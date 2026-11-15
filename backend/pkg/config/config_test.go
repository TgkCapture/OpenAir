package config

import (
	"reflect"
	"testing"
)

func TestCORSOrigins(t *testing.T) {
	cases := []struct {
		value, env string
		want       []string
	}{
		{"", "development", []string{"*"}},
		{"", "production", nil},
		{"https://admin.example.com/, http://localhost:5173", "production",
			[]string{"https://admin.example.com", "http://localhost:5173"}},
		{"https://admin.example.com", "development", []string{"https://admin.example.com"}},
	}
	for _, c := range cases {
		if got := corsOrigins(c.value, c.env); !reflect.DeepEqual(got, c.want) {
			t.Errorf("corsOrigins(%q, %q) = %v, want %v", c.value, c.env, got, c.want)
		}
	}
}
