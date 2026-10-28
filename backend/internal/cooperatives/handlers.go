package cooperatives

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
)

// Handlers serves /v1/admin/cooperatives/*, /v1/admin/memberships/*, /v1/cooperatives and
// /v1/driver/cooperative/* (contracts/api.yaml).
type Handlers struct{ Service *Service }

// Register mounts the routes behind authMW and the role checks.
func (h *Handlers) Register(mux *http.ServeMux, authMW func(http.Handler) http.Handler) {
	admin := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleAdmin)(f)) }
	driver := func(f http.HandlerFunc) http.Handler { return authMW(auth.RequireRole(auth.RoleDriver)(f)) }

	mux.Handle("GET /v1/admin/cooperatives", admin(h.adminList))
	mux.Handle("POST /v1/admin/cooperatives", admin(h.create))
	mux.Handle("GET /v1/admin/cooperatives/{cooperativeId}", admin(h.detail))
	mux.Handle("PATCH /v1/admin/cooperatives/{cooperativeId}", admin(h.update))
	mux.Handle("POST /v1/admin/cooperatives/{cooperativeId}/members", admin(h.addMember))
	mux.Handle("DELETE /v1/admin/cooperatives/{cooperativeId}/members/{driverId}", admin(h.adminRemove))
	mux.Handle("PUT /v1/admin/cooperatives/{cooperativeId}/members/{driverId}/role", admin(h.setRole))
	mux.Handle("POST /v1/admin/memberships/{membershipId}/decision", admin(h.decide(true)))

	mux.Handle("GET /v1/cooperatives", driver(h.driverList))
	mux.Handle("GET /v1/driver/cooperative", driver(h.mine))
	mux.Handle("POST /v1/driver/cooperative/requests", driver(h.request))
	mux.Handle("DELETE /v1/driver/cooperative/requests", driver(h.withdraw))
	mux.Handle("DELETE /v1/driver/cooperative/membership", driver(h.leave))
	mux.Handle("POST /v1/driver/cooperative/requests/{membershipId}/decision", driver(h.decide(false)))
	mux.Handle("DELETE /v1/driver/cooperative/members/{driverId}", driver(h.coordinatorRemove))
}

func pathID(w http.ResponseWriter, r *http.Request, name string, notFound error) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue(name))
	if err != nil {
		writeError(w, r, notFound)
		return uuid.Nil, false
	}
	return id, true
}

func (h *Handlers) adminList(w http.ResponseWriter, r *http.Request) { h.list(w, r, false) }

func (h *Handlers) driverList(w http.ResponseWriter, r *http.Request) { h.list(w, r, true) }

func (h *Handlers) list(w http.ResponseWriter, r *http.Request, onlyActive bool) {
	out, err := h.Service.List(r.Context(), onlyActive)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"cooperatives": out})
}

func (h *Handlers) create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name     string  `json:"name"`
		CityCode string  `json:"city_code"`
		NIT      *string `json:"nit"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	c, err := h.Service.Create(r.Context(), p.UserID, Input{Name: body.Name, CityCode: body.CityCode, NIT: body.NIT})
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, c)
}

func (h *Handlers) detail(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "cooperativeId", ErrNotFound)
	if !ok {
		return
	}
	d, err := h.Service.Detail(r.Context(), id)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, d)
}

func (h *Handlers) update(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "cooperativeId", ErrNotFound)
	if !ok {
		return
	}
	var raw map[string]json.RawMessage
	if !httpx.DecodeJSON(w, r, &raw) {
		return
	}
	var p Patch
	str := func(key string) (*string, bool) {
		v, present := raw[key]
		if !present {
			return nil, true
		}
		var s *string
		if err := json.Unmarshal(v, &s); err != nil {
			return nil, false
		}
		return s, true
	}
	valid := true
	if s, ok := str("name"); ok && s != nil {
		p.Name = s
	} else if !ok {
		valid = false
	}
	if s, ok := str("city_code"); ok && s != nil {
		p.CityCode = s
	} else if !ok {
		valid = false
	}
	if s, ok := str("status"); ok && s != nil {
		p.Status = s
	} else if !ok {
		valid = false
	}
	if _, present := raw["nit"]; present {
		s, ok := str("nit")
		if !ok {
			valid = false
		}
		p.NIT = &s
	}
	if !valid {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "cuerpo inválido")
		return
	}
	c, err := h.Service.Update(r.Context(), id, p)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, c)
}

func (h *Handlers) addMember(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "cooperativeId", ErrNotFound)
	if !ok {
		return
	}
	var body struct {
		DriverID uuid.UUID `json:"driver_id"`
		Role     string    `json:"role"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	m, err := h.Service.AddMember(r.Context(), p.UserID, id, body.DriverID, body.Role)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, m)
}

