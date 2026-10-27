package trips

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var t0 = time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)

func newTrip() *Trip {
	return NewTrip(uuid.New(), uuid.New(), uuid.New(), "bogota", "COP",
		Point{Lat: 4.60, Lng: -74.08}, Point{Lat: 4.65, Lng: -74.05}, 5200, 900, 1_250_000, t0)
}

func at(d time.Duration) time.Time { return t0.Add(d) }

func fare(v int64) *int64 { return &v }

// --- Máquina de estados (T040) ---

func TestHappyPathWithSuggestedFare(t *testing.T) {
	tr := newTrip()
	require.Equal(t, StatusRequested, tr.Status)
	require.NoError(t, tr.Accept(Driver, nil, at(5*time.Second)))
	assert.Equal(t, StatusAccepted, tr.Status)
	require.NoError(t, tr.Arrive(Driver, at(time.Minute)))
	require.NoError(t, tr.Start(Driver, at(2*time.Minute)))
	require.NoError(t, tr.Complete(Driver, at(20*time.Minute)))
	assert.Equal(t, StatusCompleted, tr.Status)
	assert.Nil(t, tr.RespondBy)
}

func TestInvalidTransitions(t *testing.T) {
	tr := newTrip()
	assert.ErrorIs(t, tr.Arrive(Driver, t0), ErrInvalidTransition)
	assert.ErrorIs(t, tr.Complete(Driver, t0), ErrInvalidTransition)
	assert.ErrorIs(t, tr.RespondNegotiation(Passenger, true, t0), ErrInvalidTransition)
	_, err := tr.Propose(Passenger, 1000, t0)
	assert.ErrorIs(t, err, ErrInvalidTransition)

	require.NoError(t, tr.Accept(Driver, nil, t0))
	assert.ErrorIs(t, tr.Accept(Driver, nil, t0), ErrInvalidTransition)
	assert.ErrorIs(t, tr.Start(Driver, t0), ErrInvalidTransition, "hay que llegar antes de iniciar")

	require.NoError(t, tr.Arrive(Driver, t0))
	require.NoError(t, tr.Start(Driver, t0))
	assert.ErrorIs(t, tr.Cancel(Passenger, t0), ErrInvalidTransition, "no se cancela un viaje en curso")
}

func TestCancelBeforeInProgress(t *testing.T) {
	for _, party := range []Party{Passenger, Driver} {
		tr := newTrip()
		require.NoError(t, tr.Accept(Driver, nil, t0))
		require.NoError(t, tr.Arrive(Driver, t0))
		require.NoError(t, tr.Cancel(party, at(time.Minute)))
		assert.Equal(t, StatusCancelled, tr.Status)
		assert.Equal(t, string(party), *tr.CancelReason)
	}
}

// --- Reglas (T041) ---

// RN-KYQ-001: el conductor recibe el 100 % de la tarifa acordada.
func TestRN001FullPayoutToDriver(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.Accept(Driver, fare(1_400_000), t0))
	require.NoError(t, tr.DecideProposal(Passenger, tr.Proposal.ID, true, at(10*time.Second)))
	require.NoError(t, tr.Arrive(Driver, t0))
	require.NoError(t, tr.Start(Driver, t0))
	require.NoError(t, tr.Complete(Driver, t0))
	assert.Equal(t, int64(1_400_000), *tr.AgreedFare)
	assert.Equal(t, *tr.AgreedFare, *tr.DriverPayout)
}

// RN-KYQ-007: oferta exclusiva de 25 s.
func TestRN007OfferWindow(t *testing.T) {
	tr := newTrip()
	assert.Equal(t, at(25*time.Second), *tr.RespondBy)
	assert.False(t, tr.Expire(at(24*time.Second)))
	assert.ErrorIs(t, tr.Accept(Driver, nil, at(25*time.Second)), ErrExpired)
	assert.True(t, tr.Expire(at(25*time.Second)))
	assert.Equal(t, StatusCancelled, tr.Status)
	assert.Equal(t, CancelOfferExpired, *tr.CancelReason)
}

