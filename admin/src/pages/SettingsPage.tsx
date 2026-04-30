import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Save, Check } from "lucide-react";
import api from "../lib/api";
import FilePicker from "../components/FilePicker";

interface AppConfig {
  broadcaster: string; primary_color: string;
  logo_url: string | null; enable_vod: boolean;
  enable_podcasts: boolean; enable_radio: boolean;
}

export default function SettingsPage() {
  const qc = useQueryClient();
  const [form, setForm] = useState<AppConfig>({ broadcaster: "OpenAir", primary_color: "#E63946", logo_url: null, enable_vod: true, enable_podcasts: true, enable_radio: true });
  const [saved, setSaved] = useState(false);

  const { data: config } = useQuery({
    queryKey: ["app-config"],
    queryFn: async () => (await api.get("/config")).data.data as AppConfig,
  });

  useEffect(() => { if (config) setForm(config); }, [config]);

  const saveMutation = useMutation({
    mutationFn: (data: AppConfig) => api.put("/admin/config", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["app-config"] });
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    },
  });

  const flags = [
    { key: "enable_vod",      label: "Video on Demand", desc: "Show VOD tab in mobile app" },
    { key: "enable_podcasts", label: "Podcasts",         desc: "Show Podcasts in Library tab" },
    { key: "enable_radio",    label: "Live Radio",       desc: "Show Radio tab in mobile app" },
  ];

  return (
    <div style={{ padding: "32px", maxWidth: 640 }}>
      <div className="page-header">
        <h1 className="page-title">App Settings</h1>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>

        {/* Branding */}
        <div className="card" style={{ padding: 24 }}>
          <h2 style={{ fontSize: 14, fontWeight: 700, margin: "0 0 20px" }}>Branding</h2>
          <div className="form-group">
            <label className="label">Broadcaster Name</label>
            <input className="input" value={form.broadcaster}
              onChange={e => setForm(f => ({ ...f, broadcaster: e.target.value }))} />
          </div>
          <div className="form-group">
            <label className="label">Primary Color</label>
            <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <input type="color" value={form.primary_color}
                onChange={e => setForm(f => ({ ...f, primary_color: e.target.value }))}
                style={{ width: 44, height: 36, borderRadius: 6, border: "1px solid var(--border)", cursor: "pointer", padding: 2 }} />
              <input className="input" value={form.primary_color}
                onChange={e => setForm(f => ({ ...f, primary_color: e.target.value }))}
                style={{ fontFamily: "var(--font-mono)", flex: 1 }} />
              <div style={{ width: 36, height: 36, borderRadius: 6, background: form.primary_color, flexShrink: 0, border: "1px solid var(--border)" }} />
            </div>
          </div>
          <FilePicker label="App Logo" value={form.logo_url ?? ""}
            onChange={url => setForm(f => ({ ...f, logo_url: url || null }))}
            accept="image/*" placeholder="Paste logo URL or upload" />
        </div>

        {/* Feature flags */}
        <div className="card" style={{ padding: 24 }}>
          <h2 style={{ fontSize: 14, fontWeight: 700, margin: "0 0 20px" }}>Feature Flags</h2>
          {flags.map(({ key, label, desc }) => (
            <div key={key} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 0", borderBottom: "1px solid var(--border)" }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{label}</div>
                <div style={{ fontSize: 12, color: "var(--text-3)", marginTop: 1 }}>{desc}</div>
              </div>
              <label className="toggle">
                <input type="checkbox"
                  checked={form[key as keyof AppConfig] as boolean}
                  onChange={e => setForm(f => ({ ...f, [key]: e.target.checked }))} />
                <span className="toggle-slider" />
              </label>
            </div>
          ))}
        </div>

        <button
          className="btn-primary"
          onClick={() => saveMutation.mutate(form)}
          disabled={saveMutation.isPending}
          style={{ alignSelf: "flex-start", padding: "10px 24px" }}>
          {saved ? <><Check size={14} /> Saved!</> : saveMutation.isPending ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Saving…</> : <><Save size={14} /> Save Settings</>}
        </button>
      </div>
    </div>
  );
}