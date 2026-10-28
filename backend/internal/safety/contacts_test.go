package safety_test

import (
	"context"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/trips"
)

func TestIntegrationEmergencyContacts(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	contacts, err := f.svc.Contacts(ctx, f.passenger)
	require.NoError(t, err)
	assert.Empty(t, contacts)

	four := []safety.Contact{
		{Name: "Mamá", PhoneE164: "+573001110001"}, {Name: "Papá", PhoneE164: "+573001110002"},
		{Name: "Hermana", PhoneE164: "+573001110003"}, {Name: "Tía", PhoneE164: "+573001110004"},
	}
	_, err = f.svc.SetContacts(ctx, f.passenger, four)
	assert.ErrorIs(t, err, safety.ErrTooManyContacts, "máximo 3 (FR-016)")
	_, err = f.svc.SetContacts(ctx, f.passenger, []safety.Contact{{Name: "Mamá", PhoneE164: "3001110001"}})
	assert.ErrorIs(t, err, safety.ErrInvalidContact, "teléfono en E.164")
	_, err = f.svc.SetContacts(ctx, f.passenger, []safety.Contact{{Name: "M", PhoneE164: "+573001110001"}})
	assert.ErrorIs(t, err, safety.ErrInvalidContact)

	saved, err := f.svc.SetContacts(ctx, f.passenger, []safety.Contact{{Name: "  Mamá ", PhoneE164: "+573001110001"}, four[1]})
	require.NoError(t, err)
	assert.Equal(t, "Mamá", saved[0].Name)
	contacts, err = f.svc.Contacts(ctx, f.passenger)
	require.NoError(t, err)
	assert.Equal(t, saved, contacts)

	// US4-2: al crear la alerta cada contacto recibe un SMS con el nombre y el enlace del viaje.
	tripID := f.trip(t, trips.StatusInProgress)
	f.raise(t, f.passenger, tripID)
	link, err := f.svc.Share(ctx, f.passenger, tripID)
	require.NoError(t, err)
	for _, c := range contacts {
		got := f.sms.to(c.PhoneE164)
		require.Len(t, got, 1, c.Name)
		assert.Contains(t, got[0], "Ana")
		assert.Contains(t, got[0], link.URL)
		assert.NotContains(t, got[0], passengerPhone)
	}
	assert.Empty(t, f.sms.to(four[2].PhoneE164))

	_, err = f.svc.SetContacts(ctx, f.passenger, nil)
	require.NoError(t, err)
	contacts, err = f.svc.Contacts(ctx, f.passenger)
	require.NoError(t, err)
	assert.Empty(t, contacts)
}

func TestIntegrationSafetyPIN(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	has, err := f.svc.HasPIN(ctx, f.driver)
	require.NoError(t, err)
	assert.False(t, has)

	for _, bad := range []string{"123", "12345", "abcd", ""} {
		assert.ErrorIs(t, f.svc.SetPIN(ctx, f.driver, bad, nil), safety.ErrInvalidPINFormat, bad)
	}
	require.NoError(t, f.svc.SetPIN(ctx, f.driver, "4321", nil))
	row, err := f.st.GetSafetyPin(ctx, f.driver)
	require.NoError(t, err)
	assert.NotContains(t, row.PinHash, "4321", "guardado de forma no reversible")
	assert.True(t, strings.HasPrefix(row.PinHash, "$2"), "bcrypt")

	assert.ErrorIs(t, f.svc.SetPIN(ctx, f.driver, "1111", nil), safety.ErrWrongCurrentPIN, "cambiarlo pide el actual")
	wrong := "0000"
	assert.ErrorIs(t, f.svc.SetPIN(ctx, f.driver, "1111", &wrong), safety.ErrWrongCurrentPIN)
	current := "4321"
	require.NoError(t, f.svc.SetPIN(ctx, f.driver, "1111", &current))

	id := f.raise(t, f.driver, f.trip(t, trips.StatusAccepted)).Alert.ID
	assert.ErrorIs(t, f.svc.Cancel(ctx, f.driver, id, "4321"), safety.ErrInvalidPIN, "el PIN viejo ya no vale")
	require.NoError(t, f.svc.Cancel(ctx, f.driver, id, "1111"))
}
