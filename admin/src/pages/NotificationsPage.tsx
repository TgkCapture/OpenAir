import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Send, Bell } from "lucide-react";
import api from "../lib/api";
import { toast } from "../lib/toast";
import ConfirmDialog from "../components/ConfirmDialog";

const empty = { title: "", body: "", image_url: "" };

export default function NotificationsPage() {
  const [form, setForm] = useState(empty);
  const [confirming, setConfirming] = useState(false);

  const sendMutation = useMutation({
    mutationFn: () =>
      api.post("/admin/notify", { ...form, send_all: true, image_url: form.image_url || undefined }),
    onSuccess: (res) => {
      const { saved = 0, sent = 0 } = res.data.data as { saved?: number; sent?: number };
      toast.success(
        `Sent to ${saved} ${saved === 1 ? "user" : "users"}; pushed to ${sent} ${sent === 1 ? "device" : "devices"}.`,
      );
      setForm(empty);
    },
    onSettled: () => setConfirming(false),
  });

  return (
    <div style={{ padding: "28px 32px", maxWidth: 620 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Notifications</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>
            Send a message to everyone. It appears in the app, and as a push on devices that allow it.
          </p>
        </div>
      </div>

      <div className="card" style={{ padding: 24 }}>
        <form onSubmit={(e) => { e.preventDefault(); setConfirming(true); }}>
          <div className="form-group">
            <label className="label" htmlFor="notif-title">Title</label>
            <input id="notif-title" className="input" value={form.title} required maxLength={80}
              placeholder="New episode available"
              onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
          </div>
          <div className="form-group">
            <label className="label" htmlFor="notif-body">Message</label>
            <textarea id="notif-body" className="input" value={form.body} required rows={3} maxLength={240}
              placeholder="The latest episode is ready to play."
              style={{ resize: "vertical" }}
              onChange={e => setForm(f => ({ ...f, body: e.target.value }))} />
          </div>
          <div className="form-group">
            <label className="label" htmlFor="notif-image">Image URL (optional)</label>
            <input id="notif-image" className="input" type="url" value={form.image_url}
              placeholder="https://example.com/image.jpg"
              onChange={e => setForm(f => ({ ...f, image_url: e.target.value }))} />
          </div>

          {(form.title || form.body) && (
            <div style={{ marginBottom: 20 }}>
              <div className="label">Preview</div>
              <div style={{ display: "flex", alignItems: "flex-start", gap: 12, padding: "12px 14px", borderRadius: "var(--radius-md)", background: "var(--bg-surface)" }}>
                <div style={{ width: 36, height: 36, borderRadius: 8, background: "var(--primary)", color: "var(--on-primary)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Bell size={17} aria-hidden="true" />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 700, marginBottom: 2, overflowWrap: "anywhere" }}>{form.title || "Title"}</div>
                  <div style={{ fontSize: 13, color: "var(--text-2)", overflowWrap: "anywhere" }}>{form.body || "Message"}</div>
                </div>
              </div>
            </div>
          )}

          <div style={{ display: "flex", justifyContent: "flex-end" }}>
            <button type="submit" className="btn-primary" disabled={sendMutation.isPending}>
              <Send size={15} aria-hidden="true" /> Send to everyone
            </button>
          </div>
        </form>
      </div>

      {confirming && (
        <ConfirmDialog
          title="Send to everyone?"
          message={`"${form.title}" will go to every active user. It cannot be recalled once sent.`}
          confirmLabel="Send"
          busy={sendMutation.isPending}
          onConfirm={() => sendMutation.mutate()}
          onCancel={() => setConfirming(false)}
        />
      )}
    </div>
  );
}
