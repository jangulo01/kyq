// Package megaphone implements the voice announcements of the admin panel to H3 zones (spec 009,
// US3): the drivers ONLINE in the chosen hexagons hear the admin in a one-way LiveKit room. The
// voice is not recorded (FR-016).
package megaphone

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/hexgrid"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
)

// Límites (FR-013, FR-014).
const (
	MaxDuration = 60 * time.Second
	Freshness   = 5 * time.Minute
	MaxCells    = 50
	tokenSlack  = 30 * time.Second
)

// Eventos en user:{driverId}.
const (
	EventStarted = "megaphone.started"
	EventEnded   = "megaphone.ended"
)

var (
	// ErrInvalidCells: de 1 a 50 hexágonos H3 válidos de una misma resolución de 6 a 9.
	ErrInvalidCells = errors.New("invalid cells")
	// ErrOnAir: el administrador ya tiene un comunicado en curso.
	ErrOnAir = errors.New("broadcast already on air")
	// ErrNoRecipients: no hay conductores ONLINE con ubicación reciente en esas zonas.
	ErrNoRecipients = errors.New("no recipients")
	// ErrNotFound: el comunicado no existe o ya terminó.
	ErrNotFound = errors.New("broadcast not found")
)

// Voice manages the LiveKit room of a broadcast (ptt.LiveKit).
type Voice interface {
	CreateGroupRoom(ctx context.Context, name string, maxParticipants int) error
	DeleteRoom(ctx context.Context, name string) error
	BroadcastToken(identity, name, room string, speaker bool, now time.Time, ttl time.Duration) (string, error)
}

// Service starts and ends broadcasts.
type Service struct {
	Store     *store.Store
	Voice     Voice
	VoiceURL  string
	Publisher realtime.Publisher
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

// Started is the answer to the admin (contracts: MegaphoneStarted).
type Started struct {
	BroadcastID uuid.UUID `json:"broadcast_id"`
	URL         string    `json:"url"`
	Token       string    `json:"token"`
	EndsAt      time.Time `json:"ends_at"`
	Recipients  int       `json:"recipients"`
}

// Broadcast is one entry of the log (contracts: MegaphoneBroadcast).
type Broadcast struct {
	ID         uuid.UUID  `json:"id"`
	AdminName  string     `json:"admin_name"`
	Cells      []string   `json:"cells"`
	Resolution int        `json:"resolution"`
	StartedAt  time.Time  `json:"started_at"`
	EndedAt    *time.Time `json:"ended_at"`
	DurationS  *int       `json:"duration_s"`
	Recipients int        `json:"recipients"`
}

// parseCells validates the selection and returns the set and its resolution.
func parseCells(cells []string) (map[hexgrid.Cell]bool, int, error) {
	if len(cells) == 0 || len(cells) > MaxCells {
		return nil, 0, ErrInvalidCells
	}
	set := map[hexgrid.Cell]bool{}
	res := -1
	for _, raw := range cells {
		c, err := hexgrid.ParseCell(raw)
		if err != nil {
			return nil, 0, ErrInvalidCells
		}
		r := c.Resolution()
		if r < hexgrid.MinResolution || r > hexgrid.MaxResolution || (res != -1 && r != res) {
			return nil, 0, ErrInvalidCells
		}
		res = r
		set[c] = true
	}
	return set, res, nil
}

// Recipients returns the drivers whose position is inside the cells (FR-014).
func Recipients(candidates []store.ListMegaphoneCandidatesRow, cells map[hexgrid.Cell]bool, res int) []uuid.UUID {
	out := []uuid.UUID{}
	for _, d := range candidates {
		c, err := hexgrid.CellAt(hexgrid.Point{Lat: d.LastLat.Float64, Lng: d.LastLng.Float64}, res)
		if err == nil && cells[c] {
			out = append(out, d.DriverID)
		}
	}
	return out
}

// Start opens a broadcast of adminID to the drivers in cells. The recipients are fixed now: a
// driver who enters the zone later does not join midway (edge case).
func (s *Service) Start(ctx context.Context, adminID uuid.UUID, cells []string) (Started, error) {
	set, res, err := parseCells(cells)
	if err != nil {
		return Started{}, err
	}
	now := s.now()
	if _, err := s.Store.GetOpenMegaphoneForAdmin(ctx, adminID); err == nil {
		return Started{}, ErrOnAir
	} else if !store.IsNotFound(err) {
		return Started{}, err
	}
	candidates, err := s.Store.ListMegaphoneCandidates(ctx, pgtype.Timestamptz{Time: now.Add(-Freshness), Valid: true})
	if err != nil {
		return Started{}, err
	}
	drivers := Recipients(candidates, set, res)
	if len(drivers) == 0 {
		return Started{}, ErrNoRecipients
	}
	id := uuid.New()
	room := "mega-" + id.String()
	endsAt := now.Add(MaxDuration)
	if err := s.Voice.CreateGroupRoom(ctx, room, len(drivers)+1); err != nil {
		return Started{}, err
	}
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		if err := q.InsertMegaphoneBroadcast(ctx, store.InsertMegaphoneBroadcastParams{
			ID: id, AdminID: adminID, RoomName: room, Cells: cells, Resolution: int16(res),
			StartedAt: now, EndsAt: endsAt, RecipientCount: int32(len(drivers)),
		}); err != nil {
			return err
		}
		return q.InsertMegaphoneRecipients(ctx, store.InsertMegaphoneRecipientsParams{BroadcastID: id, DriverIds: drivers})
	})
	if err != nil {
		_ = s.Voice.DeleteRoom(ctx, room)
		return Started{}, err
	}
	speaker, err := s.Voice.BroadcastToken(adminID.String(), "Kyq", room, true, now, MaxDuration+tokenSlack)
	if err != nil {
		return Started{}, err
	}
	for _, d := range drivers {
		tok, err := s.Voice.BroadcastToken(d.String(), "", room, false, now, MaxDuration+tokenSlack)
		if err != nil {
			return Started{}, err
		}
		s.publish(ctx, d, realtime.Event{Type: EventStarted, OccurredAt: now, Data: map[string]any{
			"broadcast_id": id, "url": s.VoiceURL, "token": tok, "ends_at": endsAt,
		}})
	}
	return Started{BroadcastID: id, URL: s.VoiceURL, Token: speaker, EndsAt: endsAt, Recipients: len(drivers)}, nil
}

