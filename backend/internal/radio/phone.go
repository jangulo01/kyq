package radio

import (
	"regexp"
	"strings"
)

var (
	e164           = regexp.MustCompile(`^\+[1-9][0-9]{6,14}$`)
	colombianLocal = regexp.MustCompile(`^3[0-9]{9}$`)
	nonDigits      = regexp.MustCompile(`[\s().-]`)
)

// NormalizePhone returns a phone in E.164. Colombian mobiles may come as 3001234567,
// 573001234567 or +57 300 123 4567 (research R9); other countries need the + prefix.
func NormalizePhone(raw string) (string, bool) {
	p := nonDigits.ReplaceAllString(strings.TrimSpace(raw), "")
	switch {
	case colombianLocal.MatchString(p):
		p = "+57" + p
	case strings.HasPrefix(p, "57") && colombianLocal.MatchString(p[2:]):
		p = "+" + p
	case strings.HasPrefix(p, "+57") && !colombianLocal.MatchString(p[3:]):
		return "", false
	}
	if !e164.MatchString(p) {
		return "", false
	}
	return p, true
}

// MaskPhone shows only the country, the operator prefix and the last two digits, as the panel
// lists bulk rows: +57 300 *** **12.
func MaskPhone(p string) string {
	if strings.HasPrefix(p, "+57") && len(p) == 13 {
		return "+57 " + p[3:6] + " *** **" + p[11:]
	}
	if len(p) < 4 {
		return "***"
	}
	return p[:3] + " *** **" + p[len(p)-2:]
}
