package crm

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

// Errores de moderación (FR-015).
var (
	ErrInvalidReason    = errors.New("invalid reason")
	ErrUserNotFound     = errors.New("user not found")
	ErrCannotModerate   = errors.New("cannot moderate admin")
	ErrAlreadySuspended = errors.New("already suspended")
	ErrNotSuspended     = errors.New("not suspended")
)

// ModeratedUser is a user as the moderation screen sees it (contracts: ModeratedUser).
type ModeratedUser struct {
	UserID           uuid.UUID  `json:"user_id"`
	DisplayName      string     `json:"display_name"`
	PhoneE164        string     `json:"phone_e164"`
	Role             string     `json:"role"`
	CreatedAt        time.Time  `json:"created_at"`
	SuspendedAt      *time.Time `json:"suspended_at"`
	SuspensionReason *string    `json:"suspension_reason"`
}

func toModerated(u store.User) ModeratedUser {
	out := ModeratedUser{
		UserID: u.ID, DisplayName: u.DisplayName, PhoneE164: u.PhoneE164, Role: string(u.Role), CreatedAt: u.CreatedAt,
	}
	if u.SuspendedAt.Valid {
		at := u.SuspendedAt.Time
		out.SuspendedAt = &at
	}
	if u.SuspensionReason.Valid {
		r := u.SuspensionReason.String
		out.SuspensionReason = &r
	}
	return out
}

// Action is one entry of the moderation history (contracts: ModerationAction).
type Action struct {
	ID        uuid.UUID `json:"id"`
	Action    string    `json:"action"`
	Reason    string    `json:"reason"`
	ActorID   uuid.UUID `json:"actor_id"`
	ActorName string    `json:"actor_name"`
	CreatedAt time.Time `json:"created_at"`
}

// Moderation suspends and reactivates passengers and drivers (FR-015–FR-017).
type Moderation struct {
	Store     *store.Store
	Publisher realtime.Publisher
	Now       func() time.Time
	Logger    *slog.Logger
}

func (m *Moderation) now() time.Time {
	if m.Now != nil {
		return m.Now()
	}
	return time.Now()
}

func (m *Moderation) logger() *slog.Logger {
	if m.Logger != nil {
		return m.Logger
	}
	return slog.Default()
}

// NormalizeReason trims the reason and checks its length (3 to 500 characters).
func NormalizeReason(reason string) (string, error) {
	r := strings.TrimSpace(reason)
	if n := utf8.RuneCountInString(r); n < 3 || n > 500 {
		return "", ErrInvalidReason
	}
	return r, nil
}

// likePattern escapes the LIKE wildcards of a search term.
func likePattern(q string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(q)
}

// Search finds users by part of the name or phone, role and status (FR-014).
func (m *Moderation) Search(ctx context.Context, query, role, status string) ([]ModeratedUser, error) {
	params := store.SearchUsersParams{}
	if q := strings.TrimSpace(query); q != "" {
		params.Pattern = pgtype.Text{String: likePattern(q), Valid: true}
	}
	if role != "" {
		params.Role = store.NullUserRole{UserRole: store.UserRole(role), Valid: true}
	}
	switch status {
	case "active":
		params.Suspended = pgtype.Bool{Bool: false, Valid: true}
	case "suspended":
		params.Suspended = pgtype.Bool{Bool: true, Valid: true}
	}
	rows, err := m.Store.SearchUsers(ctx, params)
	if err != nil {
		return nil, err
	}
	out := make([]ModeratedUser, len(rows))
	for i, u := range rows {
		out[i] = toModerated(u)
	}
	return out, nil
}

// Suspend suspends a passenger or driver: it records the action, revokes the refresh tokens and
// takes a driver without an active trip OFFLINE (FR-016).
func (m *Moderation) Suspend(ctx context.Context, userID, actorID uuid.UUID, reason string) (ModeratedUser, error) {
	return m.apply(ctx, userID, actorID, reason, store.ModerationKindSuspend)
}

// Reactivate lifts a suspension.
func (m *Moderation) Reactivate(ctx context.Context, userID, actorID uuid.UUID, reason string) (ModeratedUser, error) {
	return m.apply(ctx, userID, actorID, reason, store.ModerationKindReactivate)
}

