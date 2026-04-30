import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Send, Bell } from "lucide-react";
import api from "../lib/api";

export default function NotificationsPage() {
  const [form, setForm] = useState({
    title: "",
    body: "",
    send_all: true,
    image_url: "",
  });
  const [result, setResult] = useState<{ sent: number } | null>(null);

  const sendMutation = useMutation({
    mutationFn: (data: object) => api.post("/admin/notify", data),
    onSuccess: (res) => {
      setResult(res.data.data);
      setForm({ title: "", body: "", send_all: true, image_url: "" });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setResult(null);
    sendMutation.mutate({
      ...form,
      image_url: form.image_url || undefined,
    });
  };

  return (
    <div style={{ padding: "32px 32px 48px", maxWidth: 672 }}>
      {/* Header */}
      <div style={{ marginBottom: 32 }}>
        <h1 className="page-title" style={{ marginBottom: 8 }}>Push Notifications</h1>
        <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>
          Send push notifications to your app users.
        </p>
      </div>

      {/* Success message */}
      {result && (
        <div style={{
          display: "flex", alignItems: "center", gap: 12,
          padding: "12px 16px", borderRadius: "var(--radius-lg)",
          background: "rgba(16, 185, 129, 0.1)", border: "1px solid rgba(16, 185, 129, 0.25)",
          color: "#10B981", fontSize: 13, marginBottom: 24,
        }}>
          <Bell size={16} />
          <span>
            Notification sent to <strong>{result.sent}</strong> device{result.sent !== 1 ? "s" : ""}.
          </span>
        </div>
      )}

      {/* Error message */}
      {sendMutation.isError && (
        <div style={{
          padding: "12px 16px", borderRadius: "var(--radius-lg)",
          background: "rgba(239, 68, 68, 0.1)", border: "1px solid rgba(239, 68, 68, 0.25)",
          color: "#DC2626", fontSize: 13, marginBottom: 24,
        }}>
          Failed to send notification. Check your FCM configuration.
        </div>
      )}

      {/* Form card */}
      <div style={{
        background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
        padding: 24, border: "1px solid var(--border)",
      }}>
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
              Notification Title *
            </label>
            <input
              type="text"
              value={form.title}
              onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              placeholder="e.g. New episode available!"
              required
              style={{
                width: "100%", padding: "10px 16px", borderRadius: "var(--radius-md)",
                border: "1px solid var(--border)", background: "var(--bg)",
                color: "var(--text)", fontSize: 13,
              }}
            />
          </div>

          <div style={{ marginBottom: 16 }}>
            <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
              Message Body *
            </label>
            <textarea
              value={form.body}
              onChange={e => setForm(f => ({ ...f, body: e.target.value }))}
              placeholder="e.g. The latest episode of Tech Talk is now live."
              required
              rows={3}
              style={{
                width: "100%", padding: "10px 16px", borderRadius: "var(--radius-md)",
                border: "1px solid var(--border)", background: "var(--bg)",
                color: "var(--text)", fontSize: 13, resize: "vertical",
              }}
            />
          </div>

          <div style={{ marginBottom: 20 }}>
            <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
              Image URL <span style={{ color: "var(--text-3)", fontWeight: "normal" }}>(optional)</span>
            </label>
            <input
              type="url"
              value={form.image_url}
              onChange={e => setForm(f => ({ ...f, image_url: e.target.value }))}
              placeholder="https://..."
              style={{
                width: "100%", padding: "10px 16px", borderRadius: "var(--radius-md)",
                border: "1px solid var(--border)", background: "var(--bg)",
                color: "var(--text)", fontSize: 13,
              }}
            />
          </div>

          <div style={{
            background: "var(--bg)", borderRadius: "var(--radius-lg)",
            padding: 16, marginBottom: 20,
          }}>
            <p style={{ fontSize: 13, fontWeight: 500, margin: "0 0 12px", color: "var(--text)" }}>
              Send to
            </p>
            <label style={{ display: "flex", alignItems: "center", gap: 12, cursor: "pointer" }}>
              <input
                type="radio"
                checked={form.send_all}
                onChange={() => setForm(f => ({ ...f, send_all: true }))}
                style={{ accentColor: "var(--primary)" }}
              />
              <div>
                <p style={{ fontSize: 13, fontWeight: 500, margin: 0, color: "var(--text)" }}>All users</p>
                <p style={{ fontSize: 11, color: "var(--text-3)", margin: "2px 0 0" }}>
                  Send to every registered device
                </p>
              </div>
            </label>
          </div>

          {/* Preview */}
          {(form.title || form.body) && (
            <div style={{
              border: "1px solid var(--border)", borderRadius: "var(--radius-lg)",
              padding: 16, marginBottom: 20,
            }}>
              <p style={{ fontSize: 10, fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.05em", color: "var(--text-3)", margin: "0 0 12px" }}>
                Preview
              </p>
              <div style={{
                display: "flex", alignItems: "flex-start", gap: 12,
                background: "var(--bg)", borderRadius: "var(--radius-lg)",
                padding: 12,
              }}>
                <div style={{
                  width: 32, height: 32, background: "var(--primary)",
                  borderRadius: "var(--radius-md)", display: "flex",
                  alignItems: "center", justifyContent: "center", flexShrink: 0,
                }}>
                  <Bell size={14} style={{ color: "white" }} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{ fontSize: 13, fontWeight: 600, margin: 0, color: "var(--text)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {form.title || "Notification title"}
                  </p>
                  <p style={{ fontSize: 11, color: "var(--text-3)", margin: "4px 0 0", overflow: "hidden", textOverflow: "ellipsis", display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical" }}>
                    {form.body || "Notification body"}
                  </p>
                </div>
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={sendMutation.isPending}
            style={{
              width: "100%", display: "flex", alignItems: "center", justifyContent: "center",
              gap: 8, background: "var(--primary)", color: "white",
              border: "none", padding: "12px", borderRadius: "var(--radius-lg)",
              fontSize: 13, fontWeight: 600, cursor: "pointer",
              boxShadow: "0 4px 12px rgba(230, 57, 70, 0.2)",
            }}
            onMouseEnter={(e) => e.currentTarget.style.background = "#DC2626"}
            onMouseLeave={(e) => e.currentTarget.style.background = "var(--primary)"}
          >
            <Send size={16} />
            {sendMutation.isPending ? "Sending..." : "Send Notification"}
          </button>
        </form>
      </div>
    </div>
  );
}