func TestDriverRejectsOffer(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.Reject(Driver, t0))
	assert.Equal(t, CancelOfferRejected, *tr.CancelReason)
}

// FR-010a: el conductor cambia la tarifa y el pasajero confirma en 30 s.
func TestFR010aDriverChangesFare(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.Accept(Driver, fare(1_100_000), at(5*time.Second)))
	assert.Equal(t, StatusFarePending, tr.Status)
	require.NotNil(t, tr.Proposal)
	assert.Equal(t, Driver, tr.Proposal.ProposedBy)
	assert.Equal(t, at(35*time.Second), *tr.RespondBy)

	assert.ErrorIs(t, tr.DecideProposal(Driver, tr.Proposal.ID, true, at(10*time.Second)), ErrForbidden,
		"nadie acepta su propia propuesta")

	// Sin respuesta en 30 s: cancelado sin cargo.
	assert.True(t, tr.Expire(at(35*time.Second)))
	assert.Equal(t, CancelFareRejected, *tr.CancelReason)
	require.Len(t, tr.ClosedProposals, 1)
	assert.Equal(t, ProposalExpired, tr.ClosedProposals[0].Status)
}

func TestFR010aPassengerRejectsNewFare(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.Accept(Driver, fare(1_100_000), t0))
	require.NoError(t, tr.DecideProposal(Passenger, tr.Proposal.ID, false, at(5*time.Second)))
	assert.Equal(t, StatusCancelled, tr.Status)
	assert.Equal(t, CancelFareRejected, *tr.CancelReason)
}

func TestAcceptWithSameFareSkipsConfirmation(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.Accept(Driver, fare(tr.SuggestedFare), t0))
	assert.Equal(t, StatusAccepted, tr.Status)
}

// FR-010c: negociación solo con consentimiento del pasajero.
func TestFR010cNegotiationDeclinedKeepsSuggestedFare(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.RequestNegotiation(Driver, at(5*time.Second)))
	assert.Equal(t, StatusNegotiationPending, tr.Status)
	assert.ErrorIs(t, tr.RespondNegotiation(Driver, true, at(6*time.Second)), ErrForbidden, "decide el pasajero")

	require.NoError(t, tr.RespondNegotiation(Passenger, false, at(10*time.Second)))
	assert.Equal(t, StatusRequested, tr.Status)
	assert.Equal(t, at(35*time.Second), *tr.RespondBy, "el conductor tiene 25 s nuevos")
	require.NoError(t, tr.Accept(Driver, nil, at(20*time.Second)))
	assert.Equal(t, tr.SuggestedFare, *tr.AgreedFare)
}

func TestFR010cNegotiationRequestUnansweredGoesBackToOffer(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.RequestNegotiation(Driver, t0))
	assert.True(t, tr.Expire(at(30*time.Second)))
	assert.Equal(t, StatusRequested, tr.Status)
}

func TestFR010cNegotiationAgreement(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.RequestNegotiation(Driver, t0))
	require.NoError(t, tr.RespondNegotiation(Passenger, true, at(5*time.Second)))
	assert.Equal(t, StatusNegotiating, tr.Status)
	assert.Equal(t, at(5*time.Second+3*time.Minute), *tr.NegotiationExpiresAt)

	first, err := tr.Propose(Driver, 1_500_000, at(10*time.Second))
	require.NoError(t, err)
	counter, err := tr.Propose(Passenger, 1_300_000, at(20*time.Second))
	require.NoError(t, err)
	require.Len(t, tr.ClosedProposals, 1)
	assert.Equal(t, first.ID, tr.ClosedProposals[0].ID)
	assert.Equal(t, ProposalSuperseded, tr.ClosedProposals[0].Status)

	assert.ErrorIs(t, tr.DecideProposal(Driver, first.ID, true, at(25*time.Second)), ErrNoOpenProposal)
	require.NoError(t, tr.DecideProposal(Driver, counter.ID, true, at(25*time.Second)))
	assert.Equal(t, StatusAccepted, tr.Status)
	assert.Equal(t, int64(1_300_000), *tr.AgreedFare)
}

