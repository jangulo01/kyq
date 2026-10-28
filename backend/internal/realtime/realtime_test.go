package realtime

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type fakeAffiliations map[[2]uuid.UUID]bool

func (f fakeAffiliations) IsAffiliated(_ context.Context, p, d uuid.UUID) (bool, error) {
	return f[[2]uuid.UUID{p, d}], nil
}

type fakeTrips map[[2]uuid.UUID]bool

func (f fakeTrips) IsParticipant(_ context.Context, trip, user uuid.UUID) (bool, error) {
	return f[[2]uuid.UUID{trip, user}], nil
}

func TestAuthorize(t *testing.T) {
	ctx := context.Background()
	me, other, driver, trip := uuid.New(), uuid.New(), uuid.New(), uuid.New()
	a := Authorizer{
		Affiliations: fakeAffiliations{{me, driver}: true},
		Trips:        fakeTrips{{trip, me}: true},
	}

	assert.NoError(t, a.Authorize(ctx, me, "user:"+me.String()))
	assert.ErrorIs(t, a.Authorize(ctx, me, "user:"+other.String()), ErrForbiddenChannel)
	assert.NoError(t, a.Authorize(ctx, me, "driver_presence:"+driver.String()))
	assert.ErrorIs(t, a.Authorize(ctx, other, "driver_presence:"+driver.String()), ErrForbiddenChannel)
	assert.NoError(t, a.Authorize(ctx, driver, "driver_presence:"+driver.String()), "el conductor ve su propia presencia")
	assert.NoError(t, a.Authorize(ctx, me, "trip:"+trip.String()))
	assert.ErrorIs(t, a.Authorize(ctx, other, "trip:"+trip.String()), ErrForbiddenChannel)
	assert.ErrorIs(t, a.Authorize(ctx, me, "admin:"+me.String()), ErrForbiddenChannel)
	assert.ErrorIs(t, a.Authorize(ctx, me, "user:no-uuid"), ErrForbiddenChannel)

	empty := Authorizer{}
	assert.ErrorIs(t, empty.Authorize(ctx, me, "trip:"+trip.String()), ErrForbiddenChannel, "sin verificador se deniega")
}

// 007: el canal de la torre solo para admins; el resto de canales sigue la regla de Authorize.
func TestAuthorizeRoleAdminTower(t *testing.T) {
	ctx := context.Background()
	me := uuid.New()
	a := Authorizer{}
	assert.NoError(t, a.AuthorizeRole(ctx, me, "admin", AdminTowerChannel))
	for _, role := range []string{"passenger", "driver", ""} {
		assert.ErrorIs(t, a.AuthorizeRole(ctx, me, role, AdminTowerChannel), ErrForbiddenChannel, role)
	}
	assert.ErrorIs(t, a.AuthorizeRole(ctx, me, "admin", "admin:otro"), ErrForbiddenChannel)
	assert.NoError(t, a.AuthorizeRole(ctx, me, "passenger", "user:"+me.String()))
	assert.ErrorIs(t, a.AuthorizeRole(ctx, me, "admin", "user:"+uuid.NewString()), ErrForbiddenChannel)
}

func TestPublish(t *testing.T) {
	var got struct {
		Channel string `json:"channel"`
		Data    Event  `json:"data"`
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "/api/publish", r.URL.Path)
		assert.Equal(t, "key", r.Header.Get("X-API-Key"))
		require.NoError(t, json.NewDecoder(r.Body).Decode(&got))
		_, _ = w.Write([]byte(`{"result":{}}`))
	}))
	defer srv.Close()

	c := &Client{APIURL: srv.URL + "/api", APIKey: "key"}
	ev := Event{Type: "driver.presence", OccurredAt: time.Unix(0, 0).UTC(), Data: map[string]string{"presence": "free"}}
	require.NoError(t, c.Publish(context.Background(), "driver_presence:x", ev))
	assert.Equal(t, "driver_presence:x", got.Channel)
	assert.Equal(t, "driver.presence", got.Data.Type)
}

func TestPublishReportsCentrifugoError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"error":{"code":102,"message":"unknown channel"}}`))
	}))
	defer srv.Close()

	c := &Client{APIURL: srv.URL, APIKey: "key"}
	assert.ErrorContains(t, c.Publish(context.Background(), "x", Event{}), "unknown channel")
}
