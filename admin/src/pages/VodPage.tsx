import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Edit, Eye, EyeOff, Film, X } from "lucide-react";
import api from "../lib/api";
import FilePicker from "../components/FilePicker";

interface VodItem {
  id: string; title: string; description?: string; type: string;
  file_url: string; thumbnail_url?: string; category?: string;
  duration_secs?: number; is_premium: boolean; is_published: boolean; view_count: number;
}

const empty = { title: "", description: "", type: "vod", file_url: "", thumbnail_url: "", category: "", duration_secs: "", is_premium: false, is_published: true };

export default function VodPage() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<VodItem | null>(null);
  const [form, setForm] = useState<typeof empty>(empty);

  const { data: items = [], isLoading } = useQuery({
    queryKey: ["vod"],
    queryFn: async () => (await api.get("/vod?per_page=50")).data.data as VodItem[],
  });

  const saveMutation = useMutation({
    mutationFn: (data: object) =>
      editing ? api.put(`/admin/vod/${editing.id}`, data) : api.post("/admin/vod", data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["vod"] }); close(); },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isPremium }: { id: string; isPremium: boolean }) =>
      api.patch(`/admin/vod/${id}/access`, { is_premium: isPremium }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["vod"] }),
  });

  const close = () => { setShowForm(false); setEditing(null); setForm(empty); };

  const startEdit = (item: VodItem) => {
    setEditing(item);
    setForm({ title: item.title, description: item.description ?? "", type: item.type, file_url: item.file_url, thumbnail_url: item.thumbnail_url ?? "", category: item.category ?? "", duration_secs: item.duration_secs?.toString() ?? "", is_premium: item.is_premium, is_published: item.is_published });
    setShowForm(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    saveMutation.mutate({ ...form, duration_secs: form.duration_secs ? parseInt(form.duration_secs) : null, thumbnail_url: form.thumbnail_url || null, description: form.description || null, category: form.category || null });
  };

  return (
    <div style={{ padding: "32px" }}>
      <div className="page-header">
        <h1 className="page-title">VOD Management</h1>
        <button className="btn-primary" onClick={() => setShowForm(true)}>
          <Plus size={14} /> Add Video
        </button>
      </div>

      {showForm && (
        <div className="modal-overlay">
          <div className="modal" style={{ maxWidth: 520 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
              <h2 className="modal-title" style={{ margin: 0 }}>{editing ? "Edit Video" : "Add Video"}</h2>
              <button onClick={close} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-3)" }}><X size={18} /></button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="label">Title *</label>
                <input className="input" value={form.title} required
                  onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label">Description</label>
                <textarea className="input" value={form.description} rows={2} style={{ resize: "none" }}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
              </div>
              <FilePicker label="Video File *" value={form.file_url}
                onChange={url => setForm(f => ({ ...f, file_url: url }))}
                accept="video/*" placeholder="Paste video URL or upload file" />
              <FilePicker label="Thumbnail" value={form.thumbnail_url}
                onChange={url => setForm(f => ({ ...f, thumbnail_url: url }))}
                accept="image/*" placeholder="Paste image URL or upload" />
              <div className="form-row">
                <div className="form-group">
                  <label className="label">Category</label>
                  <input className="input" value={form.category}
                    placeholder="News, Sports, Drama…"
                    onChange={e => setForm(f => ({ ...f, category: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label className="label">Duration (seconds)</label>
                  <input className="input" type="number" value={form.duration_secs}
                    onChange={e => setForm(f => ({ ...f, duration_secs: e.target.value }))} />
                </div>
              </div>
              <div className="form-group">
                <label className="label">Type</label>
                <select className="input" value={form.type}
                  onChange={e => setForm(f => ({ ...f, type: e.target.value }))}>
                  <option value="vod">VOD</option>
                  <option value="promo">Promo</option>
                  <option value="highlight">Highlight</option>
                </select>
              </div>
              <div style={{ display: "flex", gap: 16, marginBottom: 16 }}>
                <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer" }}>
                  <label className="toggle">
                    <input type="checkbox" checked={form.is_premium}
                      onChange={e => setForm(f => ({ ...f, is_premium: e.target.checked }))} />
                    <span className="toggle-slider" />
                  </label>
                  <span style={{ fontSize: 13 }}>Premium</span>
                </label>
                <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer" }}>
                  <label className="toggle">
                    <input type="checkbox" checked={form.is_published}
                      onChange={e => setForm(f => ({ ...f, is_published: e.target.checked }))} />
                    <span className="toggle-slider" />
                  </label>
                  <span style={{ fontSize: 13 }}>Published</span>
                </label>
              </div>
              <div style={{ display: "flex", gap: 8 }}>
                <button type="submit" className="btn-primary" style={{ flex: 1, justifyContent: "center" }}
                  disabled={saveMutation.isPending}>
                  {saveMutation.isPending ? <span className="spinner" /> : (editing ? "Save" : "Add Video")}
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
      ) : items.length === 0 ? (
        <div className="empty-state"><Film size={40} /><p>No videos yet.</p></div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {items.map(item => (
            <div key={item.id} className="card" style={{ display: "flex", alignItems: "center", gap: 14, padding: "12px 16px" }}>
              <div style={{ width: 56, height: 40, borderRadius: 6, background: "var(--bg)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, overflow: "hidden" }}>
                {item.thumbnail_url
                  ? <img src={item.thumbnail_url} style={{ width: "100%", height: "100%", objectFit: "cover" }} alt="" />
                  : <Film size={18} style={{ color: "var(--text-3)" }} />}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
                  <span style={{ fontSize: 13, fontWeight: 600 }}>{item.title}</span>
                  {item.is_premium && <span className="badge badge-red">PRO</span>}
                  {!item.is_published && <span className="badge badge-gray">Draft</span>}
                </div>
                <p style={{ fontSize: 11, color: "var(--text-3)", margin: "2px 0 0" }}>
                  {item.category && <span style={{ marginRight: 8 }}>{item.category}</span>}
                  {item.view_count} views
                </p>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
                <button onClick={() => toggleMutation.mutate({ id: item.id, isPremium: !item.is_premium })}
                  title={item.is_premium ? "Set Free" : "Set Premium"}
                  style={{ padding: 6, background: "none", border: "none", cursor: "pointer", color: item.is_premium ? "var(--primary)" : "var(--text-3)", borderRadius: 6 }}>
                  {item.is_premium ? <EyeOff size={15} /> : <Eye size={15} />}
                </button>
                <button onClick={() => startEdit(item)}
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