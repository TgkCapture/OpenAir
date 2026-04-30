import { useQuery } from "@tanstack/react-query";
import { Users, Tv, Film, Radio, Eye } from "lucide-react";
import { Link } from "react-router-dom";
import api from "../lib/api";

export default function DashboardPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ["analytics"],
    queryFn: async () => (await api.get("/admin/analytics")).data.data,
    refetchInterval: 60_000,
  });

  const cards = [
    { label: "Total Users",    value: stats?.total_users,    icon: Users,  to: "/users",     color: "#3B82F6", bg: "rgba(59,130,246,0.1)" },
    { label: "Channels",       value: stats?.total_channels, icon: Tv,     to: "/channels",  color: "#10B981", bg: "rgba(16,185,129,0.1)" },
    { label: "Videos",         value: stats?.total_vod,      icon: Film,   to: "/vod",       color: "#8B5CF6", bg: "rgba(139,92,246,0.1)" },
    { label: "Podcasts",       value: stats?.total_podcasts, icon: Radio,  to: "/podcasts",  color: "#F59E0B", bg: "rgba(245,158,11,0.1)" },
    { label: "Total Views",    value: stats?.total_views,    icon: Eye,    to: "/analytics", color: "#E63946", bg: "rgba(230,57,70,0.1)"  },
  ];

  return (
    <div style={{ padding: "32px 32px 48px" }}>

      {/* Header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p style={{ margin: "4px 0 0", fontSize: 13, color: "var(--text-3)" }}>
            Welcome to OpenAir Admin
          </p>
        </div>
      </div>

      {/* Stats grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))", gap: 12, marginBottom: 32 }}>
        {cards.map(({ label, value, icon: Icon, to, color, bg }) => (
          <Link key={label} to={to} style={{ textDecoration: "none" }}>
            <div className="stat-card">
              <div className="stat-icon" style={{ background: bg }}>
                <Icon size={16} style={{ color }} />
              </div>
              {isLoading ? (
                <div style={{ height: 32, width: 60, background: "var(--border)", borderRadius: 6, marginBottom: 4 }} />
              ) : (
                <div className="stat-value">
                  {typeof value === "number" ? value.toLocaleString() : "—"}
                </div>
              )}
              <div className="stat-label">{label}</div>
            </div>
          </Link>
        ))}
      </div>

      {/* Top content */}
      {stats?.top_content?.length > 0 && (
        <div className="card" style={{ padding: 24 }}>
          <h2 style={{ fontSize: 14, fontWeight: 700, margin: "0 0 20px", color: "var(--text)" }}>
            Top Content by Views
          </h2>
          <div>
            {stats.top_content.map((item: { title: string; view_count: number }, i: number) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", gap: 12,
                padding: "10px 0",
                borderBottom: i < stats.top_content.length - 1 ? "1px solid var(--border)" : "none",
              }}>
                <span style={{
                  width: 24, height: 24, borderRadius: 6,
                  background: i === 0 ? "var(--primary-soft)" : "var(--bg)",
                  color: i === 0 ? "var(--primary)" : "var(--text-3)",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 11, fontWeight: 700, flexShrink: 0,
                }}>
                  {i + 1}
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {item.title}
                  </div>
                  <div style={{ marginTop: 4, height: 3, background: "var(--border)", borderRadius: 2 }}>
                    <div style={{
                      height: "100%",
                      background: "var(--primary)",
                      borderRadius: 2,
                      width: `${Math.min(100, (item.view_count / (stats.top_content[0]?.view_count || 1)) * 100)}%`,
                    }} />
                  </div>
                </div>
                <span style={{ fontSize: 12, color: "var(--text-3)", flexShrink: 0 }}>
                  {item.view_count.toLocaleString()} views
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}