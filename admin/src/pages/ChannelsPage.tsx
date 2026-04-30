import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Edit, Tv, Radio, Eye, EyeOff, CheckCircle, XCircle, X } from "lucide-react";
import api from "../lib/api";
import FilePicker from "../components/FilePicker";

interface Channel {
  id: string; name: string; type: "tv" | "radio";
  stream_url: string; logo_url?: string;
  is_premium: boolean; is_active: boolean; sort_order: number;
}

const empty = { name: "", type: "tv", stream_url: "", logo_url: "", is_premium: false, is_active: true, sort_order: "0" };

export default function ChannelsPage() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Channel | null>(null);
  const [form, setForm] = useState<typeof empty>(empty);
  const [filter, setFilter] = useState<"all" | "tv" | "radio">("all");

  const { data: channels = [], isLoading } = useQuery({
    queryKey: ["channels"],
    queryFn: async () => (await api.get("/channels")).data.data as Channel[],
  });

  const saveMutation = useMutation({
    mutationFn: (data: object) =>
      editing ? api.put(`/admin/channels/${editing.id}`, data) : api.post("/admin/channels", data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["channels"] }); close(); },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isPremium }: { id: string; isPremium: boolean }) =>
      api.patch(`/admin/channels/${id}/access`, { is_premium: isPremium }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["channels"] }),
  });

  const close = () => { setShowForm(false); setEditing(null); setForm(empty); };

  const startEdit = (ch: Channel) => {
    setEditing(ch);
    setForm({ name: ch.name, type: ch.type, stream_url: ch.stream_url, logo_url: ch.logo_url ?? "", is_premium: ch.is_premium, is_active: ch.is_active, sort_order: ch.sort_order.toString() });
    setShowForm(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    saveMutation.mutate({ ...form, sort_order: parseInt(form.sort_order) || 0, logo_url: form.logo_url || null });
  };

  const filtered = channels.filter(c => filter === "all" || c.type === filter);

  return (
    <div style={{ padding: "32px" }}>
      <div className="page-header">
        <h1 className="page-title">Channels</h1>
        <button className="btn-primary" onClick={() => setShowForm(true)}>
          <Plus size={14} /> Add Channel
        </button>
      </div>

      {/* Filter tabs */}
      <div style={{ display: "flex", gap: 6, marginBottom: 20 }}>
        {(["all", "tv", "radio"] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)}
            style={{
              padding: "5px 14px", borderRadius: 20, fontSize: 12, fontWeight: 600,
              border: "1px solid var(--border)", cursor: "pointer",
              background: filter === f ? "var(--primary)" : "var(--bg-card)",
              color: filter === f ? "white" : "var(--text-2)",
            }}>
            {f === "all" ? "All" : f.toUpperCase()}
          </button>
        ))}
      </div>

      {showForm && (
        <div className="modal-overlay">
          <div className="modal">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
              <h2 className="modal-title" style={{ margin: 0 }}>{editing ? "Edit Channel" : "Add Channel"}</h2>
              <button onClick={close} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-3)" }}><X size={18} /></button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="label">Channel Name *</label>
                <input className="input" value={form.name} required
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label">Type</label>
                <select className="input" value={form.type}
                  onChange={e => setForm(f => ({ ...f, type: e.target.value }))}>
                  <option value="tv">TV</option>
                  <option value="radio">Radio</option>
                </select>
              </div>
              <div className="form-group">
                <label className="label">Stream URL *</label>
                <input className="input" type="url" value={form.stream_url} required
                  placeholder="rtmp:// or https://.m3u8"
                  onChange={e => setForm(f => ({ ...f, stream_url: e.target.value }))} />
              </div>
              <FilePicker label="Logo" value={form.logo_url}
                onChange={url => setForm(f => ({ ...f, logo_url: url }))}
                accept="image/*" placeholder="Paste logo URL or upload" />
              <div className="form-row">
                <div className="form-group">
                  <label className="label">Sort Order</label>
                  <input className="input" type="number" value={form.sort_order}
                    onChange={e => setForm(f => ({ ...f, sort_order: e.target.value }))} />
                </div>
                <div className="form-group" style={{ display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
                  <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer", marginBottom: 8 }}>
                    <label className="toggle">
                      <input type="checkbox" checked={form.is_premium}
                        onChange={e => setForm(f => ({ ...f, is_premium: e.target.checked }))} />
                      <span className="toggle-slider" />
                    </label>
                    <span style={{ fontSize: 13 }}>Premium</span>
                  </label>
                  <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer" }}>
                    <label className="toggle">
                      <input type="checkbox" checked={form.is_active}
                        onChange={e => setForm(f => ({ ...f, is_active: e.target.checked }))} />
                      <span className="toggle-slider" />
                    </label>
                    <span style={{ fontSize: 13 }}>Active</span>
                  </label>
                </div>
              </div>
              <div style={{ display: "flex", gap: 8, marginTop: 8 }}>
                <button type="submit" className="btn-primary" style={{ flex: 1, justifyContent: "center" }}
                  disabled={saveMutation.isPending}>
                  {saveMutation.isPending ? <span className="spinner" /> : (editing ? "Save" : "Add Channel")}
                </button>
                <button type="button" className="btn-ghost" onClick={close}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {isLoading ? (
        <div style={{ display: "flex", justifyContent: "center", padding: 48 }}>
          <span className="spinner" style={{ width: 28, height: 28 }} />
        </div>
      ) : filtered.length === 0 ? (
        <div className="empty-state">
          <Tv size={40} />
          <p>No channels yet. Add your first channel.</p>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {filtered.map(ch => (
            <div key={ch.id} className="card" style={{ display: "flex", alignItems: "center", gap: 14, padding: "14px 16px" }}>
              <div style={{ width: 40, height: 40, borderRadius: 8, background: "var(--bg)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, overflow: "hidden" }}>
                {ch.logo_url
                  ? <img src={ch.logo_url} style={{ width: "100%", height: "100%", objectFit: "cover" }} alt="" />
                  : (ch.type === "tv" ? <Tv size={18} style={{ color: "var(--text-3)" }} /> : <Radio size={18} style={{ color: "var(--text-3)" }} />)}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
                  <span style={{ fontSize: 13, fontWeight: 600 }}>{ch.name}</span>
                  <span className={`badge ${ch.type === "tv" ? "badge-blue" : "badge-green"}`}>{ch.type.toUpperCase()}</span>
                  {ch.is_premium && <span className="badge badge-red">PRO</span>}
                </div>
                <p style={{ fontSize: 11, color: "var(--text-3)", margin: "2px 0 0", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{ch.stream_url}</p>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
                {ch.is_active
                  ? <CheckCircle size={15} style={{ color: "#10B981" }} />
                  : <XCircle size={15} style={{ color: "var(--text-3)" }} />}
                <button onClick={() => toggleMutation.mutate({ id: ch.id, isPremium: !ch.is_premium })}
                  title={ch.is_premium ? "Set Free" : "Set Premium"}
                  style={{ padding: 6, background: "none", border: "none", cursor: "pointer", color: "var(--text-3)", borderRadius: 6 }}>
                  {ch.is_premium ? <EyeOff size={15} /> : <Eye size={15} />}
                </button>
                <button onClick={() => startEdit(ch)}
                  style={{ padding: 6, background: "none", border: "none", cursor: "pointer", color: "var(--text-3)", borderRadius: 6 }}>
                  <Edit size={15} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}