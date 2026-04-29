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
    <div className="p-8 max-w-2xl">
      <h1 className="text-2xl font-semibold mb-8">App Settings & Branding</h1>

      <div className="space-y-6">
        <div className="bg-white dark:bg-surface rounded-xl p-6 border border-gray-200 dark:border-gray-800">
          <h2 className="font-semibold mb-4 flex items-center gap-2">
            <Radio size={18} className="text-primary" /> Branding
          </h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">Broadcaster Name</label>
              <input
                type="text"
                value={form.broadcaster}
                onChange={e => setForm(f => ({ ...f, broadcaster: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Primary Color</label>
              <div className="flex gap-3 items-center">
                <input
                  type="color"
                  value={form.primary_color}
                  onChange={e => setForm(f => ({ ...f, primary_color: e.target.value }))}
                  className="h-10 w-16 rounded border border-gray-300 cursor-pointer"
                />
                <input
                  type="text"
                  value={form.primary_color}
                  onChange={e => setForm(f => ({ ...f, primary_color: e.target.value }))}
                  className="flex-1 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm font-mono"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Logo URL</label>
              <input
                type="url"
                value={form.logo_url ?? ""}
                onChange={e => setForm(f => ({ ...f, logo_url: e.target.value || null }))}
                placeholder="https://..."
                className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm"
              />
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-surface rounded-xl p-6 border border-gray-200 dark:border-gray-800">
          <h2 className="font-semibold mb-4">Feature Flags</h2>
          <div className="space-y-3">
            {[
              { key: "enable_vod", label: "Video on Demand (VOD)", desc: "Show VOD tab in mobile app" },
              { key: "enable_podcasts", label: "Podcasts", desc: "Show Podcasts in Library tab" },
              { key: "enable_radio", label: "Live Radio", desc: "Show Radio tab in mobile app" },
            ].map(({ key, label, desc }) => (
              <div key={key} className="flex items-center justify-between py-2">
                <div>
                  <p className="text-sm font-medium">{label}</p>
                  <p className="text-xs text-gray-500">{desc}</p>
                </div>
                <button
                  onClick={() => setForm(f => ({ ...f, [key]: !f[key as keyof AppConfig] }))}
                  className={`relative w-11 h-6 rounded-full transition-colors ${
                    form[key as keyof AppConfig] ? "bg-primary" : "bg-gray-300 dark:bg-gray-600"
                  }`}
                >
                  <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${
                    form[key as keyof AppConfig] ? "translate-x-5" : ""
                  }`} />
                </button>
              </div>
            ))}
          </div>
        </div>

        <button
          onClick={() => saveMutation.mutate(form)}
          disabled={saveMutation.isPending}
          className="flex items-center gap-2 bg-primary text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-red-600 transition-colors disabled:opacity-60"
        >
          <Save size={16} />
          {saved ? "Saved!" : saveMutation.isPending ? "Saving..." : "Save Settings"}
        </button>
      </div>
    </div>
  );
}