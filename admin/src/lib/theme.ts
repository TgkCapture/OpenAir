export type Theme = "light" | "dark";

const STORAGE_KEY = "openair-theme";

/** The saved theme, or the system preference when nothing is saved. */
export function getTheme(): Theme {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved === "light" || saved === "dark") return saved;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

/** Applies a theme to the page and remembers it. */
export function setTheme(theme: Theme): void {
  localStorage.setItem(STORAGE_KEY, theme);
  applyTheme(theme);
}

export function applyTheme(theme: Theme): void {
  document.documentElement.classList.toggle("dark", theme === "dark");
}

/**
 * Applies the broadcaster's brand colour (a #RRGGBB value from Settings) to
 * the whole dashboard. Text on the brand colour is white or near-black,
 * whichever is easier to read. A missing or malformed colour is ignored.
 */
export function applyBrandColor(hex: string | null | undefined): void {
  const match = /^#?([0-9a-f]{6})$/i.exec(hex ?? "");
  if (!match) return;

  const value = parseInt(match[1], 16);
  const channels = [(value >> 16) & 255, (value >> 8) & 255, value & 255].map((c) => {
    const s = c / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  const luminance = 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];

  const root = document.documentElement.style;
  root.setProperty("--primary", `#${match[1]}`);
  root.setProperty("--on-primary", luminance > 0.4 ? "#111318" : "#FFFFFF");
}
