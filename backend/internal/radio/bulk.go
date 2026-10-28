package radio

import (
	"bytes"
	"context"
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// Bulk upload limits and pace (FR-033, research R9).
const (
	MaxBulkRows        = 2000
	bulkSMSInterval    = 50 * time.Millisecond // 20 SMS por segundo
	bulkSMSAttempts    = 2
	BulkStatusReady    = "validated"
	BulkStatusSending  = "sending"
	BulkStatusDone     = "done"
	maxBulkNameLetters = 60
)

// ErrBulkState: the upload is not in a state that allows that (ya se está enviando).
var ErrBulkState = errors.New("bulk upload state")

// BulkUpload is one CSV upload with its totals per row status (contracts: BulkUpload).
type BulkUpload struct {
	ID        uuid.UUID      `json:"id"`
	FileName  string         `json:"file_name"`
	Status    string         `json:"status"`
	RowsTotal int            `json:"rows_total"`
	Counts    map[string]int `json:"counts"`
	CreatedAt time.Time      `json:"created_at"`
}

// BulkRow is one row of an upload: never the full phone (FR-004).
type BulkRow struct {
	Line        int     `json:"line"`
	Name        string  `json:"name"`
	PhoneMasked string  `json:"phone_masked"`
	Kind        string  `json:"kind"`
	Channel     string  `json:"channel"`
	Role        *string `json:"role,omitempty"`
	Status      string  `json:"status"`
	Error       *string `json:"error"`
}

// BulkUploadDetail is BulkUpload with its rows.
type BulkUploadDetail struct {
	BulkUpload
	Rows []BulkRow `json:"rows"`
}

// bulkLine is a parsed CSV row before it is stored.
type bulkLine struct {
	line    int
	name    string
	phone   string // E.164; vacío si no es válido (la columna solo admite E.164)
	kind    store.UserRole
	channel string
	role    string
	err     string
}

// parseKind accepts the Spanish and English names of the two apps.
func parseKind(v string) (store.UserRole, bool) {
	switch strings.ToLower(strings.TrimSpace(v)) {
	case "", "conductor", "driver":
		return store.UserRoleDriver, true
	case "pasajero", "passenger", "cliente":
		return store.UserRolePassenger, true
	}
	return "", false
}

// parseRole accepts the channel roles as people write them in a sheet.
func parseRole(v string) (string, bool) {
	switch strings.ToLower(strings.TrimSpace(v)) {
	case "", "miembro", "member":
		return RoleMember, true
	case "dueño", "dueno", "owner":
		return RoleOwner, true
	case "moderador", "moderator":
		return RoleModerator, true
	case "oyente", "solo escucha", "listener", "escucha":
		return RoleListener, true
	}
	return "", false
}

// readBulkCSV reads `nombre,telefono,tipo,canal,rol` with or without header, separated by commas
// or semicolons (Excel en español), and validates each row without touching the database.
func readBulkCSV(data []byte) ([]bulkLine, error) {
	data = bytes.TrimPrefix(data, []byte("\xef\xbb\xbf"))
	first, _, _ := bytes.Cut(data, []byte("\n"))
	r := csv.NewReader(bytes.NewReader(data))
	if bytes.Count(first, []byte(";")) > bytes.Count(first, []byte(",")) {
		r.Comma = ';'
	}
	r.FieldsPerRecord = -1
	r.TrimLeadingSpace = true
	var out []bulkLine
	line := 0
	for {
		rec, err := r.Read()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return nil, ErrInvalid
		}
		line++
		if line == 1 && len(rec) > 1 && strings.Contains(strings.ToLower(rec[1]), "tel") {
			continue // encabezado
		}
		blank := true
		for _, f := range rec {
			blank = blank && strings.TrimSpace(f) == ""
		}
		if blank {
			continue
		}
		for len(rec) < 5 {
			rec = append(rec, "")
		}
		l := bulkLine{line: line, name: strings.TrimSpace(rec[0]), phone: strings.TrimSpace(rec[1]), channel: strings.TrimSpace(rec[3])}
		kind, okKind := parseKind(rec[2])
		role, okRole := parseRole(rec[4])
		l.kind, l.role = kind, role
		switch {
		case l.name == "" || utf8.RuneCountInString(l.name) > maxBulkNameLetters:
			l.err = "falta el nombre o es muy largo"
		case !okKind:
			l.err = "tipo inválido: usa conductor o pasajero"
		case !okRole:
			l.err = "rol inválido: usa dueño, moderador, miembro u oyente"
		case l.channel == "":
			l.err = "falta el canal"
		default:
			if _, ok := validName(l.channel); !ok {
				l.err = "el nombre del canal debe tener entre 3 y 40 letras"
			}
		}
		if p, ok := NormalizePhone(l.phone); ok {
			l.phone = p
		} else {
			l.phone = ""
			if l.err == "" {
				l.err = "teléfono inválido"
			}
		}
		if l.err == "" && l.kind == store.UserRolePassenger && (l.role == RoleOwner || l.role == RoleModerator) {
			l.err = "un pasajero no puede ser dueño ni moderador"
		}
		out = append(out, l)
		if len(out) > MaxBulkRows {
			return nil, ErrBulkTooLarge
		}
	}
	return out, nil
}