func TestFR010cRejectKeepsNegotiating(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.RequestNegotiation(Driver, t0))
	require.NoError(t, tr.RespondNegotiation(Passenger, true, t0))
	p, err := tr.Propose(Driver, 2_000_000, at(time.Second))
	require.NoError(t, err)
	require.NoError(t, tr.DecideProposal(Passenger, p.ID, false, at(2*time.Second)))
	assert.Equal(t, StatusNegotiating, tr.Status)
	assert.Nil(t, tr.Proposal)
	_, err = tr.Propose(Passenger, 1_200_000, at(3*time.Second))
	assert.NoError(t, err, "tras rechazar se puede contraproponer")
}

func TestFR010cProposalTimeoutCancels(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.RequestNegotiation(Driver, t0))
	require.NoError(t, tr.RespondNegotiation(Passenger, true, t0))
	_, err := tr.Propose(Driver, 1_500_000, at(10*time.Second))
	require.NoError(t, err)
	assert.False(t, tr.Expire(at(39*time.Second)))
	assert.True(t, tr.Expire(at(40*time.Second)))
	assert.Equal(t, CancelNegotiationFail, *tr.CancelReason)
}

func TestFR010cNegotiationCappedAtThreeMinutes(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.RequestNegotiation(Driver, t0))
	require.NoError(t, tr.RespondNegotiation(Passenger, true, t0))
	var err error
	for i := range 6 { // propuestas cada 25 s
		_, err = tr.Propose(Party([]Party{Driver, Passenger}[i%2]), int64(1_000_000+i), at(time.Duration(i*25)*time.Second))
		require.NoError(t, err)
	}
	_, err = tr.Propose(Driver, 999, at(152*time.Second))
	require.NoError(t, err)
	assert.Equal(t, at(3*time.Minute), *tr.RespondBy, "el plazo no supera los 3 min de negociación")
	assert.True(t, tr.Expire(at(3*time.Minute)))
	assert.Equal(t, CancelNegotiationFail, *tr.CancelReason)
}

func TestNegotiationWithoutFirstProposalCancels(t *testing.T) {
	tr := newTrip()
	require.NoError(t, tr.RequestNegotiation(Driver, t0))
	require.NoError(t, tr.RespondNegotiation(Passenger, true, t0))
	assert.True(t, tr.Expire(at(30*time.Second)))
	assert.Equal(t, CancelNegotiationFail, *tr.CancelReason)
}

// Autorización por parte (contracts/api.yaml).
func TestOnlyDriverAdvancesTrip(t *testing.T) {
	tr := newTrip()
	assert.ErrorIs(t, tr.Accept(Passenger, nil, t0), ErrForbidden)
	assert.ErrorIs(t, tr.Reject(Passenger, t0), ErrForbidden)
	assert.ErrorIs(t, tr.RequestNegotiation(Passenger, t0), ErrForbidden)
	require.NoError(t, tr.Accept(Driver, nil, t0))
	assert.ErrorIs(t, tr.Arrive(Passenger, t0), ErrForbidden)
}

func TestPartyOf(t *testing.T) {
	tr := newTrip()
	p, ok := tr.PartyOf(tr.DriverID)
	assert.True(t, ok)
	assert.Equal(t, Driver, p)
	_, ok = tr.PartyOf(uuid.New())
	assert.False(t, ok, "terceros no son parte del viaje")
}

func TestInvalidAmount(t *testing.T) {
	tr := newTrip()
	assert.ErrorIs(t, tr.Accept(Driver, fare(0), t0), ErrInvalidAmount)
}
