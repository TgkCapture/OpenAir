package schedule

import (
	"testing"
	"time"
	_ "time/tzdata"
)

func mustLoad(t *testing.T, name string) *time.Location {
	t.Helper()
	loc, err := time.LoadLocation(name)
	if err != nil {
		t.Fatalf("load %s: %v", name, err)
	}
	return loc
}

func TestDayBoundsUsesStationTimezone(t *testing.T) {
	blantyre := mustLoad(t, "Africa/Blantyre") // UTC+2, no daylight saving

	start, end, err := dayBounds("2026-11-15", blantyre, time.Time{})
	if err != nil {
		t.Fatalf("dayBounds: %v", err)
	}

	wantStart := time.Date(2026, 11, 14, 22, 0, 0, 0, time.UTC)
	wantEnd := time.Date(2026, 11, 15, 22, 0, 0, 0, time.UTC)
	if !start.Equal(wantStart) || !end.Equal(wantEnd) {
		t.Fatalf("got %s to %s, want %s to %s", start.UTC(), end.UTC(), wantStart, wantEnd)
	}

	// A programme at 00:30 station time belongs to that day, although it is
	// still the previous day in UTC.
	justAfterMidnight := time.Date(2026, 11, 15, 0, 30, 0, 0, blantyre)
	if justAfterMidnight.Before(start) || !justAfterMidnight.Before(end) {
		t.Fatalf("00:30 local should fall inside the day")
	}

	// A programme at 23:30 the evening before does not.
	previousEvening := time.Date(2026, 11, 14, 23, 30, 0, 0, blantyre)
	if !previousEvening.Before(start) {
		t.Fatalf("23:30 the previous evening should fall outside the day")
	}
}

func TestDayBoundsDefaultsToTodayAtTheStation(t *testing.T) {
	blantyre := mustLoad(t, "Africa/Blantyre")

	// 23:00 UTC on the 14th is already 01:00 on the 15th in Blantyre.
	now := time.Date(2026, 11, 14, 23, 0, 0, 0, time.UTC)
	start, _, err := dayBounds("", blantyre, now)
	if err != nil {
		t.Fatalf("dayBounds: %v", err)
	}
	if got := start.Format("2006-01-02"); got != "2026-11-15" {
		t.Fatalf("got %s, want 2026-11-15", got)
	}
}

func TestDayBoundsHandlesDaylightSaving(t *testing.T) {
	london := mustLoad(t, "Europe/London")

	// Clocks go forward on 29 March 2026, so that day is 23 hours long.
	start, end, err := dayBounds("2026-03-29", london, time.Time{})
	if err != nil {
		t.Fatalf("dayBounds: %v", err)
	}
	if got := end.Sub(start); got != 23*time.Hour {
		t.Fatalf("got a %s day, want 23h", got)
	}
}

func TestDayBoundsRejectsBadDate(t *testing.T) {
	if _, _, err := dayBounds("15/11/2026", time.UTC, time.Time{}); err == nil {
		t.Fatal("expected an error for a malformed date")
	}
}
