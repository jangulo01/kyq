package radio

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// US11, FR-036/037: reportar, cola sin contenido, abrir con acceso registrado y resolver.
func TestIntegrationReports(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos, f.jonathan, f.pedro)
	var suspended []uuid.UUID
	f.svc.SuspendUser = func(_ context.Context, userID, _ uuid.UUID, reason string) error {
		suspended = append(suspended, userID)
		assert.Contains(t, reason, "Radio: mensaje reportado")
		return nil
	}
	conv := f.channel(t, f.carlos, "Taxistas Norte", JoinOpenLink, nil)
	f.join(t, conv, f.carlos, f.jonathan)
	f.join(t, conv, f.carlos, f.pedro)
	voice := f.voice(t, f.jonathan, conv, 2*time.Second)
	txt, err := f.svc.Send(ctx, f.jonathan, conv, SendInput{Kind: MessageText, Body: "insulto"})
	require.NoError(t, err)

	assert.ErrorIs(t, f.svc.ReportMessage(ctx, f.jonathan, txt.ID, ""), ErrInvalid, "no se reporta lo propio")
	assert.ErrorIs(t, f.svc.ReportMessage(ctx, f.ana, txt.ID, ""), ErrNotFound, "solo quien lo ve")
	require.NoError(t, f.svc.ReportMessage(ctx, f.carlos, txt.ID, "ofensivo"))
	require.NoError(t, f.svc.ReportMessage(ctx, f.carlos, txt.ID, "otra vez"), "dos veces es lo mismo")
	require.NoError(t, f.svc.ReportMessage(ctx, f.pedro, txt.ID, ""))
	require.NoError(t, f.svc.ReportMessage(ctx, f.pedro, voice, "grito"))

	queue, err := f.svc.Reports(ctx)
	require.NoError(t, err)
	require.Len(t, queue, 3)
	assert.Equal(t, "Taxistas Norte", queue[0].ConversationTitle)
	assert.Equal(t, MessageText, queue[0].MessageKind)

	// Abrir el reporte queda registrado y trae el audio.
	var voiceReport Report
	for _, r := range queue {
		if r.MessageKind == MessageVoice {
			voiceReport = r
		}
	}
	d, err := f.svc.OpenReport(ctx, f.admin, voiceReport.ID)
	require.NoError(t, err)
	assert.Equal(t, "Jonathan", d.AuthorName)
	require.NotNil(t, d.MediaURL)
	var opened int
	require.NoError(t, f.st.Pool.QueryRow(ctx, `SELECT count(*) FROM radio_report_access WHERE report_id = $1 AND admin_id = $2`, voiceReport.ID, f.admin).Scan(&opened))
	assert.Equal(t, 1, opened)

	// Borrar el mensaje cierra los dos reportes del texto y lo quita del historial.
	textReport := queue[0]
	require.NoError(t, f.svc.ResolveReport(ctx, f.admin, textReport.ID, ResolveInput{Decision: DecisionMessageDeleted, Note: "lenguaje"}))
	queue, err = f.svc.Reports(ctx)
	require.NoError(t, err)
	require.Len(t, queue, 1)
	hist, err := f.svc.History(ctx, f.carlos, conv, nil, 20)
	require.NoError(t, err)
	for _, m := range hist {
		assert.NotEqual(t, txt.ID, m.ID)
	}
	assert.ErrorIs(t, f.svc.ResolveReport(ctx, f.admin, textReport.ID, ResolveInput{Decision: DecisionDismissed}), ErrInvalid, "ya resuelto")

	// Suspender al autor (007) y el canal.
	require.NoError(t, f.svc.ResolveReport(ctx, f.admin, voiceReport.ID, ResolveInput{Decision: DecisionUserSuspended}))
	assert.Equal(t, []uuid.UUID{f.jonathan}, suspended)
	old := mustRoom(t, f, conv)
	require.NoError(t, f.svc.SetChannelSuspended(ctx, conv, true))
	c, err := f.st.GetRadioConversation(ctx, conv)
	require.NoError(t, err)
	assert.Equal(t, store.RadioConversationStatusSuspended, c.Status)
	assert.Contains(t, f.rooms.deleted, old, "todos salen de la sala")
	_, err = f.svc.TakeFloor(ctx, f.carlos, conv)
	assert.ErrorIs(t, err, ErrSuspended)
	require.NoError(t, f.svc.SetChannelSuspended(ctx, conv, false))
	_, err = f.svc.TakeFloor(ctx, f.carlos, conv)
	require.NoError(t, err)

	direct := f.contact(t, f.carlos, f.pedro)
	assert.ErrorIs(t, f.svc.SetChannelSuspended(ctx, direct, true), ErrNotChannel)
}
