// Package cooperatives manages cooperatives, their members and coordinators, and the drivers'
// requests to join (006, FR-001..FR-008). Delegation of trips to coworkers lives in package
// trips; the group voice channel, in package ptt.
package cooperatives

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

var (
	ErrNotFound             = errors.New("cooperative not found")
	ErrMembershipNotFound   = errors.New("membership not found")
	ErrDriverNotFound       = errors.New("driver not found")
	ErrNameTaken            = errors.New("cooperative name taken")
	ErrAlreadyInCooperative = errors.New("driver already in a cooperative or with a pending request")
	ErrNotPending           = errors.New("membership request already decided")
	ErrReasonRequired       = errors.New("reject reason required")
	ErrForbidden            = errors.New("not a coordinator of this cooperative")
	ErrNotMember            = errors.New("driver is not a member")
)

// InvalidError is a validation error with a message for the user.
type InvalidError struct{ Message string }

func (e InvalidError) Error() string { return e.Message }

// GroupChannel lets the service take a driver out of the group voice channel when he leaves or
// is removed, and close it when the cooperative is suspended (FR-024). Package ptt implements it.
type GroupChannel interface {
	LeaveGroup(ctx context.Context, cooperativeID, driverID uuid.UUID) error
	CloseGroup(ctx context.Context, cooperativeID uuid.UUID) error
}

// Groups sends each change to several group channels: the 006 room and the cooperative's
// conversation in Radio Kyq (011). Every channel is tried; the first error is returned.
type Groups []GroupChannel

func (g Groups) LeaveGroup(ctx context.Context, cooperativeID, driverID uuid.UUID) error {
	var first error
	for _, c := range g {
		if err := c.LeaveGroup(ctx, cooperativeID, driverID); err != nil && first == nil {
			first = err
		}
	}
	return first
}

func (g Groups) CloseGroup(ctx context.Context, cooperativeID uuid.UUID) error {
	var first error
	for _, c := range g {
		if err := c.CloseGroup(ctx, cooperativeID); err != nil && first == nil {
			first = err
		}
	}
	return first
}

// Service implements the cooperative use cases.
type Service struct {
	Store     *store.Store
	Publisher realtime.Publisher
	Group     GroupChannel
	Usage     telemetry.Usage
	Now       func() time.Time
	Logger    *slog.Logger
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) logger() *slog.Logger {
	if s.Logger != nil {
		return s.Logger
	}
	return slog.Default()
}

// Status values match cooperative_status, cooperative_role and membership_status.
const (
	StatusActive    = "active"
	StatusSuspended = "suspended"
	RoleMember      = "member"
	RoleCoordinator = "coordinator"
)

// Cooperative is contracts/api.yaml#Cooperative.
type Cooperative struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	CityCode     string    `json:"city_code"`
	NIT          *string   `json:"nit"`
	Status       string    `json:"status"`
	MembersCount int       `json:"members_count"`
	PendingCount int       `json:"pending_count"`
	CreatedAt    time.Time `json:"created_at"`
}

// Ref is contracts/api.yaml#CooperativeRef.
type Ref struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

// Member is contracts/api.yaml#CooperativeMember.
type Member struct {
	MembershipID uuid.UUID `json:"membership_id"`
	DriverID     uuid.UUID `json:"driver_id"`
	DisplayName  string    `json:"display_name"`
	VehiclePlate string    `json:"vehicle_plate"`
	Role         string    `json:"role"`
	Presence     string    `json:"presence"`
	Since        time.Time `json:"since"`
}

// Request is contracts/api.yaml#MembershipRequest.
type Request struct {
	MembershipID uuid.UUID `json:"membership_id"`
	DriverID     uuid.UUID `json:"driver_id"`
	DisplayName  string    `json:"display_name"`
	VehiclePlate string    `json:"vehicle_plate"`
	RequestedAt  time.Time `json:"requested_at"`
}

