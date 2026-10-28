package radio

import (
	"context"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// ForgetUser applies the deletion of an account to Radio (habeas data, T047): the content of
// every message the person sent is erased at once with its audio, photo and the copies others
// saved, the copies the person saved are removed, and the remaining rows show the author as
// "Usuario eliminado". It runs before the user row is deleted (author_id también queda NULL por
// la clave foránea).
func (s *Service) ForgetUser(ctx context.Context, userID uuid.UUID) error {
	copies, err := s.Store.ListRadioSavedCopiesOfAuthor(ctx, nullID(userID))
	if err != nil {
		return err
	}
	for _, c := range copies {
		s.removeObject(ctx, c.SavedKey.String, true)
		if _, err := s.Store.UnsaveRadioReceipt(ctx, store.UnsaveRadioReceiptParams{MessageID: c.MessageID, UserID: c.UserID}); err != nil && !store.IsNotFound(err) {
			return err
		}
	}
	ids, err := s.Store.ListRadioMessagesByAuthor(ctx, nullID(userID))
	if err != nil {
		return err
	}
	for _, id := range ids {
		old, err := s.Store.DeleteRadioMessage(ctx, id)
		if store.IsNotFound(err) {
			continue
		}
		if err != nil {
			return err
		}
		if old.ObjectKey.Valid {
			s.removeObject(ctx, old.ObjectKey.String, false)
		}
	}
	own, err := s.Store.ListRadioSavedByUser(ctx, userID)
	if err != nil {
		return err
	}
	for _, c := range own {
		s.removeObject(ctx, c.SavedKey.String, true)
	}
	_, err = s.Store.AnonymizeRadioAuthor(ctx, nullID(userID))
	return err
}
