package radio

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// lastPresence is the last state of about that reached to.
func lastPresence(f *fixture, to, about uuid.UUID) string {
	got := ""
	for _, e := range f.pub.events(to, EventPresence) {
		if e["user_id"] == about {
			got, _ = e["status"].(string)
		}
	}
	return got
}

// US5, FR-019: el estado propio llega a los contactos; sin latido 90 s queda Desconectado.
func TestIntegrationPresence(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.contact(t, f.carlos, f.jonathan)
	carlos, jon := f.carlos, f.jonathan

	require.NoError(t, f.svc.Heartbeat(ctx, f.carlos))
	assert.Equal(t, StatusAvailable, lastPresence(f, jon, carlos), "encender la radio lo anuncia")
	_, err := f.svc.UpdateMe(ctx, f.carlos, MeUpdate{Status: ptr(StatusBusy)})
	require.NoError(t, err)
	assert.Equal(t, StatusBusy, lastPresence(f, jon, carlos))
	_, err = f.svc.UpdateMe(ctx, f.carlos, MeUpdate{Status: ptr("durmiendo")})
	assert.ErrorIs(t, err, ErrInvalid)

	list, err := f.svc.List(ctx, f.jonathan)
	require.NoError(t, err)
	assert.Equal(t, StatusBusy, *list[0].PeerStatus)

	// 30 s de latido lo mantienen; 90 s sin él, Desconectado.
	f.advance(30 * time.Second)
	require.NoError(t, f.svc.Heartbeat(ctx, f.carlos))
	f.advance(60 * time.Second)
	require.NoError(t, f.svc.Sweep(ctx))
	assert.Equal(t, StatusBusy, lastPresence(f, jon, carlos))
	f.advance(31 * time.Second)
	require.NoError(t, f.svc.Sweep(ctx))
	assert.Equal(t, StatusOffline, lastPresence(f, jon, carlos))
	list, err = f.svc.List(ctx, f.jonathan)
	require.NoError(t, err)
	assert.Equal(t, StatusOffline, *list[0].PeerStatus)
	require.NoError(t, f.svc.Heartbeat(ctx, f.carlos))
	assert.Equal(t, StatusBusy, lastPresence(f, jon, carlos), "vuelve con su estado")
}

// FR-021: horario de silencio en la zona horaria del usuario; al empezar pasa a Ocupado y al
// terminar vuelve a su estado. Elegir un estado a mano durante el horario se respeta.
func TestIntegrationQuietHours(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	lima, err := time.LoadLocation("America/Lima")
	require.NoError(t, err)
	// Próximo lunes a las 21:58 en Lima.
	start := time.Now().In(lima)
	for start.Weekday() != time.Monday || !start.After(time.Now()) {
		start = time.Date(start.Year(), start.Month(), start.Day()+1, 21, 58, 0, 0, lima)
	}
	*f.clock = start.UTC()
	_, err = f.svc.UpdateMe(ctx, f.carlos, MeUpdate{Timezone: ptr("America/Lima")})
	require.NoError(t, err)
	_, err = f.svc.UpdateMe(ctx, f.carlos, MeUpdate{Timezone: ptr("Marte/Olimpo")})
	assert.ErrorIs(t, err, ErrInvalid)
	// Lunes a viernes de 22:00 a 06:00: cruza la medianoche.
	require.NoError(t, f.svc.SetQuietHours(ctx, f.carlos, []QuietHoursRule{
		{Weekdays: []int{1, 2, 3, 4, 5}, Starts: "22:00", Ends: "06:00", Enabled: true},
	}))
	assert.ErrorIs(t, f.svc.SetQuietHours(ctx, f.carlos, []QuietHoursRule{{Weekdays: []int{8}, Starts: "22:00", Ends: "06:00"}}), ErrInvalid)
	rules, err := f.svc.GetQuietHours(ctx, f.carlos)
	require.NoError(t, err)
	require.Len(t, rules, 1)
	assert.Equal(t, "22:00", rules[0].Starts)

	status := func() string {
		me, err := f.svc.Me(ctx, f.carlos)
		require.NoError(t, err)
		return me.Status
	}
	require.NoError(t, f.svc.QuietHours(ctx))
	assert.Equal(t, StatusAvailable, status())
	f.advance(2 * time.Minute) // 22:00 en Lima
	require.NoError(t, f.svc.QuietHours(ctx))
	assert.Equal(t, StatusBusy, status(), "empieza el silencio")
	assert.NotEmpty(t, f.pub.events(f.carlos, EventPresence), "su barra superior cambia sola")

	f.advance(8 * time.Hour) // martes 06:00
	require.NoError(t, f.svc.QuietHours(ctx))
	assert.Equal(t, StatusAvailable, status(), "vuelve a su estado")

	// Martes 22:00 otra vez en silencio; elige Solo escucha a mano y al terminar se respeta.
	f.advance(16 * time.Hour)
	require.NoError(t, f.svc.QuietHours(ctx))
	assert.Equal(t, StatusBusy, status())
	_, err = f.svc.UpdateMe(ctx, f.carlos, MeUpdate{Status: ptr(StatusListenOnly)})
	require.NoError(t, err)
	f.advance(8 * time.Hour)
	require.NoError(t, f.svc.QuietHours(ctx))
	assert.Equal(t, StatusListenOnly, status())
}