// Membership is contracts/api.yaml#Membership.
type Membership struct {
	ID                uuid.UUID  `json:"id"`
	Cooperative       Ref        `json:"cooperative"`
	CooperativeStatus string     `json:"cooperative_status"`
	Role              string     `json:"role"`
	Status            string     `json:"status"`
	RejectReason      *string    `json:"reject_reason"`
	RequestedAt       time.Time  `json:"requested_at"`
	DecidedAt         *time.Time `json:"decided_at"`
}

// Detail is contracts/api.yaml#CooperativeDetail.
type Detail struct {
	Cooperative Cooperative `json:"cooperative"`
	Members     []Member    `json:"members"`
	Requests    []Request   `json:"requests"`
}

// Mine is contracts/api.yaml#DriverCooperative.
type Mine struct {
	Membership *Membership `json:"membership"`
	Members    []Member    `json:"members"`
	Requests   []Request   `json:"requests"`
}

// Input is the editable data of a cooperative.
type Input struct {
	Name     string
	CityCode string
	NIT      *string
}

func (in *Input) normalize() error {
	in.Name = strings.Join(strings.Fields(in.Name), " ")
	in.CityCode = strings.TrimSpace(in.CityCode)
	if n := utf8.RuneCountInString(in.Name); n < 3 || n > 80 {
		return InvalidError{"el nombre debe tener entre 3 y 80 caracteres"}
	}
	if in.CityCode == "" || len(in.CityCode) > 40 {
		return InvalidError{"indica la ciudad"}
	}
	if in.NIT != nil {
		v := strings.TrimSpace(*in.NIT)
		if v == "" {
			in.NIT = nil
		} else if utf8.RuneCountInString(v) > 20 {
			return InvalidError{"el NIT admite hasta 20 caracteres"}
		} else {
			in.NIT = &v
		}
	}
	return nil
}

func text(v *string) pgtype.Text {
	if v == nil {
		return pgtype.Text{}
	}
	return pgtype.Text{String: *v, Valid: true}
}

func textPtr(t pgtype.Text) *string {
	if !t.Valid {
		return nil
	}
	v := t.String
	return &v
}

func tsPtr(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

func nullID(id uuid.UUID) uuid.NullUUID { return uuid.NullUUID{UUID: id, Valid: true} }

// constraint returns the violated unique constraint, or "".
func constraint(err error) string {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return pgErr.ConstraintName
	}
	return ""
}

func mapUnique(err error) error {
	switch constraint(err) {
	case "cooperatives_name_unique":
		return ErrNameTaken
	case "cooperative_memberships_one_per_driver":
		return ErrAlreadyInCooperative
	}
	return err
}

func viewOf(c store.Cooperative, members, pending int32) Cooperative {
	return Cooperative{
		ID: c.ID, Name: c.Name, CityCode: c.CityCode, NIT: textPtr(c.Nit), Status: string(c.Status),
		MembersCount: int(members), PendingCount: int(pending), CreatedAt: c.CreatedAt,
	}
}

// RoomName is the first LiveKit room of a cooperative's group channel; package ptt rotates it
// whenever a member leaves or is removed (group_ptt_channels.room_name holds the current one).
func RoomName(id uuid.UUID) string { return "coop-" + id.String() }

// Create adds an active cooperative with its group voice channel (FR-001, FR-022).
func (s *Service) Create(ctx context.Context, adminID uuid.UUID, in Input) (Cooperative, error) {
	if err := in.normalize(); err != nil {
		return Cooperative{}, err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return Cooperative{}, err
	}
	var row store.Cooperative
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		row, err = q.CreateCooperative(ctx, store.CreateCooperativeParams{
			ID: id, Name: in.Name, CityCode: in.CityCode, Nit: text(in.NIT), CreatedBy: adminID,
		})
		if err != nil {
			return mapUnique(err)
		}
		return q.CreateGroupPTTChannel(ctx, store.CreateGroupPTTChannelParams{CooperativeID: id, RoomName: RoomName(id)})
	})
	if err != nil {
		return Cooperative{}, err
	}
	return viewOf(row, 0, 0), nil
}

// Patch is a partial update; nil fields stay as they are.
type Patch struct {
	Name     *string
	CityCode *string
	NIT      **string
	Status   *string
}

