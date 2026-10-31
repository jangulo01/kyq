package radio

import (
	"errors"
	"html/template"
	"net/http"
	"net/url"
)

// La página del enlace de invitación (R9): abre `kyq://radio/{code}` en la app y, si no está
// instalada, ofrece la tienda de la app correcta con el código en el Install Referrer para que la
// invitación se aplique sola tras el registro. Sin datos personales: solo quién invita y a qué.
var pageTmpl = template.Must(template.New("invite").Parse(`<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Radio Kyq</title>
<style>
body{margin:0;font-family:system-ui,sans-serif;background:#0f3d3e;color:#fff;display:flex;min-height:100vh;align-items:center;justify-content:center}
main{max-width:420px;padding:32px 24px;text-align:center}
h1{font-size:1.4rem;margin:0 0 12px} p{line-height:1.5;opacity:.9}
a.btn{display:block;margin:16px 0;padding:16px;border-radius:999px;background:#f2b134;color:#0f3d3e;font-weight:700;text-decoration:none}
a.alt{color:#fff}
</style></head><body><main>
{{if .Valid}}
<h1>{{.Inviter}} te invita a {{if .Channel}}«{{.Channel}}» en {{end}}Radio Kyq</h1>
<p>Habla por radio con {{if .Channel}}el canal{{else}}tu compañero{{end}} desde Kyq {{.App}}.</p>
<a class="btn" href="{{.Deep}}">Abrir en Kyq {{.App}}</a>
<a class="alt" href="{{.Store}}">¿No tienes la app? Instálala aquí</a>
<script>setTimeout(function(){location.href={{.Deep}}},300)</script>
{{else}}
<h1>Esta invitación ya no es válida</h1>
<p>Venció o ya se usó. Pide a quien te invitó un enlace nuevo.</p>
{{end}}
</main></body></html>`))

var optOutTmpl = template.Must(template.New("baja").Parse(`<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Radio Kyq</title>
<style>body{font-family:system-ui,sans-serif;max-width:420px;margin:40px auto;padding:0 24px;line-height:1.5}
button{padding:14px 20px;border-radius:999px;border:0;background:#0f3d3e;color:#fff;font-weight:700}</style>
</head><body>
{{if .Done}}<h1>Listo</h1><p>No te enviaremos más invitaciones de Radio Kyq a este número.</p>
{{else}}<h1>¿Dejar de recibir invitaciones?</h1>
<p>No te enviaremos más SMS de invitación a Radio Kyq a este número.</p>
<form method="post"><button type="submit">Sí, no quiero más invitaciones</button></form>{{end}}
</body></html>`))

func (h *Handlers) page(w http.ResponseWriter, r *http.Request) {
	code := r.PathValue("code")
	data := map[string]any{"Valid": false}
	inv, err := h.Service.Preview(r.Context(), code)
	switch {
	case err == nil:
		app, store := "Conductor", h.Service.PlayDriverURL
		if inv.InviteeKind == RolePassenger {
			app, store = "Pasajero", h.Service.PlayRiderURL
		}
		data = map[string]any{
			"Valid": true, "Inviter": inv.InviterName, "App": app,
			"Deep":  template.URL("kyq://radio/" + url.PathEscape(code)),
			"Store": template.URL(withReferrer(store, code)),
		}
		if inv.ChannelName != nil {
			data["Channel"] = *inv.ChannelName
		}
	case !errors.Is(err, ErrNotFound) && !errors.Is(err, ErrInviteExpired):
		http.Error(w, "error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	_ = pageTmpl.Execute(w, data)
}

// withReferrer adds the invitation to the Play Store link (Install Referrer, R9).
func withReferrer(storeURL, code string) string {
	u, err := url.Parse(storeURL)
	if err != nil || storeURL == "" {
		return storeURL
	}
	q := u.Query()
	q.Set("referrer", "radio="+code)
	u.RawQuery = q.Encode()
	return u.String()
}

func (h *Handlers) optOutPage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_ = optOutTmpl.Execute(w, map[string]any{"Done": false})
}

func (h *Handlers) optOut(w http.ResponseWriter, r *http.Request) {
	err := h.Service.OptOut(r.Context(), r.PathValue("code"))
	if err != nil && !errors.Is(err, ErrNotFound) && !errors.Is(err, ErrInvalid) {
		http.Error(w, "error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_ = optOutTmpl.Execute(w, map[string]any{"Done": true})
}
