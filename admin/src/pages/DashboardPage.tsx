import { useQuery } from "@tanstack/react-query";
import { Users, Tv, Film, Radio, Eye, Settings } from "lucide-react";
import { Link } from "react-router-dom";
import api from "../lib/api";

export default function DashboardPage() {
  const { data: stats } = useQuery({
    queryKey: ["analytics"],
    queryFn: async () => (await api.get("/admin/analytics")).data.data,
    refetchInterval: 60_000,
  });

  const cards = [
    { label: "Users", value: stats?.total_users ?? "—", icon: Users, to: "/users", color: "bg-blue-50 dark:bg-blue-900/20 text-blue-600" },
    { label: "Channels", value: stats?.total_channels ?? "—", icon: Tv, to: "/channels", color: "bg-green-50 dark:bg-green-900/20 text-green-600" },
    { label: "Videos", value: stats?.total_vod ?? "—", icon: Film, to: "/vod", color: "bg-purple-50 dark:bg-purple-900/20 text-purple-600" },
    { label: "Podcasts", value: stats?.total_podcasts ?? "—", icon: Radio, to: "/podcasts", color: "bg-orange-50 dark:bg-orange-900/20 text-orange-600" },
    { label: "Total Views", value: stats?.total_views ?? "—", icon: Eye, to: "/analytics", color: "bg-red-50 dark:bg-red-900/20 text-red-600" },
  ];

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-semibold">Dashboard</h1>
          <p className="text-sm text-gray-500 mt-1">Welcome to OpenAir Admin</p>
        </div>
        <Link to="/settings"
          className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700 dark:hover:text-gray-300">
          <Settings size={16} /> Settings
        </Link>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 mb-8">
        {cards.map(({ label, value, icon: Icon, to, color }) => (
          <Link key={label} to={to}
            className="bg-white dark:bg-surface rounded-xl p-5 border border-gray-200 dark:border-gray-800 hover:border-primary/30 transition-colors">
            <div className={`w-10 h-10 rounded-lg ${color} flex items-center justify-center mb-3`}>
              <Icon size={20} />
            </div>
            <div className="text-2xl font-bold">{typeof value === 'number' ? value.toLocaleString() : value}</div>
            <div className="text-xs text-gray-500 mt-1">{label}</div>
          </Link>
        ))}
      </div>

      {stats?.top_content?.length > 0 && (
        <div className="bg-white dark:bg-surface rounded-xl p-6 border border-gray-200 dark:border-gray-800">
          <h2 className="font-semibold mb-4 text-sm">Top Content</h2>
          <div className="space-y-2">
            {stats.top_content.map((item: { title: string; view_count: number }, i: number) => (
              <div key={i} className="flex justify-between text-sm py-1.5 border-b border-gray-100 dark:border-gray-800 last:border-0">
                <span className="text-gray-700 dark:text-gray-300 truncate">{item.title}</span>
                <span className="text-gray-400 ml-4 flex-shrink-0">{item.view_count} views</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}