// Update edits a cooperative and suspends or reactivates it (FR-001). Suspending closes its
// group channel (FR-024).
func (s *Service) Update(ctx context.Context, id uuid.UUID, p Patch) (Cooperative, error) {
	if p.Status != nil && *p.Status != StatusActive && *p.Status != StatusSuspended {
		return Cooperative{}, InvalidError{"estado inválido: usa active o suspended"}
	}
	var row store.Cooperative
	var counts store.CountCooperativeMembershipsRow
	suspended := false
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		cur, err := q.GetCooperativeForUpdate(ctx, id)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		in := Input{Name: cur.Name, CityCode: cur.CityCode, NIT: textPtr(cur.Nit)}
		if p.Name != nil {
			in.Name = *p.Name
		}
		if p.CityCode != nil {
			in.CityCode = *p.CityCode
		}
		if p.NIT != nil {
			in.NIT = *p.NIT
		}
		if err := in.normalize(); err != nil {
			return err
		}
		status := cur.Status
		if p.Status != nil {
			status = store.CooperativeStatus(*p.Status)
		}
		suspended = cur.Status == store.CooperativeStatusActive && status == store.CooperativeStatusSuspended
		row, err = q.UpdateCooperative(ctx, store.UpdateCooperativeParams{
			ID: id, Name: in.Name, CityCode: in.CityCode, Nit: text(in.NIT), Status: status,
		})
		if err != nil {
			return mapUnique(err)
		}
		counts, err = q.CountCooperativeMemberships(ctx, id)
		return err
	})
	if err != nil {
		return Cooperative{}, err
	}
	if suspended && s.Group != nil {
		if err := s.Group.CloseGroup(ctx, id); err != nil {
			s.logger().WarnContext(ctx, "close group channel", "cooperative_id", id, "err", err)
		}
	}
	return viewOf(row, counts.MembersCount, counts.PendingCount), nil
}

// List returns the cooperatives with their counts; onlyActive for drivers (FR-002, FR-004).
func (s *Service) List(ctx context.Context, onlyActive bool) ([]Cooperative, error) {
	rows, err := s.Store.ListCooperativesWithCounts(ctx, onlyActive)
	if err != nil {
		return nil, err
	}
	out := make([]Cooperative, len(rows))
	for i, r := range rows {
		out[i] = viewOf(store.Cooperative{
			ID: r.ID, Name: r.Name, CityCode: r.CityCode, Nit: r.Nit, Status: r.Status, CreatedBy: r.CreatedBy,
			CreatedAt: r.CreatedAt, UpdatedAt: r.UpdatedAt,
		}, r.MembersCount, r.PendingCount)
	}
	return out, nil
}

func members(ctx context.Context, q *store.Queries, id uuid.UUID) ([]Member, error) {
	rows, err := q.ListCooperativeMembers(ctx, id)
	if err != nil {
		return nil, err
	}
	out := make([]Member, len(rows))
	for i, r := range rows {
		out[i] = Member{
			MembershipID: r.MembershipID, DriverID: r.DriverID, DisplayName: r.DisplayName, VehiclePlate: r.VehiclePlate,
			Role: string(r.Role), Presence: string(r.Presence), Since: r.Since,
		}
	}
	return out, nil
}

func requests(ctx context.Context, q *store.Queries, id uuid.UUID) ([]Request, error) {
	rows, err := q.ListCooperativeRequests(ctx, id)
	if err != nil {
		return nil, err
	}
	out := make([]Request, len(rows))
	for i, r := range rows {
		out[i] = Request{
			MembershipID: r.MembershipID, DriverID: r.DriverID, DisplayName: r.DisplayName, VehiclePlate: r.VehiclePlate,
			RequestedAt: r.RequestedAt,
		}
	}
	return out, nil
}