func (h *Handlers) setRole(w http.ResponseWriter, r *http.Request) {
	coop, ok := pathID(w, r, "cooperativeId", ErrNotFound)
	if !ok {
		return
	}
	driverID, ok := pathID(w, r, "driverId", ErrNotMember)
	if !ok {
		return
	}
	var body struct {
		Role string `json:"role"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	if err := h.Service.SetRole(r.Context(), coop, driverID, body.Role); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) adminRemove(w http.ResponseWriter, r *http.Request) {
	coop, ok := pathID(w, r, "cooperativeId", ErrNotFound)
	if !ok {
		return
	}
	h.remove(w, r, coop, true)
}

func (h *Handlers) coordinatorRemove(w http.ResponseWriter, r *http.Request) {
	h.remove(w, r, uuid.Nil, false)
}

func (h *Handlers) remove(w http.ResponseWriter, r *http.Request, coop uuid.UUID, admin bool) {
	driverID, ok := pathID(w, r, "driverId", ErrNotMember)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	if err := h.Service.Remove(r.Context(), Decider{UserID: p.UserID, Admin: admin}, coop, driverID); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) decide(admin bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r, "membershipId", ErrMembershipNotFound)
		if !ok {
			return
		}
		var body struct {
			Decision string `json:"decision"`
			Reason   string `json:"reason"`
		}
		if !httpx.DecodeJSON(w, r, &body) {
			return
		}
		if body.Decision != "approve" && body.Decision != "reject" {
			httpx.WriteError(w, http.StatusBadRequest, "invalid_decision", "indica approve o reject")
			return
		}
		p, _ := auth.FromContext(r.Context())
		err := h.Service.Decide(r.Context(), Decider{UserID: p.UserID, Admin: admin}, id, body.Decision == "approve", body.Reason)
		if err != nil {
			writeError(w, r, err)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func (h *Handlers) mine(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	out, err := h.Service.Mine(r.Context(), p.UserID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handlers) request(w http.ResponseWriter, r *http.Request) {
	var body struct {
		CooperativeID uuid.UUID `json:"cooperative_id"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	p, _ := auth.FromContext(r.Context())
	m, err := h.Service.RequestJoin(r.Context(), p.UserID, body.CooperativeID)
	if err != nil {
		writeError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, m)
}

func (h *Handlers) withdraw(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	if err := h.Service.Withdraw(r.Context(), p.UserID); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) leave(w http.ResponseWriter, r *http.Request) {
	p, _ := auth.FromContext(r.Context())
	if err := h.Service.Leave(r.Context(), p.UserID); err != nil {
		writeError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func writeError(w http.ResponseWriter, r *http.Request, err error) {
	var invalid InvalidError
	if errors.As(err, &invalid) {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_cooperative", invalid.Message)
		return
	}
	type mapping struct {
		status        int
		code, message string
	}
	known := []struct {
		err error
		m   mapping
	}{
		{ErrNotFound, mapping{http.StatusNotFound, "not_found", "cooperativa no encontrada"}},
		{ErrMembershipNotFound, mapping{http.StatusNotFound, "not_found", "solicitud o membresía no encontrada"}},
		{ErrDriverNotFound, mapping{http.StatusNotFound, "not_found", "conductor no encontrado"}},
		{ErrNotMember, mapping{http.StatusNotFound, "not_member", "ese conductor no es miembro de la cooperativa"}},
		{ErrNameTaken, mapping{http.StatusConflict, "cooperative_name_taken", "ya existe una cooperativa con ese nombre"}},
		{ErrAlreadyInCooperative, mapping{http.StatusConflict, "already_in_cooperative", "el conductor ya pertenece a una cooperativa o tiene una solicitud en curso"}},
		{ErrNotPending, mapping{http.StatusConflict, "not_pending", "esa solicitud ya fue decidida"}},
		{ErrReasonRequired, mapping{http.StatusBadRequest, "reason_required", "indica el motivo del rechazo"}},
		{ErrForbidden, mapping{http.StatusForbidden, "forbidden", "solo un coordinador de la cooperativa puede hacerlo"}},
	}
	for _, k := range known {
		if errors.Is(err, k.err) {
			httpx.WriteError(w, k.m.status, k.m.code, k.m.message)
			return
		}
	}
	httpx.InternalError(w, r, err)
}
