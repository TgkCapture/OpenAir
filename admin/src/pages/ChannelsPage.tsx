import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Edit, Tv, Radio, Eye, EyeOff, CheckCircle, XCircle } from "lucide-react";
import api from "../lib/api";

interface Channel {
  id: string;
  name: string;
  type: "tv" | "radio";
  stream_url: string;
  logo_url?: string;
  is_premium: boolean;
  is_active: boolean;
  sort_order: number;
}

interface ChannelForm {
  name: string;
  type: string;
  stream_url: string;
  logo_url: string;
  is_premium: boolean;
  is_active: boolean;
  sort_order: string;
}

const empty: ChannelForm = {
  name: "", type: "tv", stream_url: "",
  logo_url: "", is_premium: false, is_active: true, sort_order: "0",
};

export default function ChannelsPage() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Channel | null>(null);
  const [form, setForm] = useState<ChannelForm>(empty);
  const [filter, setFilter] = useState<"all" | "tv" | "radio">("all");

  const { data: channels = [], isLoading } = useQuery({
    queryKey: ["channels"],
    queryFn: async () => {
      const res = await api.get("/channels");
      return res.data.data as Channel[];
    },
  });

  const createMutation = useMutation({
    mutationFn: (data: object) => api.post("/admin/channels", data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["channels"] }); setShowForm(false); setForm(empty); },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: object }) => api.put(`/admin/channels/${id}`, data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["channels"] }); setEditing(null); setShowForm(false); },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isPremium }: { id: string; isPremium: boolean }) =>
      api.patch(`/admin/channels/${id}/access`, { is_premium: isPremium }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["channels"] }),
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      ...form,
      sort_order: parseInt(form.sort_order) || 0,
      logo_url: form.logo_url || null,
    };
    if (editing) {
      updateMutation.mutate({ id: editing.id, data: payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const startEdit = (ch: Channel) => {
    setEditing(ch);
    setForm({
      name: ch.name, type: ch.type, stream_url: ch.stream_url,
      logo_url: ch.logo_url ?? "", is_premium: ch.is_premium,
      is_active: ch.is_active, sort_order: ch.sort_order.toString(),
    });
    setShowForm(true);
  };

  const filtered = channels.filter(c => filter === "all" || c.type === filter);

  return (
    <div style={{ padding: "32px 32px 48px" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
        <div>
          <h1 className="page-title" style={{ marginBottom: 4 }}>Channels</h1>
          <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>Manage TV and radio channels</p>
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
          <Plus size={16} /> Add Channel
        </button>
      </div>

      {/* Filter tabs */}
      <div style={{ display: "flex", gap: 8, marginBottom: 24 }}>
        {(["all", "tv", "radio"] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            style={{
              padding: "6px 16px", borderRadius: 999, fontSize: 13, fontWeight: 500,
              cursor: "pointer", transition: "all 0.2s",
              background: filter === f ? "var(--primary)" : "var(--bg)",
              color: filter === f ? "white" : "var(--text-2)",
              border: filter === f ? "none" : "1px solid var(--border)",
            }}
          >
            {f === "all" ? "All" : f === "tv" ? "TV" : "Radio"}
          </button>
        ))}
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
            padding: 24, width: "100%", maxWidth: 480,
            border: "1px solid var(--border)",
          }}>
            <h2 style={{ fontSize: 18, fontWeight: 600, margin: "0 0 16px", color: "var(--text)" }}>
              {editing ? "Edit Channel" : "Add Channel"}
            </h2>
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Name *
                </label>
                <input
                  type="text" value={form.name} required
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13,
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
                  <option value="tv">TV</option>
                  <option value="radio">Radio</option>
                </select>
              </div>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Stream URL *
                </label>
                <input
                  type="url" value={form.stream_url} required
                  onChange={e => setForm(f => ({ ...f, stream_url: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13,
                  }}
                />
              </div>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Logo URL
                </label>
                <input
                  type="url" value={form.logo_url}
                  onChange={e => setForm(f => ({ ...f, logo_url: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13,
                  }}
                />
              </div>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Sort Order
                </label>
                <input
                  type="number" value={form.sort_order}
                  onChange={e => setForm(f => ({ ...f, sort_order: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13,
                  }}
                />
              </div>
              <div style={{ display: "flex", gap: 16, marginBottom: 16 }}>
                <label style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, cursor: "pointer", color: "var(--text)" }}>
                  <input type="checkbox" checked={form.is_premium}
                    onChange={e => setForm(f => ({ ...f, is_premium: e.target.checked }))} />
                  Premium
                </label>
                <label style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, cursor: "pointer", color: "var(--text)" }}>
                  <input type="checkbox" checked={form.is_active}
                    onChange={e => setForm(f => ({ ...f, is_active: e.target.checked }))} />
                  Active
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
                  {editing ? "Save" : "Add Channel"}
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
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: "center", padding: "64px 0", color: "var(--text-3)" }}>
          <Tv size={48} style={{ margin: "0 auto 16px", opacity: 0.4 }} />
          <p>No channels yet.</p>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {filtered.map(ch => (
            <div
              key={ch.id}
              style={{
                display: "flex", alignItems: "center", gap: 16,
                padding: 16, borderRadius: "var(--radius-lg)",
                border: "1px solid var(--border)", background: "var(--bg-surface)",
              }}
            >
              <div style={{
                width: 40, height: 40, borderRadius: "var(--radius-md)",
                background: "var(--bg)", display: "flex", alignItems: "center",
                justifyContent: "center", flexShrink: 0,
              }}>
                {ch.type === "tv" ? <Tv size={20} style={{ color: "var(--text-3)" }} /> : <Radio size={20} style={{ color: "var(--text-3)" }} />}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                  <span style={{ fontSize: 13, fontWeight: 500, color: "var(--text)" }}>{ch.name}</span>
                  <span style={{
                    fontSize: 10, padding: "2px 8px", borderRadius: 4, fontWeight: 600,
                    background: ch.type === 'tv' ? "rgba(59,130,246,0.1)" : "rgba(16,185,129,0.1)",
                    color: ch.type === 'tv' ? "#3B82F6" : "#10B981",
                  }}>
                    {ch.type}
                  </span>
                  {ch.is_premium && (
                    <span style={{
                      background: "var(--primary)", color: "white",
                      fontSize: 10, padding: "2px 8px", borderRadius: 4, fontWeight: 600,
                    }}>PRO</span>
                  )}
                </div>
                <p style={{ fontSize: 11, color: "var(--text-3)", margin: "4px 0 0", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                  {ch.stream_url}
                </p>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
                {ch.is_active
                  ? <CheckCircle size={16} style={{ color: "#10B981" }} />
                  : <XCircle size={16} style={{ color: "var(--text-3)" }} />}
                <button
                  onClick={() => toggleMutation.mutate({ id: ch.id, isPremium: !ch.is_premium })}
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
                  title={ch.is_premium ? "Set Free" : "Set Premium"}
                >
                  {ch.is_premium ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
                <button
                  onClick={() => startEdit(ch)}
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