package ptt

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

// Pre-consulta de voz de clientes frecuentes (RN-KYQ-010, specs/005-ptt-extras): canal
// walkie-talkie corto entre un pasajero afiliado y su conductor antes de pedir el viaje. Usa la
// misma sala LiveKit sin creación automática y el mismo turno a prueba de fallos que el viaje.
const (
	// PreconsultFloorTTL limita cada intervención a 15 s (FR-004).
	PreconsultFloorTTL = 15 * time.Second
	// PreconsultJoinTimeout es el plazo para que la app del conductor se una (FR-005, FR-006).
	PreconsultJoinTimeout = 30 * time.Second
	// PreconsultWindow es la duración máxima de una consulta (FR-006).
	PreconsultWindow = 2 * time.Minute
	// PreconsultRetention es cuánto se guardan los datos de una consulta cerrada (FR-008).
	PreconsultRetention = 30 * 24 * time.Hour
	// PreconsultInboxWindow es lo que muestra la bandeja del conductor (FR-010).
	PreconsultInboxWindow = 24 * time.Hour
	// Límites por pasajero (FR-007).
	PreconsultsPerHourPerDriver = 3
	PreconsultsPerDay           = 6

	purgeEvery = time.Hour
)

// Motivos de cierre de una pre-consulta.
const (
	ReasonEndedByPassenger  = "ended_by_passenger"
	ReasonEndedByDriver     = "ended_by_driver"
	ReasonDisabled          = "disabled"
	ReasonMissed            = "missed"
	ReasonDriverUnavailable = "driver_unavailable"
	ReasonExpired           = "expired"
)

var (
	ErrPreconsultsDisabled  = errors.New("driver does not accept preconsults")
	ErrDriverUnavailable    = errors.New("driver is not free")
	ErrPreconsultBusy       = errors.New("driver is in another preconsult")
	ErrPreconsultInProgress = errors.New("passenger has another open preconsult")
	ErrRateLimited          = errors.New("too many preconsults")
	ErrPreconsultWaiting    = errors.New("driver has not joined yet")
)

// Preconsult es la vista de una consulta en la API.
type Preconsult struct {
	ID            uuid.UUID  `json:"id"`
	PassengerID   uuid.UUID  `json:"passenger_id"`
	PassengerName string     `json:"passenger_name"`
	DriverID      uuid.UUID  `json:"driver_id"`
	DriverName    string     `json:"driver_name"`
	Status        string     `json:"status"`
	OpenedAt      time.Time  `json:"opened_at"`
	JoinDeadline  time.Time  `json:"join_deadline"`
	ClosesAt      time.Time  `json:"closes_at"`
	JoinedAt      *time.Time `json:"joined_at"`
	AnsweredAt    *time.Time `json:"answered_at"`
	ClosedAt      *time.Time `json:"closed_at"`
	CloseReason   *string    `json:"close_reason"`
}

// PreconsultSettings son los ajustes de consultas de un conductor.
type PreconsultSettings struct {
	AcceptsPreconsults  bool        `json:"accepts_preconsults"`
	BlockedPassengerIDs []uuid.UUID `json:"blocked_passenger_ids"`
}