// ErrBulkTooLarge: more than MaxBulkRows rows.
var ErrBulkTooLarge = errors.New("bulk upload too large")

// UploadBulk validates a CSV and stores its rows without sending anything (FR-033): duplicated
// phones in a channel, channels that do not exist and have no owner in the list, owners that are
// not drivers of Kyq and passengers where the panel does not allow them are errors per row.
func (s *Service) UploadBulk(ctx context.Context, adminID uuid.UUID, fileName string, data []byte) (BulkUploadDetail, error) {
	lines, err := readBulkCSV(data)
	if err != nil {
		return BulkUploadDetail{}, err
	}
	if len(lines) == 0 {
		return BulkUploadDetail{}, ErrInvalid
	}
	st, err := s.settings(ctx)
	if err != nil {
		return BulkUploadDetail{}, err
	}
	fileName = strings.TrimSpace(fileName)
	if fileName == "" {
		fileName = "carga.csv"
	}
	// Por canal: si ya existe y quién sería su dueño.
	type channelInfo struct {
		exists bool
		owner  bool
	}
	channels := map[string]*channelInfo{}
	seen := map[string]int{}
	for i := range lines {
		l := &lines[i]
		if l.err != "" {
			continue
		}
		key := strings.ToLower(l.channel)
		if prev, ok := seen[key+"|"+l.phone]; ok && l.phone != "" {
			l.err = fmt.Sprintf("repetido: ya está en la línea %d", prev)
			continue
		}
		seen[key+"|"+l.phone] = l.line
		info := channels[key]
		if info == nil {
			_, err := s.Store.GetRadioActiveChannelByName(ctx, l.channel)
			switch {
			case err == nil:
				info = &channelInfo{exists: true}
			case store.IsNotFound(err):
				info = &channelInfo{}
			default:
				return BulkUploadDetail{}, err
			}
			channels[key] = info
		}
		if l.kind == store.UserRolePassenger && st.PassengersInChannels == PassengersNone {
			l.err = "el panel no admite pasajeros en canales"
			continue
		}
		if l.role == RoleOwner {
			switch u, err := s.Store.GetRadioUserByPhone(ctx, l.phone); {
			case info.exists:
				l.err = "el canal ya existe y tiene dueño"
			case info.owner:
				l.err = "el canal ya tiene un dueño en esta lista"
			case store.IsNotFound(err) || (err == nil && u.Role != store.UserRoleDriver):
				l.err = "el dueño debe usar ya Kyq Conductor"
			case err != nil:
				return BulkUploadDetail{}, err
			default:
				info.owner = true
			}
		}
	}
	for i := range lines {
		l := &lines[i]
		if l.err == "" {
			if info := channels[strings.ToLower(l.channel)]; info != nil && !info.exists && !info.owner {
				l.err = "el canal no existe: agrega una fila con su dueño (rol dueño)"
			}
		}
	}
	id, err := newID()
	if err != nil {
		return BulkUploadDetail{}, err
	}
	now := s.now()
	valid := 0
	for _, l := range lines {
		if l.err == "" {
			valid++
		}
	}
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		if _, err := q.InsertRadioBulkUpload(ctx, store.InsertRadioBulkUploadParams{
			ID: id, AdminID: adminID, FileName: fileName, RowsTotal: int32(len(lines)),
			RowsValid: int32(valid), RowsInvalid: int32(len(lines) - valid), CreatedAt: now,
		}); err != nil {
			return err
		}
		for _, l := range lines {
			code, err := newCode()
			if err != nil {
				return err
			}
			rowID, err := newID()
			if err != nil {
				return err
			}
			params := store.InsertRadioInviteParams{
				ID: rowID, Code: code, InviteeKind: l.kind, Status: store.RadioInviteStatusPending,
				CreatedAt: now, ExpiresAt: now.Add(InviteTTL), BulkID: nullID(id),
				Line: pgtype.Int4{Int32: int32(l.line), Valid: true}, InviteeName: text(l.name), ChannelName: text(l.channel),
			}
			if l.phone != "" {
				params.PhoneE164 = text(l.phone)
			}
			if l.kind == "" {
				params.InviteeKind = store.UserRoleDriver
			}
			if l.role != "" {
				params.Role = store.NullRadioRole{RadioRole: store.RadioRole(l.role), Valid: true}
			}
			if l.err != "" {
				params.Status, params.Error = store.RadioInviteStatusFailed, text(l.err)
			}
			if _, err := q.InsertRadioInvite(ctx, params); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return BulkUploadDetail{}, err
	}
	return s.BulkDetail(ctx, id)
}

