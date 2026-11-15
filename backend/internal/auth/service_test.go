package auth

import "testing"

func TestHashRefreshToken(t *testing.T) {
	a := hashRefreshToken("token-one")
	b := hashRefreshToken("token-two")

	if len(a) != 64 {
		t.Fatalf("expected a 64-character hex SHA-256, got %d characters", len(a))
	}
	if a != hashRefreshToken("token-one") {
		t.Fatal("hashing the same token twice must give the same value")
	}
	if a == b {
		t.Fatal("different tokens must not share a hash")
	}
	if a == "token-one" {
		t.Fatal("the stored value must not be the raw token")
	}
}
