import { useMemo, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Pencil, Film, Trash2, Lock, LockOpen, Search } from "lucide-react";
import api from "../lib/api";
import { toast } from "../lib/toast";
import FilePicker from "../components/FilePicker";
import Modal from "../components/Modal";
import ConfirmDialog from "../components/ConfirmDialog";

interface VodItem {
  id: string; title: string; description?: string; type: string;
  file_url: string; thumbnail_url?: string; category?: string;
  duration_secs?: number; is_premium: boolean; is_published: boolean; view_count: number;
}

type Filter = "all" | "published" | "drafts" | "premium";

const FILTERS: { key: Filter; label: string }[] = [
  { key: "all", label: "All" },
  { key: "published", label: "Published" },
  { key: "drafts", label: "Drafts" },
  { key: "premium", label: "Premium" },
];

const empty = { title: "", description: "", type: "vod", file_url: "", thumbnail_url: "", category: "", duration_secs: "", is_premium: false, is_published: true };

function formatLength(secs?: number): string {
  if (!secs) return "";
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = String(secs % 60).padStart(2, "0");
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${s}` : `${m}:${s}`;
}

export default function VodPage() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<VodItem | null>(null);
  const [deleting, setDeleting] = useState<VodItem | null>(null);
  const [form, setForm] = useState<typeof empty>(empty);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<Filter>("all");

  const { data: items = [], isLoading, isError, refetch } = useQuery({
    queryKey: ["vod"],
    queryFn: async () => (await api.get("/admin/vod?per_page=200")).data.data as VodItem[],
  });

  const visible = useMemo(() => {
    const needle = search.trim().toLowerCase();
    return items.filter((item) => {
      if (filter === "published" && !item.is_published) return false;
      if (filter === "drafts" && item.is_published) return false;
      if (filter === "premium" && !item.is_premium) return false;
      if (!needle) return true;
      return item.title.toLowerCase().includes(needle)
        || (item.category ?? "").toLowerCase().includes(needle);
    });
  }, [items, search, filter]);

  const close = () => { setShowForm(false); setEditing(null); setForm(empty); };

  const saveMutation = useMutation({
    mutationFn: (data: object) =>
      editing ? api.put(`/admin/vod/${editing.id}`, data) : api.post("/admin/vod", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["vod"] });
      toast.success(editing ? "Video saved" : "Video added");
      close();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/vod/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["vod"] });
      toast.success("Video deleted");
    },
    onSettled: () => setDeleting(null),
  });

  const accessMutation = useMutation({
    mutationFn: ({ id, isPremium }: { id: string; isPremium: boolean }) =>
      api.patch(`/admin/vod/${id}/access`, { is_premium: isPremium }),
    onSuccess: (_, { isPremium }) => {
      qc.invalidateQueries({ queryKey: ["vod"] });
      toast.success(isPremium ? "Video is now premium" : "Video is now free");
    },
  });

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
    <div style={{ padding: "28px 32px" }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Videos</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>Upload, publish and set who can watch.</p>
        </div>
        <button className="btn-primary" onClick={() => setShowForm(true)}>
          <Plus size={16} aria-hidden="true" /> Add video
        </button>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <div className="search-wrap" style={{ flex: "1 1 240px", maxWidth: 360 }}>
          <Search size={16} aria-hidden="true" />
          <input
            className="input"
            type="search"
            aria-label="Search videos"
            placeholder="Search by title or category"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div role="group" aria-label="Filter videos" style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {FILTERS.map(({ key, label }) => (
            <button
              key={key}
              className="btn-ghost"
              aria-pressed={filter === key}
              onClick={() => setFilter(key)}
              style={{
                borderRadius: 20,
                ...(filter === key
                  ? { background: "var(--emphasis)", color: "var(--on-emphasis)", borderColor: "var(--emphasis)" }
                  : {}),
              }}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <div style={{ display: "flex", justifyContent: "center", padding: 48 }}>
          <span className="spinner" style={{ width: 28, height: 28 }} />
        </div>
      ) : isError ? (
        <div className="empty-state">
          <Film size={40} aria-hidden="true" />
          <p>Could not load videos.</p>
          <button className="btn-ghost" style={{ marginTop: 16 }} onClick={() => refetch()}>Try again</button>
        </div>
      ) : items.length === 0 ? (
        <div className="empty-state"><Film size={40} aria-hidden="true" /><p>No videos yet. Add the first one.</p></div>
      ) : visible.length === 0 ? (
        <div className="empty-state"><Search size={40} aria-hidden="true" /><p>No videos match your search or filter.</p></div>
      ) : (
        <div className="card" style={{ overflowX: "auto" }}>
          <table className="table" style={{ minWidth: 760 }}>
            <thead>
              <tr>
                <th>Title</th>
                <th>Category</th>
                <th>Access</th>
                <th>Status</th>
                <th>Length</th>
                <th>Views</th>
                <th><span style={{ position: "absolute", left: -9999 }}>Actions</span></th>
              </tr>
            </thead>
            <tbody>
              {visible.map((item) => (
                <tr key={item.id}>
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                      <div style={{ width: 64, height: 36, borderRadius: 8, background: "var(--bg-surface)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, overflow: "hidden" }}>
                        {item.thumbnail_url
                          ? <img src={item.thumbnail_url} style={{ width: "100%", height: "100%", objectFit: "cover" }} alt="" />
                          : <Film size={16} aria-hidden="true" style={{ color: "var(--text-3)" }} />}
                      </div>
                      <span style={{ fontWeight: 600 }}>{item.title}</span>
                    </div>
                  </td>
                  <td style={{ color: "var(--text-2)" }}>{item.category ?? ""}</td>
                  <td>
                    <span className={`badge ${item.is_premium ? "badge-red" : "badge-gray"}`}>
                      {item.is_premium ? "Premium" : "Free"}
                    </span>
                  </td>
                  <td>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 8, fontWeight: item.is_published ? 600 : 400, color: item.is_published ? "var(--text)" : "var(--text-3)" }}>
                      <span aria-hidden="true" style={{
                        width: 8, height: 8, borderRadius: 4, boxSizing: "border-box",
                        ...(item.is_published ? { background: "var(--success)" } : { border: "2px solid var(--text-3)" }),
                      }} />
                      {item.is_published ? "Published" : "Draft"}
                    </span>
                  </td>
                  <td style={{ color: "var(--text-2)" }}>{formatLength(item.duration_secs)}</td>
                  <td style={{ color: "var(--text-2)" }}>{item.view_count}</td>
                  <td>
                    <div style={{ display: "flex", justifyContent: "flex-end" }}>
                      <button
                        className="icon-btn"
                        aria-label={item.is_premium ? `Make ${item.title} free` : `Make ${item.title} premium`}
                        title={item.is_premium ? "Make free" : "Make premium"}
                        disabled={accessMutation.isPending}
                        onClick={() => accessMutation.mutate({ id: item.id, isPremium: !item.is_premium })}
                      >
                        {item.is_premium ? <LockOpen size={16} aria-hidden="true" /> : <Lock size={16} aria-hidden="true" />}
                      </button>
                      <button className="icon-btn" aria-label={`Edit ${item.title}`} title="Edit" onClick={() => startEdit(item)}>
                        <Pencil size={16} aria-hidden="true" />
                      </button>
                      <button className="icon-btn" aria-label={`Delete ${item.title}`} title="Delete" onClick={() => setDeleting(item)}>
                        <Trash2 size={16} aria-hidden="true" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {showForm && (
        <Modal title={editing ? "Edit video" : "Add video"} onClose={close} width={520}>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="label" htmlFor="vod-title">Title</label>
              <input id="vod-title" className="input" value={form.title} required minLength={2}
                onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
            </div>
            <div className="form-group">
              <label className="label" htmlFor="vod-description">Description</label>
              <textarea id="vod-description" className="input" value={form.description} rows={2} style={{ resize: "vertical" }}
                onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <FilePicker label="Video file" value={form.file_url}
              onChange={url => setForm(f => ({ ...f, file_url: url }))}
              accept="video/*" placeholder="Paste a video URL or upload a file" />
            <FilePicker label="Thumbnail" value={form.thumbnail_url}
              onChange={url => setForm(f => ({ ...f, thumbnail_url: url }))}
              accept="image/*" placeholder="Paste an image URL or upload" />
            <div className="form-row">
              <div className="form-group">
                <label className="label" htmlFor="vod-category">Category</label>
                <input id="vod-category" className="input" value={form.category}
                  placeholder="News, Sports, Drama"
                  onChange={e => setForm(f => ({ ...f, category: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label" htmlFor="vod-duration">Length in seconds</label>
                <input id="vod-duration" className="input" type="number" min={0} value={form.duration_secs}
                  onChange={e => setForm(f => ({ ...f, duration_secs: e.target.value }))} />
              </div>
            </div>
            {!editing && (
              <div className="form-group">
                <label className="label" htmlFor="vod-type">Type</label>
                <select id="vod-type" className="input" value={form.type}
                  onChange={e => setForm(f => ({ ...f, type: e.target.value }))}>
                  <option value="vod">Video</option>
                  <option value="promo">Promo</option>
                  <option value="highlight">Highlight</option>
                </select>
              </div>
            )}
            <div style={{ display: "flex", flexWrap: "wrap", gap: 20, marginBottom: 20 }}>
              <label style={{ display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }}>
                <span className="toggle">
                  <input type="checkbox" checked={form.is_premium}
                    onChange={e => setForm(f => ({ ...f, is_premium: e.target.checked }))} />
                  <span className="toggle-slider" />
                </span>
                Premium
              </label>
              <label style={{ display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }}>
                <span className="toggle">
                  <input type="checkbox" checked={form.is_published}
                    onChange={e => setForm(f => ({ ...f, is_published: e.target.checked }))} />
                  <span className="toggle-slider" />
                </span>
                Published
              </label>
            </div>
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, flexWrap: "wrap" }}>
              <button type="button" className="btn-ghost" onClick={close}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saveMutation.isPending || !form.file_url}>
                {saveMutation.isPending ? <span className="spinner" /> : (editing ? "Save" : "Add video")}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {deleting && (
        <ConfirmDialog
          title="Delete video?"
          message={`"${deleting.title}" will be removed for everyone. This cannot be undone.`}
          confirmLabel="Delete"
          busy={deleteMutation.isPending}
          onConfirm={() => deleteMutation.mutate(deleting.id)}
          onCancel={() => setDeleting(null)}
        />
      )}
    </div>
  );
}