// Detail returns a cooperative with its members and pending requests (FR-002).
func (s *Service) Detail(ctx context.Context, id uuid.UUID) (Detail, error) {
	c, err := s.Store.GetCooperative(ctx, id)
	if store.IsNotFound(err) {
		return Detail{}, ErrNotFound
	}
	if err != nil {
		return Detail{}, err
	}
	m, err := members(ctx, s.Store.Queries, id)
	if err != nil {
		return Detail{}, err
	}
	r, err := requests(ctx, s.Store.Queries, id)
	if err != nil {
		return Detail{}, err
	}
	return Detail{Cooperative: viewOf(c, int32(len(m)), int32(len(r))), Members: m, Requests: r}, nil
}

func membershipView(id, coopID uuid.UUID, coopName string, coopStatus store.CooperativeStatus, m store.CooperativeMembership) *Membership {
	return &Membership{
		ID: id, Cooperative: Ref{ID: coopID, Name: coopName}, CooperativeStatus: string(coopStatus), Role: string(m.Role),
		Status: string(m.Status), RejectReason: textPtr(m.RejectReason), RequestedAt: m.RequestedAt, DecidedAt: tsPtr(m.DecidedAt),
	}
}

// Mine returns the driver's membership, coworkers and, for coordinators, pending requests (FR-007).
func (s *Service) Mine(ctx context.Context, driverID uuid.UUID) (Mine, error) {
	out := Mine{Members: []Member{}, Requests: []Request{}}
	cur, err := s.Store.GetCurrentMembership(ctx, driverID)
	if store.IsNotFound(err) {
		last, err := s.Store.GetLastEndedMembership(ctx, driverID)
		if store.IsNotFound(err) {
			return out, nil
		}
		if err != nil {
			return Mine{}, err
		}
		out.Membership = membershipView(last.ID, last.CooperativeID, last.CooperativeName, last.CooperativeStatus, store.CooperativeMembership{
			Role: last.Role, Status: last.Status, RejectReason: last.RejectReason, RequestedAt: last.RequestedAt, DecidedAt: last.DecidedAt,
		})
		return out, nil
	}
	if err != nil {
		return Mine{}, err
	}
	out.Membership = membershipView(cur.ID, cur.CooperativeID, cur.CooperativeName, cur.CooperativeStatus, store.CooperativeMembership{
		Role: cur.Role, Status: cur.Status, RejectReason: cur.RejectReason, RequestedAt: cur.RequestedAt, DecidedAt: cur.DecidedAt,
	})
	if cur.Status != store.MembershipStatusActive {
		return out, nil
	}
	if out.Members, err = members(ctx, s.Store.Queries, cur.CooperativeID); err != nil {
		return Mine{}, err
	}
	if cur.Role == store.CooperativeRoleCoordinator {
		if out.Requests, err = requests(ctx, s.Store.Queries, cur.CooperativeID); err != nil {
			return Mine{}, err
		}
	}
	return out, nil
}

// RequestJoin creates a pending request to an active cooperative (FR-003, FR-004).
func (s *Service) RequestJoin(ctx context.Context, driverID, cooperativeID uuid.UUID) (*Membership, error) {
	id, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}
	now := s.now()
	var view *Membership
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		c, err := q.GetCooperative(ctx, cooperativeID)
		if store.IsNotFound(err) || (err == nil && c.Status != store.CooperativeStatusActive) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		m, err := q.InsertMembership(ctx, store.InsertMembershipParams{
			ID: id, CooperativeID: cooperativeID, DriverID: driverID, Role: store.CooperativeRoleMember,
			Status: store.MembershipStatusPending, RequestedAt: now,
		})
		if err != nil {
			return mapUnique(err)
		}
		view = membershipView(m.ID, c.ID, c.Name, c.Status, m)
		return nil
	})
	return view, err
}

// Withdraw cancels the driver's pending request.
func (s *Service) Withdraw(ctx context.Context, driverID uuid.UUID) error {
	return s.end(ctx, driverID, driverID, store.MembershipStatusPending, store.MembershipStatusCancelled)
}

// Leave takes the driver out of his cooperative (FR-004) and its group channel (FR-024).
func (s *Service) Leave(ctx context.Context, driverID uuid.UUID) error {
	return s.end(ctx, driverID, driverID, store.MembershipStatusActive, store.MembershipStatusLeft)
}