func optTime(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func preconsultView(r store.GetPreconsultRow) Preconsult {
	v := Preconsult{
		ID: r.ID, PassengerID: r.PassengerID, PassengerName: r.PassengerName, DriverID: r.DriverID,
		DriverName: r.DriverName, OpenedAt: r.OpenedAt, JoinDeadline: r.JoinDeadline, ClosesAt: r.ClosesAt,
		JoinedAt: optTime(r.JoinedAt), AnsweredAt: optTime(r.AnsweredAt), ClosedAt: optTime(r.ClosedAt),
	}
	if r.CloseReason.Valid {
		reason := r.CloseReason.String
		v.CloseReason = &reason
	}
	switch {
	case !r.ClosedAt.Valid:
		v.Status = "open"
	case !r.JoinedAt.Valid:
		v.Status = "missed"
	case r.AnsweredAt.Valid:
		v.Status = "answered"
	default:
		v.Status = "unanswered"
	}
	return v
}

// open dice si la consulta admite voz ahora: sin cerrar, dentro de su ventana y, si el
// conductor no se unió, dentro del plazo para hacerlo.
func preconsultOpen(p store.GetPreconsultRow, now time.Time) bool {
	if p.ClosedAt.Valid || !p.ClosesAt.After(now) {
		return false
	}
	return p.JoinedAt.Valid || p.JoinDeadline.After(now)
}

// preconsultFor devuelve la consulta si userID es una de sus partes; si no, ErrNotFound (no se
// revela que existe).
func (s *Service) preconsultFor(ctx context.Context, userID, id uuid.UUID) (store.GetPreconsultRow, error) {
	p, err := s.Store.GetPreconsult(ctx, id)
	if store.IsNotFound(err) {
		return store.GetPreconsultRow{}, ErrNotFound
	}
	if err != nil {
		return store.GetPreconsultRow{}, err
	}
	if userID != p.PassengerID && userID != p.DriverID {
		return store.GetPreconsultRow{}, ErrNotFound
	}
	return p, nil
}

func (s *Service) publish(ctx context.Context, driverID, to uuid.UUID, typ string, now time.Time, data map[string]any) {
	if s.Publisher == nil {
		return
	}
	ev := realtime.Event{Type: typ, OccurredAt: now, Data: data}
	if err := s.Publisher.Publish(ctx, "user:"+to.String(), ev); err != nil {
		s.logger().WarnContext(ctx, "publish "+typ, "err", err)
		return
	}
	telemetry.Add(s.Usage, driverID, telemetry.Events, 1)
}

// OpenPreconsult abre una consulta del pasajero con su conductor (RN-KYQ-010). Si ya tiene una
// abierta con ese conductor la devuelve con created=false.
func (s *Service) OpenPreconsult(ctx context.Context, passengerID, driverID uuid.UUID) (Preconsult, bool, error) {
	now := s.now()
	target, err := s.Store.GetPreconsultTarget(ctx, store.GetPreconsultTargetParams{PassengerID: passengerID, DriverID: driverID})
	if store.IsNotFound(err) {
		return Preconsult{}, false, ErrNotFound
	}
	if err != nil {
		return Preconsult{}, false, err
	}
	if !target.AcceptsPreconsults || target.PreconsultsBlocked {
		return Preconsult{}, false, ErrPreconsultsDisabled
	}
	if existing, ok, err := s.existingPreconsult(ctx, passengerID, driverID); err != nil || ok {
		return existing, false, err
	}
	if target.Presence != store.DriverPresenceFree {
		return Preconsult{}, false, ErrDriverUnavailable
	}
	counts, err := s.Store.CountRecentPreconsults(ctx, store.CountRecentPreconsultsParams{
		DriverID: driverID, HourAgo: now.Add(-time.Hour), PassengerID: passengerID, DayAgo: now.Add(-24 * time.Hour),
	})
	if err != nil {
		return Preconsult{}, false, err
	}
	if counts.LastHourWithDriver >= PreconsultsPerHourPerDriver || counts.LastDay >= PreconsultsPerDay {
		return Preconsult{}, false, ErrRateLimited
	}
	id := uuid.New()
	err = s.Store.InsertPreconsult(ctx, store.InsertPreconsultParams{
		ID: id, PassengerID: passengerID, DriverID: driverID, RoomName: "pre-" + id.String(), OpenedAt: now,
		JoinDeadline: now.Add(PreconsultJoinTimeout), ClosesAt: now.Add(PreconsultWindow),
	})
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		switch pgErr.ConstraintName {
		case "ptt_preconsults_open_driver":
			return Preconsult{}, false, ErrPreconsultBusy
		case "ptt_preconsults_open_passenger":
			// Otra petición del mismo pasajero ganó la carrera.
			if existing, ok, err := s.existingPreconsult(ctx, passengerID, driverID); err != nil || ok {
				return existing, false, err
			}
			return Preconsult{}, false, ErrPreconsultInProgress
		}
	}
	if err != nil {
		return Preconsult{}, false, err
	}
	row, err := s.Store.GetPreconsult(ctx, id)
	if err != nil {
		return Preconsult{}, false, err
	}
	s.publish(ctx, driverID, driverID, "preconsult.opened", now, map[string]any{
		"preconsult_id": id, "passenger_id": passengerID, "passenger_name": row.PassengerName,
		"join_deadline": row.JoinDeadline, "closes_at": row.ClosesAt,
	})
	return preconsultView(row), true, nil
}

