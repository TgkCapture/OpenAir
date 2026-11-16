/**
 * Dates and times in the station's timezone.
 *
 * The schedule is planned in station time, which may differ from the timezone
 * of the browser the admin is opened in. These helpers convert between a
 * wall-clock time at the station and a UTC instant.
 */

function partsIn(at: Date, timeZone: string): Record<string, string> {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", second: "2-digit",
  }).formatToParts(at);
  return Object.fromEntries(parts.map((p) => [p.type, p.value]));
}

/** How many minutes the station's clock is ahead of UTC at the given instant. */
function offsetMinutes(at: Date, timeZone: string): number {
  const p = partsIn(at, timeZone);
  const asUtc = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute, +p.second);
  return Math.round((asUtc - at.getTime()) / 60000);
}

/** The instant at which the station's clock shows `date` (YYYY-MM-DD) and `time` (HH:MM). */
export function stationToUtc(date: string, time: string, timeZone: string): Date {
  const wallClockAsUtc = new Date(`${date}T${time}:00Z`).getTime();
  const first = new Date(wallClockAsUtc - offsetMinutes(new Date(wallClockAsUtc), timeZone) * 60000);
  // The offset can differ at the corrected instant, around a daylight-saving change.
  return new Date(wallClockAsUtc - offsetMinutes(first, timeZone) * 60000);
}

/** The station's date (YYYY-MM-DD) at the given instant. */
export function stationDate(at: Date | string, timeZone: string): string {
  const p = partsIn(new Date(at), timeZone);
  return `${p.year}-${p.month}-${p.day}`;
}

/** The station's clock time (HH:MM, 24-hour) at the given instant. */
export function stationTime(at: Date | string, timeZone: string): string {
  const p = partsIn(new Date(at), timeZone);
  return `${p.hour}:${p.minute}`;
}

/** `date` (YYYY-MM-DD) moved by a number of days. */
export function addDays(date: string, days: number): string {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** A readable form of `date` (YYYY-MM-DD), for example "Sunday 15 November 2026". */
export function longDate(date: string): string {
  return new Intl.DateTimeFormat("en-GB", {
    timeZone: "UTC", weekday: "long", day: "numeric", month: "long", year: "numeric",
  }).format(new Date(`${date}T00:00:00Z`));
}
