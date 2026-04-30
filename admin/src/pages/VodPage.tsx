import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Edit, Trash2, Eye, EyeOff, Film } from "lucide-react";
import api from "../lib/api";

interface VodItem {
  id: string;
  title: string;
  description?: string;
  type: string;
  file_url: string;
  thumbnail_url?: string;
  category?: string;
  duration_secs?: number;
  is_premium: boolean;
  is_published: boolean;
  view_count: number;
}

interface VodForm {
  title: string;
  description: string;
  type: string;
  file_url: string;
  thumbnail_url: string;
  category: string;
  duration_secs: string;
  is_premium: boolean;
  is_published: boolean;
}

const empty: VodForm = {
  title: "", description: "", type: "vod",
  file_url: "", thumbnail_url: "", category: "",
  duration_secs: "", is_premium: false, is_published: true,
};

export default function VodPage() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<VodItem | null>(null);
  const [form, setForm] = useState<VodForm>(empty);

  const { data: items = [], isLoading } = useQuery({
    queryKey: ["vod"],
    queryFn: async () => {
      const res = await api.get("/vod?per_page=50");
      return res.data.data as VodItem[];
    },
  });

  const createMutation = useMutation({
    mutationFn: (data: object) => api.post("/admin/vod", data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["vod"] }); setShowForm(false); setForm(empty); },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: object }) => api.put(`/admin/vod/${id}`, data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["vod"] }); setEditing(null); setShowForm(false); },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isPremium }: { id: string; isPremium: boolean }) =>
      api.patch(`/admin/vod/${id}/access`, { is_premium: isPremium }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["vod"] }),
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      ...form,
      duration_secs: form.duration_secs ? parseInt(form.duration_secs) : null,
      thumbnail_url: form.thumbnail_url || null,
      description: form.description || null,
      category: form.category || null,
    };
    if (editing) {
      updateMutation.mutate({ id: editing.id, data: payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const startEdit = (item: VodItem) => {
    setEditing(item);
    setForm({
      title: item.title,
      description: item.description ?? "",
      type: item.type,
      file_url: item.file_url,
      thumbnail_url: item.thumbnail_url ?? "",
      category: item.category ?? "",
      duration_secs: item.duration_secs?.toString() ?? "",
      is_premium: item.is_premium,
      is_published: item.is_published,
    });
    setShowForm(true);
  };

  return (
    <div style={{ padding: "32px 32px 48px" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
        <div>
          <h1 className="page-title" style={{ marginBottom: 4 }}>VOD Management</h1>
          <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>Manage video on demand content</p>
        </div>
        <button
          onClick={() => { setEditing(null); setForm(empty); setShowForm(true); }}
          style={{
            display: "flex", alignItems: "center", gap: 8,
            background: "var(--primary)", color: "white",
            border: "none", padding: "8px 16px", borderRadius: "var(--radius-md)",
            fontSize: 13, fontWeight: 600, cursor: "pointer",
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = "#DC2626"}
          onMouseLeave={(e) => e.currentTarget.style.background = "var(--primary)"}
        >
          <Plus size={16} /> Add Video
        </button>
      </div>

      {/* Modal */}
      {showForm && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)",
          display: "flex", alignItems: "center", justifyContent: "center",
          zIndex: 50, padding: 16,
        }}>
          <div style={{
            background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
            padding: 24, width: "100%", maxWidth: 560,
            border: "1px solid var(--border)", maxHeight: "90vh", overflowY: "auto",
          }}>
            <h2 style={{ fontSize: 18, fontWeight: 600, margin: "0 0 16px", color: "var(--text)" }}>
              {editing ? "Edit Video" : "Add New Video"}
            </h2>
            <form onSubmit={handleSubmit}>
              {[
                { label: "Title *", key: "title", type: "text" },
                { label: "File URL *", key: "file_url", type: "url" },
                { label: "Thumbnail URL", key: "thumbnail_url", type: "url" },
                { label: "Category", key: "category", type: "text" },
                { label: "Duration (seconds)", key: "duration_secs", type: "number" },
              ].map(({ label, key, type }) => (
                <div key={key} style={{ marginBottom: 12 }}>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                    {label}
                  </label>
                  <input
                    type={type}
                    value={(form as unknown as Record<string, string>)[key]}
                    onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                    required={label.includes("*")}
                    style={{
                      width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                      border: "1px solid var(--border)", background: "var(--bg)",
                      color: "var(--text)", fontSize: 13,
                    }}
                  />
                </div>
              ))}
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Description
                </label>
                <textarea
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  rows={3}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13, resize: "vertical",
                  }}
                />
              </div>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Type
                </label>
                <select
                  value={form.type}
                  onChange={e => setForm(f => ({ ...f, type: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13,
                  }}
                >
                  <option value="vod">VOD</option>
                  <option value="promo">Promo</option>
                  <option value="highlight">Highlight</option>
                </select>
              </div>
              <div style={{ display: "flex", gap: 16, marginBottom: 16 }}>
                <label style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, cursor: "pointer", color: "var(--text)" }}>
                  <input type="checkbox" checked={form.is_premium}
                    onChange={e => setForm(f => ({ ...f, is_premium: e.target.checked }))} />
                  Premium
                </label>
                <label style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, cursor: "pointer", color: "var(--text)" }}>
                  <input type="checkbox" checked={form.is_published}
                    onChange={e => setForm(f => ({ ...f, is_published: e.target.checked }))} />
                  Published
                </label>
              </div>
              <div style={{ display: "flex", gap: 12 }}>
                <button
                  type="submit"
                  style={{
                    flex: 1, background: "var(--primary)", color: "white",
                    border: "none", padding: "10px", borderRadius: "var(--radius-md)",
                    fontSize: 13, fontWeight: 600, cursor: "pointer",
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.background = "#DC2626"}
                  onMouseLeave={(e) => e.currentTarget.style.background = "var(--primary)"}
                >
                  {editing ? "Save Changes" : "Add Video"}
                </button>
                <button
                  type="button"
                  onClick={() => { setShowForm(false); setEditing(null); }}
                  style={{
                    flex: 1, background: "transparent", color: "var(--text)",
                    border: "1px solid var(--border)", padding: "10px",
                    borderRadius: "var(--radius-md)", fontSize: 13, cursor: "pointer",
                  }}
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Content */}
      {isLoading ? (
        <div style={{ display: "flex", justifyContent: "center", padding: "48px 0" }}>
          <div style={{
            width: 32, height: 32, border: "2px solid var(--primary)",
            borderTopColor: "transparent", borderRadius: "50%",
            animation: "spin 0.8s linear infinite",
          }} />
        </div>
      ) : items.length === 0 ? (
        <div style={{ textAlign: "center", padding: "64px 0", color: "var(--text-3)" }}>
          <Film size={48} style={{ margin: "0 auto 16px", opacity: 0.4 }} />
          <p>No videos yet. Add your first video.</p>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {items.map(item => (
            <div
              key={item.id}
              style={{
                display: "flex", alignItems: "center", gap: 16,
                padding: 16, borderRadius: "var(--radius-lg)",
                border: "1px solid var(--border)", background: "var(--bg-surface)",
              }}
            >
              <div style={{
                width: 64, height: 48, borderRadius: "var(--radius-md)",
                background: "var(--bg)", display: "flex", alignItems: "center",
                justifyContent: "center", flexShrink: 0, overflow: "hidden",
              }}>
                {item.thumbnail_url
                  ? <img src={item.thumbnail_url} alt="" style={{ width: "100%", height: "100%", objectFit: "cover", borderRadius: "var(--radius-md)" }} />
                  : <Film size={24} style={{ color: "var(--text-3)" }} />}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                  <span style={{ fontSize: 13, fontWeight: 500, color: "var(--text)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {item.title}
                  </span>
                  {item.is_premium && (
                    <span style={{
                      background: "var(--primary)", color: "white",
                      fontSize: 10, padding: "2px 8px", borderRadius: 4, fontWeight: 600,
                    }}>PRO</span>
                  )}
                  {!item.is_published && (
                    <span style={{
                      background: "var(--bg)", color: "var(--text-2)",
                      fontSize: 10, padding: "2px 8px", borderRadius: 4,
                      border: "1px solid var(--border)",
                    }}>Draft</span>
                  )}
                </div>
                <div style={{ fontSize: 11, color: "var(--text-3)", marginTop: 4 }}>
                  {item.category && <span style={{ marginRight: 12 }}>{item.category}</span>}
                  <span>{item.view_count} views</span>
                </div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}>
                <button
                  onClick={() => toggleMutation.mutate({ id: item.id, isPremium: !item.is_premium })}
                  style={{
                    padding: 8, background: "transparent", border: "none",
                    borderRadius: "var(--radius-md)", cursor: "pointer",
                    color: item.is_premium ? "var(--primary)" : "var(--text-3)",
                    display: "flex",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = "var(--bg)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = "transparent";
                  }}
                  title={item.is_premium ? "Set Free" : "Set Premium"}
                >
                  {item.is_premium ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
                <button
                  onClick={() => startEdit(item)}
                  style={{
                    padding: 8, background: "transparent", border: "none",
                    borderRadius: "var(--radius-md)", cursor: "pointer",
                    color: "var(--text-3)", display: "flex",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = "var(--bg)";
                    e.currentTarget.style.color = "var(--primary)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = "transparent";
                    e.currentTarget.style.color = "var(--text-3)";
                  }}
                >
                  <Edit size={16} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}