// existingPreconsult devuelve la consulta abierta del pasajero con driverID (ok=true), o
// ErrPreconsultInProgress si la tiene con otro conductor.
func (s *Service) existingPreconsult(ctx context.Context, passengerID, driverID uuid.UUID) (Preconsult, bool, error) {
	open, err := s.Store.GetOpenPreconsultByPassenger(ctx, passengerID)
	if store.IsNotFound(err) {
		return Preconsult{}, false, nil
	}
	if err != nil {
		return Preconsult{}, false, err
	}
	if open.DriverID != driverID {
		return Preconsult{}, false, ErrPreconsultInProgress
	}
	row, err := s.Store.GetPreconsult(ctx, open.ID)
	if err != nil {
		return Preconsult{}, false, err
	}
	return preconsultView(row), true, nil
}

// GetPreconsult devuelve la consulta a cualquiera de sus partes.
func (s *Service) GetPreconsult(ctx context.Context, userID, id uuid.UUID) (Preconsult, error) {
	p, err := s.preconsultFor(ctx, userID, id)
	if err != nil {
		return Preconsult{}, err
	}
	return preconsultView(p), nil
}

// EndPreconsult termina la consulta; el barrido borra la sala y avisa a ambos (FR-006).
func (s *Service) EndPreconsult(ctx context.Context, userID, id uuid.UUID) (Preconsult, error) {
	p, err := s.preconsultFor(ctx, userID, id)
	if err != nil {
		return Preconsult{}, err
	}
	reason := ReasonEndedByPassenger
	if userID == p.DriverID {
		reason = ReasonEndedByDriver
	}
	if _, err := s.Store.EndPreconsult(ctx, store.EndPreconsultParams{Now: s.now(), Reason: reason, ID: id}); err != nil {
		return Preconsult{}, err
	}
	return s.GetPreconsult(ctx, userID, id)
}

// PreconsultToken da credenciales de la sala de la consulta. El primer token del conductor la
// marca como conectada y avisa al pasajero, que desde entonces puede hablar (FR-005).
func (s *Service) PreconsultToken(ctx context.Context, userID, id uuid.UUID) (Credentials, error) {
	now := s.now()
	p, err := s.preconsultFor(ctx, userID, id)
	if err != nil {
		return Credentials{}, err
	}
	if !preconsultOpen(p, now) {
		return Credentials{}, ErrClosed
	}
	name := p.PassengerName
	if userID == p.DriverID {
		name = p.DriverName
	}
	if err := s.Rooms.CreateRoom(ctx, p.RoomName); err != nil {
		s.logger().ErrorContext(ctx, "create livekit room", "room", p.RoomName, "err", err)
		return Credentials{}, ErrUnavailable
	}
	token, err := s.LiveKit.ParticipantToken(userID.String(), name, p.RoomName, now, min(TokenTTL, p.ClosesAt.Sub(now)))
	if err != nil {
		return Credentials{}, err
	}
	if userID == p.DriverID {
		n, err := s.Store.MarkPreconsultJoined(ctx, store.MarkPreconsultJoinedParams{Now: ts(now), ID: id})
		if err != nil {
			return Credentials{}, err
		}
		if n > 0 {
			s.publish(ctx, p.DriverID, p.PassengerID, "preconsult.joined", now, map[string]any{"preconsult_id": id})
		}
	}
	closesAt := p.ClosesAt
	return Credentials{URL: s.PublicURL, Token: token, Room: p.RoomName, ClosesAt: &closesAt}, nil
}

