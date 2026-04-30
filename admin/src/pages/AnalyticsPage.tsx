import { useQuery } from "@tanstack/react-query";
import { Users, Tv, Film, Radio, Eye, TrendingUp, RefreshCw } from "lucide-react";
import api from "../lib/api";

export default function AnalyticsPage() {
  const { data: stats, isLoading, refetch } = useQuery({
    queryKey: ["analytics"],
    queryFn: async () => (await api.get("/admin/analytics")).data.data,
    refetchInterval: 60_000,
  });

  const cards = [
    { label: "Total Users",    value: stats?.total_users,    icon: Users,  color: "#3B82F6", bg: "rgba(59,130,246,0.1)" },
    { label: "Active Channels",value: stats?.total_channels, icon: Tv,     color: "#10B981", bg: "rgba(16,185,129,0.1)" },
    { label: "VOD Videos",     value: stats?.total_vod,      icon: Film,   color: "#8B5CF6", bg: "rgba(139,92,246,0.1)" },
    { label: "Podcasts",       value: stats?.total_podcasts, icon: Radio,  color: "#F59E0B", bg: "rgba(245,158,11,0.1)" },
    { label: "Total Views",    value: stats?.total_views,    icon: Eye,    color: "#E63946", bg: "rgba(230,57,70,0.1)"  },
  ];

  return (
    <div style={{ padding: "32px" }}>
      <div className="page-header">
        <h1 className="page-title">Analytics</h1>
        <button className="btn-ghost" onClick={() => refetch()} style={{ gap: 6 }}>
          <RefreshCw size={13} /> Refresh
        </button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))", gap: 12, marginBottom: 32 }}>
        {cards.map(({ label, value, icon: Icon, color, bg }) => (
          <div key={label} className="stat-card">
            <div className="stat-icon" style={{ background: bg }}>
              <Icon size={16} style={{ color }} />
            </div>
            {isLoading ? (
              <div style={{ height: 32, width: 64, background: "var(--border)", borderRadius: 6, marginBottom: 4 }} />
            ) : (
              <div className="stat-value">{typeof value === "number" ? value.toLocaleString() : "—"}</div>
            )}
            <div className="stat-label">{label}</div>
          </div>
        ))}
      </div>

      {stats?.top_content?.length > 0 && (
        <div className="card" style={{ padding: 24 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
            <TrendingUp size={16} style={{ color: "var(--primary)" }} />
            <h2 style={{ fontSize: 14, fontWeight: 700, margin: 0 }}>Top Content by Views</h2>
          </div>
          {stats.top_content.map((item: { title: string; view_count: number }, i: number) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 0", borderBottom: i < stats.top_content.length - 1 ? "1px solid var(--border)" : "none" }}>
              <span style={{ width: 22, height: 22, borderRadius: 5, background: i === 0 ? "var(--primary-soft)" : "var(--bg)", color: i === 0 ? "var(--primary)" : "var(--text-3)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 700, flexShrink: 0 }}>
                {i + 1}
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", marginBottom: 4 }}>
                  {item.title}
                </div>
                <div style={{ height: 4, background: "var(--border)", borderRadius: 2 }}>
                  <div style={{ height: "100%", background: "var(--primary)", borderRadius: 2, width: `${Math.min(100, (item.view_count / (stats.top_content[0]?.view_count || 1)) * 100)}%` }} />
                </div>
              </div>
              <span style={{ fontSize: 12, color: "var(--text-3)", flexShrink: 0 }}>
                {item.view_count.toLocaleString()}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}