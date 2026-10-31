package radio

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// failingSMS fails the first sends to some phones; the rest reach inner.
type failingSMS struct {
	inner    *fakeSMS
	mu       sync.Mutex
	failures map[string]int
}

func (f *failingSMS) SendSMS(ctx context.Context, phone, body string) error {
	f.mu.Lock()
	if f.failures[phone] > 0 {
		f.failures[phone]--
		f.mu.Unlock()
		return errors.New("twilio caído")
	}
	f.mu.Unlock()
	return f.inner.SendSMS(ctx, phone, body)
}

func rowsByLine(d BulkUploadDetail) map[int]BulkRow {
	out := map[int]BulkRow{}
	for _, r := range d.Rows {
		out[r.Line] = r
	}
	return out
}

// US10, FR-033/034: CSV validado sin enviar, canales nuevos con su dueño, un SMS por fila
// válida, estados por fila y reenvío de las fallidas sin volver a escribir a quien aceptó.
func TestIntegrationBulkUpload(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.svc.SMS = &failingSMS{inner: f.sms, failures: map[string]int{"+573005550203": 2}}
	f.svc.BulkSMSInterval = 1
	f.consent(t, f.jonathan)
	existing := f.channel(t, f.jonathan, "Taxistas Sur", JoinApproval, nil)
	f.join(t, existing, f.jonathan, f.pedro)
	require.NoError(t, f.svc.Moderate(ctx, f.jonathan, existing, f.pedro, ModerateInput{Action: ptr(ActApprove)}))

	csv := "nombre;telefono;tipo;canal;rol\n" +
		"Carlos;300 000 0001;conductor;Taxistas Norte;dueño\n" + // línea 2: Carlos ya usa Kyq: será dueño
		"Luis;3005550202;conductor;Taxistas Norte;miembro\n" +
		"Marta;3005550203;conductor;Taxistas Norte;moderador\n" +
		"Sin teléfono;12;conductor;Taxistas Norte;miembro\n" + // 5: inválido
		"Luis otra vez;+57 300 555 0202;conductor;Taxistas Norte;\n" + // 6: repetido
		"Pedro;3100000003;conductor;Taxistas Sur;miembro\n" + // 7: ya está en el canal
		"Rosa;3005550207;conductor;Canal Fantasma;miembro\n" + // 8: canal sin dueño
		"Ana;3200000001;pasajero;Taxistas Norte;oyente\n" + // 9: el panel no admite pasajeros
		"Juan;3005550209;chofer;Taxistas Norte;miembro\n" // 10: tipo inválido
	// El teléfono de Carlos en el fixture es +573100000001.
	csv = strings.Replace(csv, "300 000 0001", "310 000 0001", 1)

	d, err := f.svc.UploadBulk(ctx, f.admin, "flota.csv", []byte(csv))
	require.NoError(t, err)
	assert.Equal(t, 9, d.RowsTotal)
	assert.Empty(t, f.sms.sent, "validar no envía nada")
	_, err = f.st.GetRadioActiveChannelByName(ctx, "Taxistas Norte")
	assert.True(t, store.IsNotFound(err), "ni crea canales")
	rows := rowsByLine(d)
	for line, want := range map[int]string{
		5: "teléfono inválido", 6: "repetido: ya está en la línea 3", 8: "el canal no existe: agrega una fila con su dueño (rol dueño)",
		9: "el panel no admite pasajeros en canales", 10: "tipo inválido: usa conductor o pasajero",
	} {
		require.NotNil(t, rows[line].Error, "línea %d", line)
		assert.Equal(t, want, *rows[line].Error, "línea %d", line)
		assert.Equal(t, "failed", rows[line].Status)
	}
	assert.Equal(t, "+57 300 *** **02", rows[3].PhoneMasked, "sin el teléfono completo")
	assert.Equal(t, 5, d.Counts["failed"])
	assert.Equal(t, 4, d.Counts["pending"])

	require.NoError(t, f.svc.SendBulk(ctx, d.ID, false))
	assert.ErrorIs(t, f.svc.SendBulk(ctx, d.ID, false), ErrBulkState, "no se confirma dos veces")
	d, err = f.svc.BulkDetail(ctx, d.ID)
	require.NoError(t, err)
	assert.Equal(t, BulkStatusDone, d.Status)
	rows = rowsByLine(d)
	assert.Equal(t, "already_member", rows[2].Status, "el dueño queda en su canal")
	assert.Equal(t, "sent", rows[3].Status)
	assert.Equal(t, "failed", rows[4].Status, "dos intentos fallidos")
	assert.Equal(t, "already_member", rows[7].Status)
	conv, err := f.st.GetRadioActiveChannelByName(ctx, "Taxistas Norte")
	require.NoError(t, err)
	role, _ := f.status(t, conv.ID, f.carlos)
	assert.Equal(t, store.RadioRoleOwner, role)
	luis := f.sms.to("+573005550202")
	require.Len(t, luis, 1)
	assert.Contains(t, luis[0], "Carlos te invita al canal Taxistas Norte de Radio Kyq: https://kyq.test/r/")
	assert.Contains(t, luis[0], "/baja", "FR-035: cómo darse de baja")
	assert.Empty(t, f.sms.to("+573100000003"), "a quien ya está no se le escribe")

	// Luis se registra con ese teléfono y entra al canal sin aprobación (invitación del panel).
	code := f.phoneInvite(t, "+573005550202")
	luisID := f.newDriver(t, "+573005550202", "Luis")
	res, err := f.svc.Accept(ctx, luisID, code)
	require.NoError(t, err)
	assert.False(t, res.Pending)
	assert.Equal(t, conv.ID, res.Conversation.ID)
	role, st := f.status(t, conv.ID, luisID)
	assert.Equal(t, store.RadioRoleMember, role)
	assert.Equal(t, store.RadioMemberStatusActive, st)

	// Reenviar solo las fallidas: Marta recibe el SMS; a Luis (aceptó) no se le escribe otra vez.
	require.NoError(t, f.svc.SendBulk(ctx, d.ID, true))
	d, err = f.svc.BulkDetail(ctx, d.ID)
	require.NoError(t, err)
	rows = rowsByLine(d)
	assert.Equal(t, "sent", rows[4].Status)
	assert.Equal(t, "accepted", rows[3].Status)
	assert.Len(t, f.sms.to("+573005550202"), 1)
	assert.Equal(t, "failed", rows[5].Status, "un error de validación no se reenvía")

	list, err := f.svc.BulkUploads(ctx)
	require.NoError(t, err)
	require.Len(t, list, 1)
	assert.Equal(t, "flota.csv", list[0].FileName)
	assert.Equal(t, 1, list[0].Counts["accepted"])
}

func TestBulkCSVLimits(t *testing.T) {
	var b strings.Builder
	for i := range MaxBulkRows + 1 {
		fmt.Fprintf(&b, "Conductor %d,300%07d,conductor,Canal Grande,miembro\n", i, i)
	}
	_, err := readBulkCSV([]byte(b.String()))
	assert.ErrorIs(t, err, ErrBulkTooLarge)

	lines, err := readBulkCSV([]byte("\xef\xbb\xbfnombre,telefono,tipo,canal,rol\nAna,3001234567,pasajero,Canal,oyente\nPepe,3001234568,conductor,Canal,jefe\n"))
	require.NoError(t, err)
	require.Len(t, lines, 2)
	assert.Equal(t, "+573001234567", lines[0].phone)
	assert.Equal(t, store.UserRolePassenger, lines[0].kind)
	assert.Equal(t, RoleListener, lines[0].role)
	assert.Equal(t, "rol inválido: usa dueño, moderador, miembro u oyente", lines[1].err)
}
