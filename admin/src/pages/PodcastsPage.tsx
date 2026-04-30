import { Mic } from "lucide-react";

export default function PodcastsPage() {
  return (
    <div style={{ padding: "32px 32px 48px" }}>
      <div style={{ marginBottom: 24 }}>
        <h1 className="page-title" style={{ marginBottom: 8 }}>Podcasts</h1>
        <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>
          Manage podcast episodes
        </p>
      </div>

      <div style={{
        background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
        border: "1px solid var(--border)", padding: 48,
        textAlign: "center",
      }}>
        <Mic size={64} style={{ margin: "0 auto 16px", opacity: 0.3, color: "var(--text-3)" }} />
        <p style={{ fontSize: 14, color: "var(--text-2)", marginBottom: 8 }}>
          Podcast management coming soon
        </p>
        <p style={{ fontSize: 12, color: "var(--text-3)" }}>
          Full podcast episode management will be available in milestone 6
        </p>
      </div>
    </div>
  );
}