func (s *Service) end(ctx context.Context, actor, driverID uuid.UUID, from, to store.MembershipStatus) error {
	now := s.now()
	var coopID uuid.UUID
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		cur, err := q.GetCurrentMembership(ctx, driverID)
		if store.IsNotFound(err) || (err == nil && cur.Status != from) {
			return ErrMembershipNotFound
		}
		if err != nil {
			return err
		}
		coopID = cur.CooperativeID
		n, err := q.EndMembership(ctx, store.EndMembershipParams{
			ID: cur.ID, Status: to, FromStatus: from, EndedBy: nullID(actor), EndedAt: ts(now),
		})
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrMembershipNotFound
		}
		return nil
	})
	if err != nil {
		return err
	}
	if from == store.MembershipStatusActive {
		s.leaveGroup(ctx, coopID, driverID)
	}
	return nil
}

func (s *Service) leaveGroup(ctx context.Context, coopID, driverID uuid.UUID) {
	if s.Group == nil {
		return
	}
	if err := s.Group.LeaveGroup(ctx, coopID, driverID); err != nil {
		s.logger().WarnContext(ctx, "leave group channel", "cooperative_id", coopID, "err", err)
	}
}

// Decider is who decides a request: an admin, or a driver who must coordinate that cooperative.
type Decider struct {
	UserID uuid.UUID
	Admin  bool
}

// coordinatorOf returns the cooperative the driver coordinates, or ErrForbidden.
func coordinatorOf(ctx context.Context, q *store.Queries, driverID uuid.UUID) (uuid.UUID, error) {
	cur, err := q.GetCurrentMembership(ctx, driverID)
	if store.IsNotFound(err) {
		return uuid.Nil, ErrForbidden
	}
	if err != nil {
		return uuid.Nil, err
	}
	if cur.Status != store.MembershipStatusActive || cur.Role != store.CooperativeRoleCoordinator {
		return uuid.Nil, ErrForbidden
	}
	return cur.CooperativeID, nil
}

// Decide approves or rejects a pending request (FR-005); rejecting needs a reason.
func (s *Service) Decide(ctx context.Context, by Decider, membershipID uuid.UUID, approve bool, reason string) error {
	reason = strings.TrimSpace(reason)
	if !approve && reason == "" {
		return ErrReasonRequired
	}
	now := s.now()
	var m store.CooperativeMembership
	status := store.MembershipStatusActive
	if !approve {
		status = store.MembershipStatusRejected
	}
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		m, err = q.GetMembershipForUpdate(ctx, membershipID)
		if store.IsNotFound(err) {
			return ErrMembershipNotFound
		}
		if err != nil {
			return err
		}
		if !by.Admin {
			coop, err := coordinatorOf(ctx, q, by.UserID)
			if err != nil {
				return err
			}
			if coop != m.CooperativeID {
				return ErrMembershipNotFound // no revela solicitudes de otras cooperativas
			}
		}
		if m.Status != store.MembershipStatusPending {
			return ErrNotPending
		}
		var rr pgtype.Text
		if !approve {
			rr = pgtype.Text{String: reason, Valid: true}
		}
		_, err = q.DecideMembership(ctx, store.DecideMembershipParams{
			ID: membershipID, Status: status, RejectReason: rr, DecidedBy: nullID(by.UserID), DecidedAt: ts(now),
		})
		return err
	})
	if err != nil {
		return err
	}
	s.notify(ctx, m.DriverID, m.ID, m.CooperativeID, string(status), string(m.Role), now)
	return nil
}

