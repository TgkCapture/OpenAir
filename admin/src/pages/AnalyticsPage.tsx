import { useQuery } from "@tanstack/react-query";
import { Users, Tv, Film, TrendingUp, Eye, Radio } from "lucide-react";
import api from "../lib/api";

interface Stats {
  total_users: number;
  total_channels: number;
  total_vod: number;
  total_podcasts: number;
  total_views: number;
  top_content: Array<{ title: string; view_count: number }>;
}

export default function AnalyticsPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ["analytics"],
    queryFn: async () => {
      const res = await api.get("/admin/analytics");
      return res.data.data as Stats;
    },
    refetchInterval: 60_000,
  });

  if (isLoading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", padding: "48px 0" }}>
        <div style={{
          width: 32, height: 32, border: "2px solid var(--primary)",
          borderTopColor: "transparent", borderRadius: "50%",
          animation: "spin 0.8s linear infinite",
        }} />
      </div>
    );
  }

  const cards = [
    { label: "Total Users", value: stats?.total_users ?? 0, icon: Users, color: "#3B82F6" },
    { label: "TV & Radio Channels", value: stats?.total_channels ?? 0, icon: Tv, color: "#10B981" },
    { label: "VOD Videos", value: stats?.total_vod ?? 0, icon: Film, color: "#8B5CF6" },
    { label: "Podcasts", value: stats?.total_podcasts ?? 0, icon: Radio, color: "#F59E0B" },
    { label: "Total Views", value: stats?.total_views ?? 0, icon: Eye, color: "var(--primary)" },
  ];

  return (
    <div style={{ padding: "32px 32px 48px" }}>
      {/* Header */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24 }}>
        <div>
          <h1 className="page-title" style={{ marginBottom: 4 }}>Analytics</h1>
          <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>Platform metrics and insights</p>
        </div>
        <span style={{ fontSize: 11, color: "var(--text-3)" }}>Refreshes every 60s</span>
      </div>

      {/* Stats grid */}
      <div style={{
        display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))",
        gap: 16, marginBottom: 32,
      }}>
        {cards.map(({ label, value, icon: Icon, color }) => (
          <div
            key={label}
            style={{
              background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
              padding: 16, border: "1px solid var(--border)",
            }}
          >
            <Icon size={20} style={{ color, marginBottom: 12 }} />
            <div style={{ fontSize: 28, fontWeight: 700, color: "var(--text)" }}>
              {value.toLocaleString()}
            </div>
            <div style={{ fontSize: 12, color: "var(--text-3)", marginTop: 4 }}>
              {label}
            </div>
          </div>
        ))}
      </div>

      {/* Top content */}
      {stats?.top_content && stats.top_content.length > 0 && (
        <div style={{
          background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
          border: "1px solid var(--border)", padding: 24,
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
            <TrendingUp size={18} style={{ color: "var(--primary)" }} />
            <h2 style={{ fontSize: 14, fontWeight: 700, margin: 0, color: "var(--text)" }}>
              Top Content by Views
            </h2>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {stats.top_content.map((item, i) => (
              <div key={i}>
                <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 8 }}>
                  <span style={{
                    width: 24, fontSize: 11, fontWeight: 700, color: "var(--text-3)",
                  }}>
                    {i + 1}
                  </span>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
                      <span style={{ fontSize: 13, fontWeight: 500, color: "var(--text)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                        {item.title}
                      </span>
                      <span style={{ fontSize: 11, color: "var(--text-3)", marginLeft: 12 }}>
                        {item.view_count} views
                      </span>
                    </div>
                    <div style={{ height: 4, background: "var(--border)", borderRadius: 2, overflow: "hidden" }}>
                      <div style={{
                        height: "100%", background: "var(--primary)", borderRadius: 2,
                        width: `${Math.min(100, (item.view_count / (stats.top_content[0]?.view_count || 1)) * 100)}%`,
                      }} />
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}