func (s *Service) bulkView(ctx context.Context, b store.RadioBulkUpload) (BulkUpload, error) {
	counts, err := s.Store.CountRadioBulkRows(ctx, store.CountRadioBulkRowsParams{Now: s.now(), BulkID: nullID(b.ID)})
	if err != nil {
		return BulkUpload{}, err
	}
	out := BulkUpload{ID: b.ID, FileName: b.FileName, Status: b.Status, RowsTotal: int(b.RowsTotal), Counts: map[string]int{}, CreatedAt: b.CreatedAt}
	for _, c := range counts {
		out.Counts[c.Status] = int(c.N)
	}
	return out, nil
}

// BulkUploads lists the uploads, newest first, with their totals (FR-034).
func (s *Service) BulkUploads(ctx context.Context) ([]BulkUpload, error) {
	rows, err := s.Store.ListRadioBulkUploads(ctx)
	if err != nil {
		return nil, err
	}
	out := make([]BulkUpload, 0, len(rows))
	for _, b := range rows {
		v, err := s.bulkView(ctx, b)
		if err != nil {
			return nil, err
		}
		out = append(out, v)
	}
	return out, nil
}

// BulkDetail is one upload with the state of each row.
func (s *Service) BulkDetail(ctx context.Context, id uuid.UUID) (BulkUploadDetail, error) {
	b, err := s.Store.GetRadioBulkUpload(ctx, id)
	if store.IsNotFound(err) {
		return BulkUploadDetail{}, ErrNotFound
	}
	if err != nil {
		return BulkUploadDetail{}, err
	}
	view, err := s.bulkView(ctx, b)
	if err != nil {
		return BulkUploadDetail{}, err
	}
	rows, err := s.Store.ListRadioBulkRows(ctx, nullID(id))
	if err != nil {
		return BulkUploadDetail{}, err
	}
	now := s.now()
	out := BulkUploadDetail{BulkUpload: view, Rows: make([]BulkRow, 0, len(rows))}
	for _, r := range rows {
		row := BulkRow{
			Line: int(r.Line.Int32), Name: r.InviteeName.String, PhoneMasked: MaskPhone(r.PhoneE164.String),
			Kind: string(r.InviteeKind), Channel: r.ChannelName.String, Status: string(r.Status),
		}
		if (r.Status == store.RadioInviteStatusPending || r.Status == store.RadioInviteStatusSent) && !r.ExpiresAt.After(now) {
			row.Status = string(store.RadioInviteStatusExpired)
		}
		if r.Role.Valid {
			v := string(r.Role.RadioRole)
			row.Role = &v
		}
		if r.Error.Valid {
			v := r.Error.String
			row.Error = &v
		}
		out.Rows = append(out.Rows, row)
	}
	return out, nil
}

