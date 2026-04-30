import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2, Calendar } from "lucide-react";
import api from "../lib/api";

interface Channel {
  id: string;
  name: string;
  type: string;
}

interface Programme {
  id: string;
  channel_id: string;
  title: string;
  description?: string;
  starts_at: string;
  ends_at: string;
}

const toLocalInput = (iso: string) => {
  const d = new Date(iso);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}T${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

export default function SchedulePage() {
  const qc = useQueryClient();
  const [selectedChannel, setSelectedChannel] = useState<string>("");
  const [selectedDate, setSelectedDate] = useState(
    new Date().toISOString().split("T")[0]
  );
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    channel_id: "",
    title: "",
    description: "",
    starts_at: "",
    ends_at: "",
  });

  const { data: channels = [] } = useQuery({
    queryKey: ["channels-tv"],
    queryFn: async () => {
      const res = await api.get("/channels?type=tv");
      return res.data.data as Channel[];
    },
  });

  useEffect(() => {
    if (channels.length > 0 && !selectedChannel) {
      setSelectedChannel(channels[0].id);
    }
  }, [channels, selectedChannel]);

  const { data: programmes = [] } = useQuery({
    queryKey: ["schedule", selectedChannel, selectedDate],
    queryFn: async () => {
      if (!selectedChannel) return [];
      const res = await api.get(`/schedule/${selectedChannel}?date=${selectedDate}`);
      return res.data.data as Programme[];
    },
    enabled: !!selectedChannel,
  });

  const createMutation = useMutation({
    mutationFn: (data: object) => api.post("/admin/schedule", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["schedule"] });
      setShowForm(false);
      setForm({ channel_id: "", title: "", description: "", starts_at: "", ends_at: "" });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/schedule/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["schedule"] }),
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createMutation.mutate({
      ...form,
      channel_id: form.channel_id || selectedChannel,
      starts_at: new Date(form.starts_at).toISOString(),
      ends_at: new Date(form.ends_at).toISOString(),
      description: form.description || null,
    });
  };

  const formatTime = (iso: string) =>
    new Date(iso).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

  const isLive = (p: Programme) => {
    const now = new Date();
    return new Date(p.starts_at) <= now && now < new Date(p.ends_at);
  };

  return (
    <div style={{ padding: "32px 32px 48px" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
        <div>
          <h1 className="page-title" style={{ marginBottom: 4 }}>Programme Schedule</h1>
          <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>Manage your TV schedule</p>
        </div>
        <button
          onClick={() => setShowForm(true)}
          style={{
            display: "flex", alignItems: "center", gap: 8,
            background: "var(--primary)", color: "white",
            border: "none", padding: "8px 16px", borderRadius: "var(--radius-md)",
            fontSize: 13, fontWeight: 600, cursor: "pointer",
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = "#DC2626"}
          onMouseLeave={(e) => e.currentTarget.style.background = "var(--primary)"}
        >
          <Plus size={16} /> Add Programme
        </button>
      </div>

      {/* Filters */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 12, marginBottom: 24 }}>
        <select
          value={selectedChannel}
          onChange={e => setSelectedChannel(e.target.value)}
          style={{
            padding: "8px 12px", borderRadius: "var(--radius-md)",
            border: "1px solid var(--border)", background: "var(--bg)",
            color: "var(--text)", fontSize: 13,
          }}
        >
          {channels.map(c => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
        <input
          type="date"
          value={selectedDate}
          onChange={e => setSelectedDate(e.target.value)}
          style={{
            padding: "8px 12px", borderRadius: "var(--radius-md)",
            border: "1px solid var(--border)", background: "var(--bg)",
            color: "var(--text)", fontSize: 13,
          }}
        />
      </div>

      {/* Add form modal */}
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
              Add Programme
            </h2>
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Channel
                </label>
                <select
                  value={form.channel_id || selectedChannel}
                  onChange={e => setForm(f => ({ ...f, channel_id: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13,
                  }}
                >
                  {channels.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Title *
                </label>
                <input
                  type="text" required value={form.title}
                  onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13,
                  }}
                />
              </div>
              <div style={{ marginBottom: 12 }}>
                <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                  Description
                </label>
                <textarea
                  value={form.description} rows={2}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: "1px solid var(--border)", background: "var(--bg)",
                    color: "var(--text)", fontSize: 13, resize: "vertical",
                  }}
                />
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 16 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                    Starts at *
                  </label>
                  <input
                    type="datetime-local" required value={form.starts_at}
                    onChange={e => setForm(f => ({ ...f, starts_at: e.target.value }))}
                    style={{
                      width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                      border: "1px solid var(--border)", background: "var(--bg)",
                      color: "var(--text)", fontSize: 13,
                    }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 500, marginBottom: 6, color: "var(--text)" }}>
                    Ends at *
                  </label>
                  <input
                    type="datetime-local" required value={form.ends_at}
                    onChange={e => setForm(f => ({ ...f, ends_at: e.target.value }))}
                    style={{
                      width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                      border: "1px solid var(--border)", background: "var(--bg)",
                      color: "var(--text)", fontSize: 13,
                    }}
                  />
                </div>
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
                  Add
                </button>
                <button
                  type="button"
                  onClick={() => setShowForm(false)}
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

      {/* Timeline */}
      {programmes.length === 0 ? (
        <div style={{ textAlign: "center", padding: "64px 0", color: "var(--text-3)" }}>
          <Calendar size={48} style={{ margin: "0 auto 16px", opacity: 0.4 }} />
          <p>No programmes scheduled for this day.</p>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {programmes.map(p => {
            const live = isLive(p);
            return (
              <div
                key={p.id}
                style={{
                  display: "flex", alignItems: "center", gap: 16,
                  padding: 16, borderRadius: "var(--radius-lg)",
                  border: `1px solid ${live ? "var(--primary)" : "var(--border)"}`,
                  background: live ? "rgba(230, 57, 70, 0.05)" : "var(--bg-surface)",
                  transition: "all 0.2s",
                }}
              >
                <div style={{ width: 80, flexShrink: 0, textAlign: "center" }}>
                  <div style={{ fontSize: 13, fontWeight: 700, color: live ? "var(--primary)" : "var(--text-2)" }}>
                    {formatTime(p.starts_at)}
                  </div>
                  <div style={{ fontSize: 11, color: "var(--text-3)" }}>
                    {formatTime(p.ends_at)}
                  </div>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    {live && (
                      <span style={{
                        background: "var(--primary)", color: "white",
                        fontSize: 10, padding: "2px 6px", borderRadius: 4,
                        fontWeight: 700,
                      }}>
                        LIVE
                      </span>
                    )}
                    <span style={{ fontSize: 13, fontWeight: 500, color: "var(--text)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                      {p.title}
                    </span>
                  </div>
                  {p.description && (
                    <p style={{ fontSize: 11, color: "var(--text-3)", marginTop: 4, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                      {p.description}
                    </p>
                  )}
                </div>
                <button
                  onClick={() => deleteMutation.mutate(p.id)}
                  style={{
                    padding: 8, background: "transparent", border: "none",
                    borderRadius: "var(--radius-md)", cursor: "pointer",
                    color: "var(--text-3)", flexShrink: 0,
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.color = "var(--primary)";
                    e.currentTarget.style.background = "rgba(230, 57, 70, 0.1)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.color = "var(--text-3)";
                    e.currentTarget.style.background = "transparent";
                  }}
                >
                  <Trash2 size={15} />
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}