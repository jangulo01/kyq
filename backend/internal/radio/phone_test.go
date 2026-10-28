package radio

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNormalizePhone(t *testing.T) {
	for raw, want := range map[string]string{
		"3001234567":         "+573001234567",
		"300 123 4567":       "+573001234567",
		"573001234567":       "+573001234567",
		"+57 (300) 123-4567": "+573001234567",
		"+14155550100":       "+14155550100",
	} {
		got, ok := NormalizePhone(raw)
		assert.True(t, ok, raw)
		assert.Equal(t, want, got, raw)
	}
	for _, raw := range []string{"", "123", "6011234567", "+57123", "abc", "+573001234567890"} {
		_, ok := NormalizePhone(raw)
		assert.False(t, ok, raw)
	}
}

func TestMaskPhone(t *testing.T) {
	assert.Equal(t, "+57 300 *** **67", MaskPhone("+573001234567"))
	assert.NotContains(t, MaskPhone("+14155550100"), "55501")
}
