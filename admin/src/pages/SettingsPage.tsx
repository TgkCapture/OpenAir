import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Save, Radio } from "lucide-react";
import api from "../lib/api";

interface AppConfig {
  broadcaster: string;
  primary_color: string;
  logo_url: string | null;
  enable_vod: boolean;
  enable_podcasts: boolean;
  enable_radio: boolean;
}

export default function SettingsPage() {
  const qc = useQueryClient();
  const [form, setForm] = useState<AppConfig>({
    broadcaster: "OpenAir",
    primary_color: "#E63946",
    logo_url: null,
    enable_vod: true,
    enable_podcasts: true,
    enable_radio: true,
  });
  const [saved, setSaved] = useState(false);

  const { data: config } = useQuery({
    queryKey: ["app-config"],
    queryFn: async () => {
      const res = await api.get("/config");
      return res.data.data as AppConfig;
    },
  });

  useEffect(() => {
    if (config) setForm(config);
  }, [config]);

  const saveMutation = useMutation({
    mutationFn: (data: AppConfig) => api.put("/admin/config", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["app-config"] });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    },
  });

  return (
    <div style={{ padding: "32px 32px 48px", maxWidth: 672 }}>
      {/* Header */}
      <div style={{ marginBottom: 32 }}>
        <h1 className="page-title" style={{ marginBottom: 8 }}>App Settings & Branding</h1>
        <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>
          Configure your application branding and features
        </p>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
        {/* Branding section */}
        <div style={{
          background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
          padding: 24, border: "1px solid var(--border)",
        }}>
          <h2 style={{
            fontSize: 14, fontWeight: 700, margin: "0 0 20px",
            display: "flex", alignItems: "center", gap: 8, color: "var(--text)",
          }}>
            <Radio size={18} style={{ color: "var(--primary)" }} /> Branding
          </h2>
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                Broadcaster Name
              </label>
              <input
                type="text"
                value={form.broadcaster}
                onChange={e => setForm(f => ({ ...f, broadcaster: e.target.value }))}
                style={{
                  width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                  border: "1px solid var(--border)", background: "var(--bg)",
                  color: "var(--text)", fontSize: 13,
                }}
              />
            </div>
            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                Primary Color
              </label>
              <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                <input
                  type="color"
                  value={form.primary_color}
                  onChange={e => setForm(f => ({ ...f, primary_color: e.target.value }))}
                  style={{ width: 40, height: 40, borderRadius: "var(--radius-md)", border: "1px solid var(--border)", cursor: "pointer" }}
                />
                <input
                  type="text"
                  value={form.primary_color}
                  onChange={e => setForm(f => ({ ...f, primary_color: e.target.value }))}
                  style={{
                    flex: 1, padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13, fontFamily: "monospace",
                  }}
                />
              </div>
            </div>
            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                Logo URL
              </label>
              <input
                type="url"
                value={form.logo_url ?? ""}
                onChange={e => setForm(f => ({ ...f, logo_url: e.target.value || null }))}
                placeholder="https://..."
                style={{
                  width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                  border: "1px solid var(--border)", background: "var(--bg)",
                  color: "var(--text)", fontSize: 13,
                }}
              />
            </div>
          </div>
        </div>

        {/* Feature flags section */}
        <div style={{
          background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
          padding: 24, border: "1px solid var(--border)",
        }}>
          <h2 style={{ fontSize: 14, fontWeight: 700, margin: "0 0 20px", color: "var(--text)" }}>
            Feature Flags
          </h2>
          <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
            {[
              { key: "enable_vod", label: "Video on Demand (VOD)", desc: "Show VOD tab in mobile app" },
              { key: "enable_podcasts", label: "Podcasts", desc: "Show Podcasts in Library tab" },
              { key: "enable_radio", label: "Live Radio", desc: "Show Radio tab in mobile app" },
            ].map(({ key, label, desc }) => (
              <div key={key} style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <div>
                  <p style={{ fontSize: 13, fontWeight: 500, margin: 0, color: "var(--text)" }}>{label}</p>
                  <p style={{ fontSize: 11, color: "var(--text-3)", margin: "2px 0 0" }}>{desc}</p>
                </div>
                <button
                  onClick={() => setForm(f => ({ ...f, [key]: !f[key as keyof AppConfig] }))}
                  style={{
                    width: 44, height: 24, borderRadius: 999, border: "none",
                    background: form[key as keyof AppConfig] ? "var(--primary)" : "var(--border)",
                    cursor: "pointer", position: "relative", transition: "all 0.2s",
                    flexShrink: 0,
                  }}
                >
                  <span style={{
                    position: "absolute", top: 2, left: form[key as keyof AppConfig] ? 22 : 2,
                    width: 20, height: 20, background: "white", borderRadius: "50%",
                    transition: "all 0.2s",
                  }} />
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Save button */}
        <button
          onClick={() => saveMutation.mutate(form)}
          disabled={saveMutation.isPending}
          style={{
            display: "flex", alignItems: "center", justifyContent: "center",
            gap: 8, background: "var(--primary)", color: "white",
            border: "none", padding: "10px 24px", borderRadius: "var(--radius-md)",
            fontSize: 13, fontWeight: 600, cursor: "pointer", width: "fit-content",
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = "#DC2626"}
          onMouseLeave={(e) => e.currentTarget.style.background = "var(--primary)"}
        >
          <Save size={16} />
          {saved ? "Saved!" : saveMutation.isPending ? "Saving..." : "Save Settings"}
        </button>
      </div>
    </div>
  );
}