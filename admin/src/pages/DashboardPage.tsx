import { useQuery } from "@tanstack/react-query";
import api from "../lib/api";
import { useAuthStore } from "../store/authStore";
import StatsOverview, { type Stats } from "../components/StatsOverview";

export default function DashboardPage() {
  const { user } = useAuthStore();
  const { data: stats, isLoading } = useQuery({
    queryKey: ["analytics"],
    queryFn: async () => (await api.get("/admin/analytics")).data.data as Stats,
    refetchInterval: 60_000,
  });

  const firstName = user?.full_name?.split(" ")[0];

  return (
    <div style={{ padding: "28px 32px" }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>
            {firstName ? `Welcome back, ${firstName}.` : "Welcome back."} Here is where things stand.
          </p>
        </div>
      </div>
      <StatsOverview stats={stats} loading={isLoading} linked />
    </div>
  );
}
