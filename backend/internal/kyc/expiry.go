package kyc

import (
	"context"
	"strconv"
	"time"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
)

// Avisos de vencimiento (FR-010, FR-027): a 15 días solo en la app; a 3 días y el día del
// vencimiento también por SMS. Se mira hasta una semana atrás por si el barrido estuvo parado.
const (
	warnEarlyDays = 15
	warnLateDays  = 3
	lookBackDays  = 7
)

// CheckExpiries creates the due expiry notices once each (dedup by document and threshold) and
// returns how many were new.
func (s *Service) CheckExpiries(ctx context.Context) (int, error) {
	today := drivers.Today(s.now())
	rows, err := s.Store.ListDocumentsDue(ctx, store.ListDocumentsDueParams{
		Since: today.AddDate(0, 0, -lookBackDays), Until: today.AddDate(0, 0, warnEarlyDays),
	})
	if err != nil {
		return 0, err
	}
	created := 0
	for _, r := range rows {
		docType := string(r.DocType)
		if !drivers.DocumentExpires(docType) {
			continue
		}
		label := drivers.DocumentLabel(docType)
		days := int(r.Due.Sub(today).Hours() / 24)
		due := r.Due.Format("02/01/2006")
		var n notify.Notice
		switch {
		case days <= 0:
			n = notify.Notice{
				Kind: "doc_expired", DedupKey: "doc_expired:" + r.ID.String(), SMS: true,
				Title: label + " vencido",
				Body:  label + " vencido: envía el nuevo desde Documentos. No puedes ponerte ONLINE hasta que se apruebe.",
			}
		case days <= warnLateDays:
			n = notify.Notice{
				Kind: "doc_expiring", DedupKey: "doc_expiring:" + r.ID.String() + ":3", SMS: true,
				Title: label + " vence pronto",
				Body:  label + " vence el " + due + ". Envía el nuevo desde Documentos para seguir trabajando.",
			}
		default:
			n = notify.Notice{
				Kind: "doc_expiring", DedupKey: "doc_expiring:" + r.ID.String() + ":15",
				Title: label + " vence en " + strconv.Itoa(days) + " días",
				Body:  label + " vence el " + due + ". Puedes enviar el nuevo desde ya; el actual sigue vigente hasta esa fecha.",
			}
		}
		isNew, err := s.Notify.Notify(ctx, r.DriverID, n)
		if err != nil {
			return created, err
		}
		if isNew {
			created++
		}
	}
	return created, nil
}

// RunExpirySweeper checks expiries every interval until ctx ends.
func (s *Service) RunExpirySweeper(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if n, err := s.CheckExpiries(ctx); err != nil {
				s.logger().ErrorContext(ctx, "check document expiries", "err", err)
			} else if n > 0 {
				s.logger().InfoContext(ctx, "document expiry notices", "count", n)
			}
		}
	}
}