// End finishes a broadcast: closes the room and tells the recipients.
func (s *Service) End(ctx context.Context, id uuid.UUID) error {
	now := s.now()
	b, err := s.Store.EndMegaphoneBroadcast(ctx, store.EndMegaphoneBroadcastParams{ID: id, EndedAt: pgtype.Timestamptz{Time: now, Valid: true}})
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if err := s.Voice.DeleteRoom(ctx, b.RoomName); err != nil {
		s.logger().WarnContext(ctx, "delete megaphone room", "room", b.RoomName, "err", err)
	}
	drivers, err := s.Store.ListMegaphoneRecipients(ctx, id)
	if err != nil {
		return err
	}
	for _, d := range drivers {
		s.publish(ctx, d, realtime.Event{Type: EventEnded, OccurredAt: now, Data: map[string]any{"broadcast_id": id}})
	}
	return nil
}

// ExpireDue ends the broadcasts that reached 60 s (FR-013).
func (s *Service) ExpireDue(ctx context.Context) (int, error) {
	ids, err := s.Store.ListDueMegaphoneBroadcasts(ctx, s.now())
	if err != nil {
		return 0, err
	}
	n := 0
	for _, id := range ids {
		if err := s.End(ctx, id); err != nil && !errors.Is(err, ErrNotFound) {
			return n, err
		}
		n++
	}
	return n, nil
}

// RunSweeper ends due broadcasts every interval until ctx ends.
func (s *Service) RunSweeper(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if _, err := s.ExpireDue(ctx); err != nil && ctx.Err() == nil {
				s.logger().WarnContext(ctx, "expire megaphone broadcasts", "err", err)
			}
		}
	}
}

// List returns the latest broadcasts (FR-016).
func (s *Service) List(ctx context.Context, limit int) ([]Broadcast, error) {
	rows, err := s.Store.ListMegaphoneBroadcasts(ctx, int32(limit))
	if err != nil {
		return nil, err
	}
	out := make([]Broadcast, len(rows))
	for i, r := range rows {
		b := r.MegaphoneBroadcast
		out[i] = Broadcast{
			ID: b.ID, AdminName: r.AdminName, Cells: b.Cells, Resolution: int(b.Resolution),
			StartedAt: b.StartedAt, Recipients: int(b.RecipientCount),
		}
		if b.EndedAt.Valid {
			end := b.EndedAt.Time
			d := int(end.Sub(b.StartedAt).Round(time.Second) / time.Second)
			out[i].EndedAt, out[i].DurationS = &end, &d
		}
	}
	return out, nil
}

func (s *Service) publish(ctx context.Context, driverID uuid.UUID, ev realtime.Event) {
	if s.Publisher == nil {
		return
	}
	if err := s.Publisher.Publish(ctx, "user:"+driverID.String(), ev); err != nil {
		s.logger().WarnContext(ctx, "publish megaphone event", "type", ev.Type, "err", err)
	}
}