// TakePreconsultFloor concede el turno de 15 s con el mismo control a prueba de fallos que el
// viaje. El pasajero no puede hablar hasta que el conductor se una.
func (s *Service) TakePreconsultFloor(ctx context.Context, userID, id uuid.UUID) (time.Time, error) {
	now := s.now()
	p, err := s.preconsultFor(ctx, userID, id)
	if err != nil {
		return time.Time{}, err
	}
	if !preconsultOpen(p, now) {
		return time.Time{}, ErrClosed
	}
	if !p.JoinedAt.Valid {
		return time.Time{}, ErrPreconsultWaiting
	}
	expires, err := s.Store.TakePreconsultFloor(ctx, store.TakePreconsultFloorParams{
		UserID: holder(userID), ExpiresAt: ts(now.Add(PreconsultFloorTTL)), ID: id, Now: now,
	})
	if store.IsNotFound(err) {
		p, err := s.Store.GetPreconsult(ctx, id)
		if err != nil {
			return time.Time{}, err
		}
		if !preconsultOpen(p, now) {
			return time.Time{}, ErrClosed
		}
		return time.Time{}, ErrBusy
	}
	if err != nil {
		return time.Time{}, err
	}
	undo := func() error {
		return s.Store.ReleasePreconsultFloor(ctx, store.ReleasePreconsultFloorParams{ID: id, FloorHolderID: holder(userID)})
	}
	if err := s.grantPublish(ctx, p.RoomName, userID, undo); err != nil {
		return time.Time{}, err
	}
	if userID == p.DriverID {
		if err := s.Store.MarkPreconsultAnswered(ctx, store.MarkPreconsultAnsweredParams{Now: ts(now), ID: id}); err != nil {
			return time.Time{}, err
		}
	}
	return expires.Time, nil
}

// ReleasePreconsultFloor retira el permiso y libera el turno; sin efecto si no es suyo.
func (s *Service) ReleasePreconsultFloor(ctx context.Context, userID, id uuid.UUID) error {
	p, err := s.preconsultFor(ctx, userID, id)
	if err != nil {
		return err
	}
	if p.FloorHolderID != holder(userID) {
		return nil
	}
	return s.revokeThenRelease(ctx, p.RoomName, userID, func() error {
		return s.Store.ReleasePreconsultFloor(ctx, store.ReleasePreconsultFloorParams{ID: id, FloorHolderID: holder(userID)})
	})
}

// ExpirePreconsultFloors retira los turnos de consulta vencidos.
func (s *Service) ExpirePreconsultFloors(ctx context.Context) (int, error) {
	now := s.now()
	expired, err := s.Store.ListExpiredPreconsultFloors(ctx, ts(now))
	if err != nil {
		return 0, err
	}
	floors := make([]expiredFloor, len(expired))
	for i, f := range expired {
		floors[i] = expiredFloor{room: f.RoomName, holder: f.FloorHolderID, clear: func() (int64, error) {
			return s.Store.ClearExpiredPreconsultFloor(ctx, store.ClearExpiredPreconsultFloorParams{ID: f.ID, HolderID: f.FloorHolderID, Now: ts(now)})
		}}
	}
	return s.expire(ctx, floors)
}

// ClosePreconsults cierra las consultas vencidas, terminadas, perdidas o con el conductor ya no
// libre: borra la sala, guarda el motivo y avisa a ambos. Si LiveKit no borra la sala, sigue
// pendiente y se reintenta.
func (s *Service) ClosePreconsults(ctx context.Context) (int, error) {
	now := s.now()
	due, err := s.Store.ListDuePreconsults(ctx, now)
	if err != nil {
		return 0, err
	}
	count := 0
	for _, p := range due {
		if err := s.Rooms.DeleteRoom(ctx, p.RoomName); err != nil {
			s.logger().WarnContext(ctx, "delete livekit room", "room", p.RoomName, "err", err)
			continue
		}
		n, err := s.Store.MarkPreconsultClosed(ctx, store.MarkPreconsultClosedParams{Now: ts(now), Reason: p.Reason, ID: p.ID})
		if err != nil {
			return count, err
		}
		if n == 0 {
			continue
		}
		count++
		for _, user := range []uuid.UUID{p.PassengerID, p.DriverID} {
			s.publish(ctx, p.DriverID, user, "preconsult.closed", now, map[string]any{"preconsult_id": p.ID, "reason": p.Reason})
		}
	}
	return count, nil
}

// PurgePreconsults borra los datos de consultas cerradas hace más de PreconsultRetention.
func (s *Service) PurgePreconsults(ctx context.Context) (int64, error) {
	return s.Store.PurgePreconsults(ctx, ts(s.now().Add(-PreconsultRetention)))
}

