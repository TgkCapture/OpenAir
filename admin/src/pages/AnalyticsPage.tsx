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
      <div className="p-8 flex justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  const cards = [
    { label: "Total Users", value: stats?.total_users ?? 0, icon: Users, color: "text-blue-500" },
    { label: "TV & Radio Channels", value: stats?.total_channels ?? 0, icon: Tv, color: "text-green-500" },
    { label: "VOD Videos", value: stats?.total_vod ?? 0, icon: Film, color: "text-purple-500" },
    { label: "Podcasts", value: stats?.total_podcasts ?? 0, icon: Radio, color: "text-orange-500" },
    { label: "Total Views", value: stats?.total_views ?? 0, icon: Eye, color: "text-red-500" },
  ];

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold">Analytics</h1>
        <span className="text-xs text-gray-400">Refreshes every 60s</span>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 mb-8">
        {cards.map(({ label, value, icon: Icon, color }) => (
          <div key={label}
            className="bg-white dark:bg-surface rounded-xl p-4 border border-gray-200 dark:border-gray-800">
            <div className={`${color} mb-2`}><Icon size={20} /></div>
            <div className="text-2xl font-bold">{value.toLocaleString()}</div>
            <div className="text-xs text-gray-500 mt-1">{label}</div>
          </div>
        ))}
      </div>

      {stats?.top_content && stats.top_content.length > 0 && (
        <div className="bg-white dark:bg-surface rounded-xl border border-gray-200 dark:border-gray-800 p-6">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp size={18} className="text-primary" />
            <h2 className="font-semibold">Top Content by Views</h2>
          </div>
          <div className="space-y-3">
            {stats.top_content.map((item, i) => (
              <div key={i} className="flex items-center gap-3">
                <span className="text-xs font-bold text-gray-400 w-5">{i + 1}</span>
                <div className="flex-1">
                  <div className="flex justify-between mb-1">
                    <span className="text-sm font-medium truncate">{item.title}</span>
                    <span className="text-xs text-gray-500 ml-2">{item.view_count} views</span>
                  </div>
                  <div className="h-1.5 bg-gray-100 dark:bg-gray-800 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-primary rounded-full"
                      style={{
                        width: `${Math.min(100, (item.view_count / (stats.top_content[0]?.view_count || 1)) * 100)}%`
                      }}
                    />
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