// AddMember adds a driver without cooperative as an active member (FR-006).
func (s *Service) AddMember(ctx context.Context, adminID, cooperativeID, driverID uuid.UUID, role string) (*Membership, error) {
	if role == "" {
		role = RoleMember
	}
	if role != RoleMember && role != RoleCoordinator {
		return nil, InvalidError{"rol inválido: usa member o coordinator"}
	}
	id, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}
	now := s.now()
	var view *Membership
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		c, err := q.GetCooperative(ctx, cooperativeID)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		ok, err := q.DriverExists(ctx, driverID)
		if err != nil {
			return err
		}
		if !ok {
			return ErrDriverNotFound
		}
		m, err := q.InsertMembership(ctx, store.InsertMembershipParams{
			ID: id, CooperativeID: cooperativeID, DriverID: driverID, Role: store.CooperativeRole(role),
			Status: store.MembershipStatusActive, RequestedAt: now, DecidedBy: nullID(adminID), DecidedAt: ts(now),
		})
		if err != nil {
			return mapUnique(err)
		}
		view = membershipView(m.ID, c.ID, c.Name, c.Status, m)
		return nil
	})
	if err != nil {
		return nil, err
	}
	s.notify(ctx, driverID, id, cooperativeID, string(store.MembershipStatusActive), role, now)
	return view, nil
}

// SetRole names or removes a coordinator (FR-006); only admins.
func (s *Service) SetRole(ctx context.Context, cooperativeID, driverID uuid.UUID, role string) error {
	if role != RoleMember && role != RoleCoordinator {
		return InvalidError{"rol inválido: usa member o coordinator"}
	}
	now := s.now()
	var m store.CooperativeMembership
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		m, err = q.GetActiveMembershipInCooperative(ctx, store.GetActiveMembershipInCooperativeParams{CooperativeID: cooperativeID, DriverID: driverID})
		if store.IsNotFound(err) {
			return ErrNotMember
		}
		if err != nil {
			return err
		}
		_, err = q.SetMembershipRole(ctx, store.SetMembershipRoleParams{ID: m.ID, Role: store.CooperativeRole(role)})
		return err
	})
	if err != nil {
		return err
	}
	s.notify(ctx, driverID, m.ID, cooperativeID, string(store.MembershipStatusActive), role, now)
	return nil
}

// Remove takes a member out of the cooperative (FR-006). A coordinator may remove only plain
// members of his own cooperative, never himself.
func (s *Service) Remove(ctx context.Context, by Decider, cooperativeID, driverID uuid.UUID) error {
	now := s.now()
	var m store.CooperativeMembership
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		if !by.Admin {
			coop, err := coordinatorOf(ctx, q, by.UserID)
			if err != nil {
				return err
			}
			cooperativeID = coop
		}
		var err error
		m, err = q.GetActiveMembershipInCooperative(ctx, store.GetActiveMembershipInCooperativeParams{CooperativeID: cooperativeID, DriverID: driverID})
		if store.IsNotFound(err) {
			return ErrNotMember
		}
		if err != nil {
			return err
		}
		if !by.Admin && (m.Role == store.CooperativeRoleCoordinator || driverID == by.UserID) {
			return ErrForbidden
		}
		_, err = q.EndMembership(ctx, store.EndMembershipParams{
			ID: m.ID, Status: store.MembershipStatusRemoved, FromStatus: store.MembershipStatusActive,
			EndedBy: nullID(by.UserID), EndedAt: ts(now),
		})
		return err
	})
	if err != nil {
		return err
	}
	s.leaveGroup(ctx, cooperativeID, driverID)
	s.notify(ctx, driverID, m.ID, cooperativeID, string(store.MembershipStatusRemoved), string(m.Role), now)
	return nil
}

// notify publishes cooperative.membership to the driver (FR-008); best-effort after commit.
func (s *Service) notify(ctx context.Context, driverID, membershipID, cooperativeID uuid.UUID, status, role string, now time.Time) {
	if s.Publisher == nil {
		return
	}
	err := s.Publisher.Publish(ctx, "user:"+driverID.String(), realtime.Event{
		Type: "cooperative.membership", OccurredAt: now,
		Data: map[string]any{"membership_id": membershipID, "cooperative_id": cooperativeID, "status": status, "role": role},
	})
	if err != nil {
		s.logger().WarnContext(ctx, "publish cooperative.membership", "err", err)
	}
	telemetry.Add(s.Usage, driverID, telemetry.Events, 1)
}