func (m *Moderation) apply(ctx context.Context, userID, actorID uuid.UUID, reason string, kind store.ModerationKind) (ModeratedUser, error) {
	reason, err := NormalizeReason(reason)
	if err != nil {
		return ModeratedUser{}, err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return ModeratedUser{}, err
	}
	now := m.now()
	var out store.User
	wentOffline := false
	err = m.Store.WithTx(ctx, func(q *store.Queries) error {
		u, err := q.GetUserForUpdate(ctx, userID)
		if store.IsNotFound(err) {
			return ErrUserNotFound
		}
		if err != nil {
			return err
		}
		if u.Role == store.UserRoleAdmin {
			return ErrCannotModerate
		}
		suspend := kind == store.ModerationKindSuspend
		switch {
		case suspend && u.SuspendedAt.Valid:
			return ErrAlreadySuspended
		case !suspend && !u.SuspendedAt.Valid:
			return ErrNotSuspended
		}
		params := store.SetUserSuspensionParams{ID: userID}
		if suspend {
			params.SuspendedAt = pgtype.Timestamptz{Time: now, Valid: true}
			params.SuspensionReason = pgtype.Text{String: reason, Valid: true}
		}
		if err := q.SetUserSuspension(ctx, params); err != nil {
			return err
		}
		if err := q.InsertModerationAction(ctx, store.InsertModerationActionParams{
			ID: id, UserID: userID, Action: kind, Reason: reason, ActorID: actorID,
		}); err != nil {
			return err
		}
		u.SuspendedAt, u.SuspensionReason = params.SuspendedAt, params.SuspensionReason
		out = u
		if !suspend {
			return nil
		}
		if err := q.RevokeUserRefreshTokens(ctx, userID); err != nil {
			return err
		}
		if u.Role != store.UserRoleDriver {
			return nil
		}
		wentOffline, err = takeOffline(ctx, q, userID)
		return err
	})
	if err != nil {
		return ModeratedUser{}, err
	}
	if wentOffline {
		m.publishOffline(ctx, userID, now)
	}
	return toModerated(out), nil
}

// takeOffline sets a driver OFFLINE unless it is on an active trip, which goes on until it ends
// (spec 007, edge cases).
func takeOffline(ctx context.Context, q *store.Queries, driverID uuid.UUID) (bool, error) {
	d, err := q.GetDriverForPresence(ctx, driverID)
	if err != nil {
		return false, err
	}
	if d.Presence == store.DriverPresenceOffline {
		return false, nil
	}
	if _, err := q.GetActiveTripForDriver(ctx, driverID); err == nil {
		return false, nil
	} else if !store.IsNotFound(err) {
		return false, err
	}
	return true, q.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: driverID, Presence: store.DriverPresenceOffline})
}

func (m *Moderation) publishOffline(ctx context.Context, driverID uuid.UUID, now time.Time) {
	if m.Publisher == nil {
		return
	}
	err := m.Publisher.Publish(ctx, "driver_presence:"+driverID.String(), realtime.Event{
		Type: "driver.presence", OccurredAt: now,
		Data: map[string]any{"driver_id": driverID, "presence": store.DriverPresenceOffline, "busy_until_estimate": nil},
	})
	if err != nil {
		m.logger().WarnContext(ctx, "publicar driver.presence al suspender", "err", err)
	}
}

// History returns the moderation history of a user, newest first (FR-017).
func (m *Moderation) History(ctx context.Context, userID uuid.UUID) ([]Action, error) {
	if _, err := m.Store.GetUserByID(ctx, userID); store.IsNotFound(err) {
		return nil, ErrUserNotFound
	} else if err != nil {
		return nil, err
	}
	rows, err := m.Store.ListModerationActions(ctx, userID)
	if err != nil {
		return nil, err
	}
	out := make([]Action, len(rows))
	for i, r := range rows {
		out[i] = Action{ID: r.ID, Action: string(r.Action), Reason: r.Reason, ActorID: r.ActorID, ActorName: r.ActorName, CreatedAt: r.CreatedAt}
	}
	return out, nil
}
