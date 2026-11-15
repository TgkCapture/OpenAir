package notifications

import "testing"

func TestShortToken(t *testing.T) {
	cases := map[string]string{
		"":                 "",
		"abc":              "abc",
		"12345678":         "12345678",
		"123456789abcdefg": "12345678...",
	}
	for token, want := range cases {
		if got := shortToken(token); got != want {
			t.Errorf("shortToken(%q) = %q, want %q", token, got, want)
		}
	}
}
