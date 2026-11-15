package schedule

import "time"

// dayBounds returns the start and end of a schedule day in the station's
// timezone. dateStr is YYYY-MM-DD; when empty, it is today at the station.
// The day runs from local midnight to the next local midnight, so it is 23 or
// 25 hours long on a daylight-saving change.
func dayBounds(dateStr string, loc *time.Location, now time.Time) (start, end time.Time, err error) {
	var day time.Time
	if dateStr == "" {
		day = now.In(loc)
	} else if day, err = time.ParseInLocation("2006-01-02", dateStr, loc); err != nil {
		return time.Time{}, time.Time{}, err
	}

	start = time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, loc)
	end = start.AddDate(0, 0, 1)
	return start, end, nil
}
