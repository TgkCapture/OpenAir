import { useQuery } from "@tanstack/react-query";
import { RefreshCw } from "lucide-react";
import api from "../lib/api";
import StatsOverview, { type Stats } from "../components/StatsOverview";

export default function AnalyticsPage() {
  const { data: stats, isLoading, isFetching, isError, refetch } = useQuery({
    queryKey: ["analytics"],
    queryFn: async () => (await api.get("/admin/analytics")).data.data as Stats,
    refetchInterval: 60_000,
  });

  return (
    <div style={{ padding: "28px 32px" }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Analytics</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>Totals across the platform, refreshed every minute.</p>
        </div>
        <button className="btn-ghost" onClick={() => refetch()} disabled={isFetching}>
          <RefreshCw size={15} aria-hidden="true" /> Refresh
        </button>
      </div>
      {isError ? (
        <div className="empty-state">
          <p>Could not load analytics.</p>
          <button className="btn-ghost" style={{ marginTop: 16 }} onClick={() => refetch()}>Try again</button>
        </div>
      ) : (
        <StatsOverview stats={stats} loading={isLoading} />
      )}
    </div>
  );
}
