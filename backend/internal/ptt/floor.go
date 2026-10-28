package ptt

import (
	"context"

	"github.com/google/uuid"
)

// Turno a prueba de fallos, compartido por el canal del viaje y la pre-consulta (FR-017 de 001).
// El permiso de publicar en LiveKit sigue a la fila del turno: una fila solo se libera después
// de que LiveKit confirme la retirada, así que quien puede publicar siempre tiene el turno (o un
// turno vencido que el barrido sigue intentando retirar) y nadie más puede tomarlo mientras.

// grantPublish deja publicar a userID en room después de tomar su fila de turno. Si LiveKit
// falla, deshace la fila con undo solo si confirma que el permiso queda retirado; si no, el
// turno caduca y el barrido lo retira.
func (s *Service) grantPublish(ctx context.Context, room string, userID uuid.UUID, undo func() error) error {
	if err := s.Rooms.SetCanPublish(ctx, room, userID.String(), true); err != nil {
		s.logger().ErrorContext(ctx, "grant livekit publish", "room", room, "err", err)
		// LiveKit pudo aplicar el permiso aunque la llamada fallara.
		if s.Rooms.SetCanPublish(ctx, room, userID.String(), false) == nil {
			if err := undo(); err != nil {
				return err
			}
		}
		return ErrUnavailable
	}
	return nil
}

// revokeThenRelease retira el permiso de publicar y luego libera la fila con release. Si
// LiveKit no confirma la retirada, el turno sigue y caduca solo.
func (s *Service) revokeThenRelease(ctx context.Context, room string, userID uuid.UUID, release func() error) error {
	if err := s.Rooms.SetCanPublish(ctx, room, userID.String(), false); err != nil {
		s.logger().ErrorContext(ctx, "revoke livekit publish", "room", room, "err", err)
		return ErrUnavailable
	}
	return release()
}

// expiredFloor es un turno vencido: su sala, quién lo tiene y cómo liberar su fila.
type expiredFloor struct {
	room   string
	holder uuid.NullUUID
	clear  func() (int64, error)
}

// expire retira el permiso de cada turno vencido y solo entonces libera su fila; si LiveKit
// falla, el turno sigue vencido y se reintenta en el próximo barrido.
func (s *Service) expire(ctx context.Context, floors []expiredFloor) (int, error) {
	count := 0
	for _, f := range floors {
		if err := s.Rooms.SetCanPublish(ctx, f.room, f.holder.UUID.String(), false); err != nil {
			s.logger().WarnContext(ctx, "revoke expired floor", "room", f.room, "err", err)
			continue
		}
		n, err := f.clear()
		if err != nil {
			return count, err
		}
		count += int(n)
	}
	return count, nil
}
