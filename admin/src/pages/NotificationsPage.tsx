import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Send, Bell, Check } from "lucide-react";
import api from "../lib/api";

export default function NotificationsPage() {
  const [form, setForm] = useState({ title: "", body: "", image_url: "" });
  const [result, setResult] = useState<{ sent: number } | null>(null);

  const sendMutation = useMutation({
    mutationFn: (data: object) => api.post("/admin/notify", data),
    onSuccess: res => { setResult(res.data.data); setForm({ title: "", body: "", image_url: "" }); },
  });

  return (
    <div style={{ padding: "32px", maxWidth: 580 }}>
      <div className="page-header">
        <h1 className="page-title">Push Notifications</h1>
      </div>

      {result && (
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 16px", borderRadius: 10, background: "rgba(16,185,129,0.08)", border: "1px solid rgba(16,185,129,0.25)", color: "#059669", fontSize: 13, marginBottom: 20 }}>
          <Check size={15} />
          Notification sent to <strong style={{ margin: "0 2px" }}>{result.sent}</strong> device{result.sent !== 1 ? "s" : ""}.
        </div>
      )}

      {sendMutation.isError && (
        <div style={{ padding: "12px 16px", borderRadius: 10, background: "rgba(239,68,68,0.08)", border: "1px solid rgba(239,68,68,0.25)", color: "#DC2626", fontSize: 13, marginBottom: 20 }}>
          Failed to send. Check your FCM configuration.
        </div>
      )}

      <div className="card" style={{ padding: 24 }}>
        <form onSubmit={e => { e.preventDefault(); setResult(null); sendMutation.mutate({ ...form, send_all: true, image_url: form.image_url || undefined }); }}>
          <div className="form-group">
            <label className="label">Title *</label>
            <input className="input" value={form.title} required
              placeholder="e.g. New episode available!"
              onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
          </div>
          <div className="form-group">
            <label className="label">Message *</label>
            <textarea className="input" value={form.body} required rows={3}
              placeholder="e.g. The latest episode is now live."
              style={{ resize: "none" }}
              onChange={e => setForm(f => ({ ...f, body: e.target.value }))} />
          </div>
          <div className="form-group">
            <label className="label">Image URL <span style={{ color: "var(--text-3)", fontWeight: 400, textTransform: "none" }}>(optional)</span></label>
            <input className="input" type="url" value={form.image_url}
              placeholder="https://…"
              onChange={e => setForm(f => ({ ...f, image_url: e.target.value }))} />
          </div>

          {/* Preview */}
          {(form.title || form.body) && (
            <div style={{ marginBottom: 20 }}>
              <div className="label" style={{ marginBottom: 8 }}>Preview</div>
              <div style={{ display: "flex", alignItems: "flex-start", gap: 12, padding: "12px 14px", borderRadius: 12, background: "var(--bg)", border: "1px solid var(--border)" }}>
                <div style={{ width: 36, height: 36, borderRadius: 8, background: "var(--primary)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Bell size={16} style={{ color: "white" }} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 2 }}>{form.title || "Title"}</div>
                  <div style={{ fontSize: 12, color: "var(--text-2)" }}>{form.body || "Message body"}</div>
                </div>
              </div>
            </div>
          )}

          <button type="submit" className="btn-primary"
            disabled={sendMutation.isPending}
            style={{ width: "100%", justifyContent: "center", padding: "11px" }}>
            {sendMutation.isPending ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Sending…</> : <><Send size={14} /> Send to All Users</>}
          </button>
        </form>
      </div>
    </div>
  );
}