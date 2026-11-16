import { Users, Tv, Film, Mic, Eye, BarChart2 } from "lucide-react";
import { Link } from "react-router-dom";

export interface Stats {
  total_users?: number;
  total_channels?: number;
  total_vod?: number;
  total_podcasts?: number;
  total_views?: number;
  top_content?: { title: string; view_count: number }[];
}

const CARDS = [
  { key: "total_users",    label: "Users",    icon: Users, to: "/users" },
  { key: "total_channels", label: "Channels", icon: Tv,    to: "/channels" },
  { key: "total_vod",      label: "Videos",   icon: Film,  to: "/vod" },
  { key: "total_podcasts", label: "Podcasts", icon: Mic,   to: "/podcasts" },
  { key: "total_views",    label: "Views",    icon: Eye,   to: "/analytics" },
] as const;

interface Props {
  stats?: Stats;
  loading: boolean;
  /** Make each number a link to its page. */
  linked?: boolean;
}

/** The headline numbers and the most-watched content. */
export default function StatsOverview({ stats, loading, linked = false }: Props) {
  // Items nobody has watched are not "most watched".
  const top = (stats?.top_content ?? []).filter((item) => item.view_count > 0);
  const mostViews = top[0]?.view_count || 1;

  return (
    <>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(170px, 1fr))", gap: 12, marginBottom: 24 }}>
        {CARDS.map(({ key, label, icon: Icon, to }) => {
          const value = stats?.[key];
          const card = (
            <div className="stat-card">
              <div className="stat-icon" style={{ background: "var(--bg-surface)" }}>
                <Icon size={17} aria-hidden="true" style={{ color: "var(--text-2)" }} />
              </div>
              {loading ? (
                <div style={{ height: 28, width: 64, background: "var(--bg-surface)", borderRadius: 6, marginBottom: 4 }} />
              ) : (
                <div className="stat-value">{typeof value === "number" ? value.toLocaleString() : "—"}</div>
              )}
              <div className="stat-label">{label}</div>
            </div>
          );
          return linked
            ? <Link key={key} to={to} style={{ textDecoration: "none", color: "inherit", borderRadius: "var(--radius)" }}>{card}</Link>
            : <div key={key}>{card}</div>;
        })}
      </div>

      <div className="card" style={{ padding: 24 }}>
        <h2 style={{ fontSize: 16, fontWeight: 700, margin: "0 0 16px" }}>Most watched</h2>
        {loading ? (
          <div style={{ height: 120, background: "var(--bg-surface)", borderRadius: "var(--radius-sm)" }} />
        ) : top.length === 0 ? (
          <div className="empty-state" style={{ padding: "32px 16px" }}>
            <BarChart2 size={36} aria-hidden="true" />
            <p>Nothing has been watched yet.</p>
          </div>
        ) : (
          <ol style={{ listStyle: "none", margin: 0, padding: 0 }}>
            {top.map((item, i) => (
              <li key={i} style={{
                display: "flex", alignItems: "center", gap: 12, padding: "10px 0",
                borderBottom: i < top.length - 1 ? "1px solid var(--border)" : "none",
              }}>
                <span style={{ width: 24, color: "var(--text-3)", fontWeight: 600, flexShrink: 0, fontVariantNumeric: "tabular-nums" }}>
                  {i + 1}
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", marginBottom: 6 }}>
                    {item.title}
                  </div>
                  <div style={{ height: 4, background: "var(--bg-surface)", borderRadius: 2 }}>
                    <div style={{
                      height: "100%", background: "var(--primary)", borderRadius: 2,
                      width: `${Math.min(100, (item.view_count / mostViews) * 100)}%`,
                    }} />
                  </div>
                </div>
                <span style={{ fontSize: 13, color: "var(--text-2)", flexShrink: 0, fontVariantNumeric: "tabular-nums" }}>
                  {item.view_count.toLocaleString()} views
                </span>
              </li>
            ))}
          </ol>
        )}
      </div>
    </>
  );
}