// SendBulk confirms an upload: creates the channels that are missing with their owner and sends
// one SMS per valid row in the background (FR-033). onlyFailed resends the rows whose SMS
// failed; nobody who already accepted gets another one (FR-034).
func (s *Service) SendBulk(ctx context.Context, id uuid.UUID, onlyFailed bool) error {
	from := []string{BulkStatusReady}
	if onlyFailed {
		from = []string{BulkStatusDone}
	}
	n, err := s.Store.SetRadioBulkUploadStatus(ctx, store.SetRadioBulkUploadStatusParams{
		Status: BulkStatusSending, ConfirmedAt: ts(s.now()), ID: id, FromStatuses: from,
	})
	if err != nil {
		return err
	}
	if n == 0 {
		if _, err := s.Store.GetRadioBulkUpload(ctx, id); store.IsNotFound(err) {
			return ErrNotFound
		}
		return ErrBulkState
	}
	s.background(ctx, func(ctx context.Context) {
		if err := s.sendBulk(ctx, id, onlyFailed); err != nil {
			s.logger().ErrorContext(ctx, "radio bulk send", "bulk_id", id, "err", err)
		}
		if _, err := s.Store.SetRadioBulkUploadStatus(ctx, store.SetRadioBulkUploadStatusParams{
			Status: BulkStatusDone, ID: id, FromStatuses: []string{BulkStatusSending},
		}); err != nil {
			s.logger().ErrorContext(ctx, "radio bulk done", "bulk_id", id, "err", err)
		}
	})
	return nil
}

