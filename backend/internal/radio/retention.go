package radio

import (
	"context"
	"time"

	"github.com/kyq/backend/internal/store"
)

const (
	// retainEvery: la retención se aplica una vez al día (T019).
	retainEvery = 24 * time.Hour
	// retainBatch limita cada pasada del barrido de retención.
	retainBatch = 500
	// recordingGrace: un mensaje que sigue en `recording` tanto tiempo después de su turno no
	// recibirá ya su archivo.
	recordingGrace = 3 * time.Minute
)

// Retain deletes the messages past the current retention and their objects (FR-012). A message
// someone saved keeps its row for them and only loses the original object (the copy lives in
// kyq-radio-saved); saved copies end after a year. A retention change never deletes earlier than
// announced: each message keeps the expiry it was created with, and a longer one extends it.
func (s *Service) Retain(ctx context.Context) (int, error) {
	st, err := s.settings(ctx)
	if err != nil {
		return 0, err
	}
	now := s.now()
	if _, err := s.Store.ExtendRadioExpiry(ctx, store.ExtendRadioExpiryParams{RetentionDays: int32(st.RetentionDays), Now: now}); err != nil {
		return 0, err
	}
	n := 0
	for {
		rows, err := s.Store.ListExpiredRadioMessages(ctx, store.ListExpiredRadioMessagesParams{
			Now: now, RetentionDays: int32(st.RetentionDays), MaxRows: retainBatch,
		})
		if err != nil {
			return n, err
		}
		for _, r := range rows {
			if r.ObjectKey.Valid {
				s.removeObject(ctx, r.ObjectKey.String, false)
			}
			if r.Guarded {
				err = s.Store.DropRadioMessageObject(ctx, r.ID)
			} else {
				err = s.Store.PurgeRadioMessage(ctx, r.ID)
			}
			if err != nil {
				return n, err
			}
			n++
		}
		if len(rows) < retainBatch {
			break
		}
	}
	saved, err := s.Store.ListExpiredRadioSaved(ctx, store.ListExpiredRadioSavedParams{SavedAt: ts(now.Add(-SavedFor)), Limit: retainBatch})
	if err != nil {
		return n, err
	}
	for _, r := range saved {
		if r.SavedKey.Valid {
			s.removeObject(ctx, r.SavedKey.String, true)
		}
		if err := s.Store.ExpireRadioSaved(ctx, store.ExpireRadioSavedParams{MessageID: r.MessageID, UserID: r.UserID}); err != nil {
			return n, err
		}
		n++
	}
	return n, nil
}

// closeStaleRecordings keeps the entry of voice messages whose file never arrived (the sender
// lost signal before publishing): who talked and when stays in the history, without audio.
func (s *Service) closeStaleRecordings(ctx context.Context) error {
	rows, err := s.Store.ListStaleRecordingRadioMessages(ctx, s.now().Add(-recordingGrace))
	if err != nil {
		return err
	}
	for _, r := range rows {
		msg, err := s.Store.CompleteRadioMessage(ctx, store.CompleteRadioMessageParams{ID: r.ID})
		if store.IsNotFound(err) {
			continue
		}
		if err != nil {
			return err
		}
		s.announceMessage(ctx, msg)
	}
	return nil
}

// Sweep runs the periodic work: turns that expired or went silent (every call), radios without
// heartbeat, quiet hours, invitation expiry, stale recordings and, once a day, the retention.
func (s *Service) Sweep(ctx context.Context) error {
	if _, err := s.ExpireFloors(ctx); err != nil {
		return err
	}
	now := s.now()
	stale, err := s.Store.ListStaleRadioPresence(ctx, store.ListStaleRadioPresenceParams{Now: now, StaleBefore: now.Add(-OfflineAfter)})
	if err != nil {
		return err
	}
	for _, u := range stale {
		s.announcePresence(ctx, u, store.RadioPresence{UserID: u, RadioOn: false})
	}
	if err := s.QuietHours(ctx); err != nil {
		return err
	}
	if _, err := s.Store.ExpireRadioInvites(ctx, now); err != nil {
		return err
	}
	if err := s.closeStaleRecordings(ctx); err != nil {
		return err
	}
	if now.Sub(s.lastRetained) >= retainEvery {
		if _, err := s.Retain(ctx); err != nil {
			return err
		}
		s.lastRetained = now
	}
	return nil
}

// RunSweeper calls Sweep every interval until ctx ends (1 s: the turn rules need it).
func (s *Service) RunSweeper(ctx context.Context, interval time.Duration) {
	t := time.NewTicker(interval)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if err := s.Sweep(ctx); err != nil && ctx.Err() == nil {
				s.logger().WarnContext(ctx, "radio sweep", "err", err)
			}
		}
	}
}