func (s *Service) sweepPreconsults(ctx context.Context) {
	if _, err := s.ExpirePreconsultFloors(ctx); err != nil {
		s.logger().ErrorContext(ctx, "expire preconsult floors", "err", err)
	}
	if n, err := s.ClosePreconsults(ctx); err != nil {
		s.logger().ErrorContext(ctx, "close preconsults", "err", err)
	} else if n > 0 {
		s.logger().InfoContext(ctx, "closed preconsults", "count", n)
	}
	if now := s.now(); now.Sub(s.lastPurge) >= purgeEvery {
		if n, err := s.PurgePreconsults(ctx); err != nil {
			s.logger().ErrorContext(ctx, "purge preconsults", "err", err)
		} else {
			s.lastPurge = now
			if n > 0 {
				s.logger().InfoContext(ctx, "purged preconsults", "count", n)
			}
		}
	}
}

// Ajustes del conductor (FR-001, FR-002) y lista del pasajero (FR-003).

// PreconsultSettings devuelve los ajustes del conductor.
func (s *Service) PreconsultSettings(ctx context.Context, driverID uuid.UUID) (PreconsultSettings, error) {
	accepts, err := s.Store.GetAcceptsPreconsults(ctx, driverID)
	if store.IsNotFound(err) {
		return PreconsultSettings{}, ErrNotFound
	}
	if err != nil {
		return PreconsultSettings{}, err
	}
	blocked, err := s.Store.ListBlockedPreconsultPassengers(ctx, driverID)
	if err != nil {
		return PreconsultSettings{}, err
	}
	return PreconsultSettings{AcceptsPreconsults: accepts, BlockedPassengerIDs: blocked}, nil
}

// SetAcceptsPreconsults activa o desactiva las consultas; desactivar cierra la abierta.
func (s *Service) SetAcceptsPreconsults(ctx context.Context, driverID uuid.UUID, accepts bool) (PreconsultSettings, error) {
	n, err := s.Store.SetAcceptsPreconsults(ctx, store.SetAcceptsPreconsultsParams{UserID: driverID, AcceptsPreconsults: accepts})
	if err != nil {
		return PreconsultSettings{}, err
	}
	if n == 0 {
		return PreconsultSettings{}, ErrNotFound
	}
	if !accepts {
		if err := s.Store.EndDriverPreconsults(ctx, store.EndDriverPreconsultsParams{Now: s.now(), DriverID: driverID}); err != nil {
			return PreconsultSettings{}, err
		}
	}
	return s.PreconsultSettings(ctx, driverID)
}

// SetPreconsultsBlocked silencia o reactiva a un cliente; silenciar cierra su consulta abierta.
func (s *Service) SetPreconsultsBlocked(ctx context.Context, driverID, passengerID uuid.UUID, blocked bool) error {
	n, err := s.Store.SetPreconsultsBlocked(ctx, store.SetPreconsultsBlockedParams{Blocked: blocked, DriverID: driverID, PassengerID: passengerID})
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrNotFound
	}
	if blocked {
		return s.Store.EndPairPreconsults(ctx, store.EndPairPreconsultsParams{Now: s.now(), DriverID: driverID, PassengerID: passengerID})
	}
	return nil
}

// DriverPreconsults es la bandeja del conductor: últimas 24 h, la más reciente primero.
func (s *Service) DriverPreconsults(ctx context.Context, driverID uuid.UUID) ([]Preconsult, error) {
	rows, err := s.Store.ListDriverPreconsults(ctx, store.ListDriverPreconsultsParams{DriverID: driverID, Since: s.now().Add(-PreconsultInboxWindow)})
	if err != nil {
		return nil, err
	}
	out := make([]Preconsult, len(rows))
	for i, r := range rows {
		out[i] = preconsultView(store.GetPreconsultRow(r))
	}
	return out, nil
}

// PreconsultDrivers devuelve los Conductores Elegidos que aceptan consultas del pasajero.
func (s *Service) PreconsultDrivers(ctx context.Context, passengerID uuid.UUID) ([]uuid.UUID, error) {
	return s.Store.ListPreconsultDrivers(ctx, passengerID)
}