func (s *Service) sendBulk(ctx context.Context, id uuid.UUID, onlyFailed bool) error {
	rows, err := s.Store.ListRadioBulkRows(ctx, nullID(id))
	if err != nil {
		return err
	}
	// Primero los canales que faltan, con el dueño de la lista (FR-033).
	channelOf := map[string]uuid.UUID{}
	for _, r := range rows {
		if r.Role.RadioRole != store.RadioRoleOwner || r.Error.Valid && !onlyFailed {
			continue
		}
		if r.Status != store.RadioInviteStatusPending && r.Status != store.RadioInviteStatusFailed {
			continue
		}
		if _, err := s.Store.GetRadioActiveChannelByName(ctx, r.ChannelName.String); err == nil {
			continue
		}
		owner, err := s.Store.GetRadioUserByPhone(ctx, r.PhoneE164.String)
		if err != nil || owner.Role != store.UserRoleDriver {
			continue
		}
		passengers := s.bulkPassengerMax(rows, r.ChannelName.String)
		conv, err := s.createChannel(ctx, owner.ID, r.ChannelName.String, nil, JoinApproval, passengers)
		if err != nil {
			s.setBulkRow(ctx, r.ID, store.RadioInviteStatusFailed, "no se pudo crear el canal")
			continue
		}
		channelOf[strings.ToLower(r.ChannelName.String)] = conv.ID
		s.setBulkRow(ctx, r.ID, store.RadioInviteStatusAlreadyMember, "")
	}
	interval := s.BulkSMSInterval
	if interval == 0 {
		interval = bulkSMSInterval
	}
	tick := time.NewTicker(interval)
	defer tick.Stop()
	now := s.now()
	for _, r := range rows {
		switch {
		case !r.ExpiresAt.After(now):
			continue
		case onlyFailed && r.Status != store.RadioInviteStatusFailed:
			continue
		case !onlyFailed && r.Status != store.RadioInviteStatusPending:
			continue
		case onlyFailed && !s.bulkResendable(r):
			// Error de validación: reenviar no lo arregla.
			continue
		}
		conv, ok := channelOf[strings.ToLower(r.ChannelName.String)]
		if !ok {
			c, err := s.Store.GetRadioActiveChannelByName(ctx, r.ChannelName.String)
			if err != nil {
				s.setBulkRow(ctx, r.ID, store.RadioInviteStatusFailed, "el canal no existe")
				continue
			}
			conv = c.ID
			channelOf[strings.ToLower(r.ChannelName.String)] = conv
		}
		owner, _ := s.Store.GetRadioChannelOwner(ctx, conv)
		inviter := uuid.NullUUID{}
		if owner.ID != uuid.Nil {
			inviter = nullID(owner.ID)
		}
		if err := s.Store.SetRadioBulkInviteChannel(ctx, store.SetRadioBulkInviteChannelParams{
			ID: r.ID, ConversationID: nullID(conv), InviterID: inviter,
		}); err != nil {
			return err
		}
		if u, err := s.Store.GetRadioUserByPhone(ctx, r.PhoneE164.String); err == nil {
			if m, err := s.Store.GetRadioMember(ctx, store.GetRadioMemberParams{ConversationID: conv, UserID: u.ID}); err == nil &&
				(m.Status == store.RadioMemberStatusActive || m.Status == store.RadioMemberStatusMuted) {
				s.setBulkRow(ctx, r.ID, store.RadioInviteStatusAlreadyMember, "")
				continue
			}
		}
		if out, err := s.Store.IsRadioOptedOut(ctx, r.PhoneE164.String); err == nil && out {
			s.setBulkRow(ctx, r.ID, store.RadioInviteStatusFailed, "no quiere invitaciones")
			continue
		}
		inviterName := "Kyq"
		if owner.DisplayName != "" {
			inviterName = owner.DisplayName
		}
		body := inviterName + " te invita al canal " + r.ChannelName.String + " de Radio Kyq: " + s.InviteURL(r.Code) +
			" (vence en 14 días). Para no recibir más invitaciones abre " + s.InviteURL(r.Code) + "/baja"
		if s.SMS == nil {
			s.setBulkRow(ctx, r.ID, store.RadioInviteStatusFailed, "no se pudo enviar el SMS")
			continue
		}
		var sendErr error
		for range bulkSMSAttempts {
			<-tick.C
			if sendErr = s.SMS.SendSMS(ctx, r.PhoneE164.String, body); sendErr == nil {
				break
			}
		}
		if sendErr != nil {
			s.logger().WarnContext(ctx, "send radio bulk sms", "invite_id", r.ID, "err", sendErr)
			s.setBulkRow(ctx, r.ID, store.RadioInviteStatusFailed, "no se pudo enviar el SMS")
			continue
		}
		if err := s.Store.SetRadioInviteStatus(ctx, store.SetRadioInviteStatusParams{
			ID: r.ID, Status: store.RadioInviteStatusSent, SentAt: ts(s.now()),
		}); err != nil {
			return err
		}
	}
	return nil
}

// bulkResendable: only SMS failures are retried, never validation errors.
func (s *Service) bulkResendable(r store.RadioInvite) bool {
	return r.Error.String == "no se pudo enviar el SMS"
}

// bulkPassengerMax is the highest role of the passengers listed for a new channel (FR-017).
func (s *Service) bulkPassengerMax(rows []store.RadioInvite, channel string) *string {
	var best *string
	for _, r := range rows {
		if r.InviteeKind != store.UserRolePassenger || r.Error.Valid || !strings.EqualFold(r.ChannelName.String, channel) {
			continue
		}
		role := string(r.Role.RadioRole)
		if best == nil || roleRank(role) < roleRank(*best) {
			best = &role
		}
	}
	return best
}

func (s *Service) setBulkRow(ctx context.Context, id uuid.UUID, status store.RadioInviteStatus, msg string) {
	params := store.SetRadioInviteStatusParams{ID: id, Status: status}
	if msg != "" {
		params.Error = text(msg)
	}
	if err := s.Store.SetRadioInviteStatus(ctx, params); err != nil {
		s.logger().WarnContext(ctx, "save radio bulk row", "invite_id", id, "err", err)
	}
}
