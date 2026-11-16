import { useMemo, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Pencil, Tv, Radio, Lock, LockOpen, Power, Search } from "lucide-react";
import api from "../lib/api";
import { toast } from "../lib/toast";
import FilePicker from "../components/FilePicker";
import Modal from "../components/Modal";

interface Channel {
  id: string; name: string; type: "tv" | "radio";
  stream_url: string; logo_url?: string | null; description?: string | null;
  is_premium: boolean; is_active: boolean; sort_order: number;
}

type Filter = "all" | "tv" | "radio" | "inactive";

const FILTERS: { key: Filter; label: string }[] = [
  { key: "all", label: "All" },
  { key: "tv", label: "TV" },
  { key: "radio", label: "Radio" },
  { key: "inactive", label: "Inactive" },
];

const empty = { name: "", type: "tv", stream_url: "", logo_url: "", description: "", is_premium: false, is_active: true, sort_order: "0" };

/** The body the update endpoint expects, built from a channel as stored. */
function updateBody(ch: Channel, changes: Partial<Channel>) {
  return {
    name: ch.name,
    stream_url: ch.stream_url,
    logo_url: ch.logo_url ?? null,
    description: ch.description ?? null,
    is_premium: ch.is_premium,
    is_active: ch.is_active,
    sort_order: ch.sort_order,
    ...changes,
  };
}

export default function ChannelsPage() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Channel | null>(null);
  const [form, setForm] = useState<typeof empty>(empty);
  const [filter, setFilter] = useState<Filter>("all");
  const [search, setSearch] = useState("");

  const { data: channels = [], isLoading, isError, refetch } = useQuery({
    queryKey: ["channels"],
    queryFn: async () => (await api.get("/admin/channels")).data.data as Channel[],
  });

  const visible = useMemo(() => {
    const needle = search.trim().toLowerCase();
    return channels.filter((ch) => {
      if (filter === "tv" && ch.type !== "tv") return false;
      if (filter === "radio" && ch.type !== "radio") return false;
      if (filter === "inactive" && ch.is_active) return false;
      return !needle || ch.name.toLowerCase().includes(needle);
    });
  }, [channels, filter, search]);

  const close = () => { setShowForm(false); setEditing(null); setForm(empty); };

  const saveMutation = useMutation({
    mutationFn: (data: object) =>
      editing ? api.put(`/admin/channels/${editing.id}`, data) : api.post("/admin/channels", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["channels"] });
      toast.success(editing ? "Channel saved" : "Channel added");
      close();
    },
  });

  const accessMutation = useMutation({
    mutationFn: ({ id, isPremium }: { id: string; isPremium: boolean }) =>
      api.patch(`/admin/channels/${id}/access`, { is_premium: isPremium }),
    onSuccess: (_, { isPremium }) => {
      qc.invalidateQueries({ queryKey: ["channels"] });
      toast.success(isPremium ? "Channel is now premium" : "Channel is now free");
    },
  });

  const activeMutation = useMutation({
    mutationFn: (ch: Channel) =>
      api.put(`/admin/channels/${ch.id}`, updateBody(ch, { is_active: !ch.is_active })),
    onSuccess: (_, ch) => {
      qc.invalidateQueries({ queryKey: ["channels"] });
      toast.success(ch.is_active ? "Channel deactivated" : "Channel activated");
    },
  });

  const startEdit = (ch: Channel) => {
    setEditing(ch);
    setForm({ name: ch.name, type: ch.type, stream_url: ch.stream_url, logo_url: ch.logo_url ?? "", description: ch.description ?? "", is_premium: ch.is_premium, is_active: ch.is_active, sort_order: ch.sort_order.toString() });
    setShowForm(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    saveMutation.mutate({
      ...form,
      sort_order: parseInt(form.sort_order) || 0,
      logo_url: form.logo_url || null,
      description: form.description || null,
    });
  };

  return (
    <div style={{ padding: "28px 32px" }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Channels</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>Live TV and radio streams shown in the app.</p>
        </div>
        <button className="btn-primary" onClick={() => setShowForm(true)}>
          <Plus size={16} aria-hidden="true" /> Add channel
        </button>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <div className="search-wrap" style={{ flex: "1 1 240px", maxWidth: 360 }}>
          <Search size={16} aria-hidden="true" />
          <input className="input" type="search" aria-label="Search channels" placeholder="Search by name"
            value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <div role="group" aria-label="Filter channels" style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {FILTERS.map(({ key, label }) => (
            <button key={key} className="btn-ghost" aria-pressed={filter === key} onClick={() => setFilter(key)}
              style={{
                borderRadius: 20,
                ...(filter === key
                  ? { background: "var(--emphasis)", color: "var(--on-emphasis)", borderColor: "var(--emphasis)" }
                  : {}),
              }}>
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
          <Tv size={40} aria-hidden="true" />
          <p>Could not load channels.</p>
          <button className="btn-ghost" style={{ marginTop: 16 }} onClick={() => refetch()}>Try again</button>
        </div>
      ) : channels.length === 0 ? (
        <div className="empty-state"><Tv size={40} aria-hidden="true" /><p>No channels yet. Add the first one.</p></div>
      ) : visible.length === 0 ? (
        <div className="empty-state"><Search size={40} aria-hidden="true" /><p>No channels match your search or filter.</p></div>
      ) : (
        <div className="card" style={{ overflowX: "auto" }}>
          <table className="table" style={{ minWidth: 760 }}>
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Stream</th>
                <th>Access</th>
                <th>Status</th>
                <th>Order</th>
                <th><span style={{ position: "absolute", left: -9999 }}>Actions</span></th>
              </tr>
            </thead>
            <tbody>
              {visible.map((ch) => (
                <tr key={ch.id}>
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                      <div style={{ width: 36, height: 36, borderRadius: 8, background: "var(--bg-surface)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, overflow: "hidden" }}>
                        {ch.logo_url
                          ? <img src={ch.logo_url} style={{ width: "100%", height: "100%", objectFit: "cover" }} alt="" />
                          : (ch.type === "tv"
                            ? <Tv size={16} aria-hidden="true" style={{ color: "var(--text-3)" }} />
                            : <Radio size={16} aria-hidden="true" style={{ color: "var(--text-3)" }} />)}
                      </div>
                      <span style={{ fontWeight: 600 }}>{ch.name}</span>
                    </div>
                  </td>
                  <td style={{ color: "var(--text-2)" }}>{ch.type === "tv" ? "TV" : "Radio"}</td>
                  <td style={{ color: "var(--text-3)", maxWidth: 260 }}>
                    <span title={ch.stream_url} style={{ display: "block", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", fontSize: 13 }}>
                      {ch.stream_url}
                    </span>
                  </td>
                  <td>
                    <span className={`badge ${ch.is_premium ? "badge-red" : "badge-gray"}`}>
                      {ch.is_premium ? "Premium" : "Free"}
                    </span>
                  </td>
                  <td>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 8, fontWeight: ch.is_active ? 600 : 400, color: ch.is_active ? "var(--text)" : "var(--text-3)" }}>
                      <span aria-hidden="true" style={{
                        width: 8, height: 8, borderRadius: 4, boxSizing: "border-box",
                        ...(ch.is_active ? { background: "var(--success)" } : { border: "2px solid var(--text-3)" }),
                      }} />
                      {ch.is_active ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td style={{ color: "var(--text-2)" }}>{ch.sort_order}</td>
                  <td>
                    <div style={{ display: "flex", justifyContent: "flex-end" }}>
                      <button className="icon-btn"
                        aria-label={ch.is_premium ? `Make ${ch.name} free` : `Make ${ch.name} premium`}
                        title={ch.is_premium ? "Make free" : "Make premium"}
                        disabled={accessMutation.isPending}
                        onClick={() => accessMutation.mutate({ id: ch.id, isPremium: !ch.is_premium })}>
                        {ch.is_premium ? <LockOpen size={16} aria-hidden="true" /> : <Lock size={16} aria-hidden="true" />}
                      </button>
                      <button className="icon-btn"
                        aria-label={ch.is_active ? `Deactivate ${ch.name}` : `Activate ${ch.name}`}
                        title={ch.is_active ? "Deactivate" : "Activate"}
                        disabled={activeMutation.isPending}
                        onClick={() => activeMutation.mutate(ch)}>
                        <Power size={16} aria-hidden="true" />
                      </button>
                      <button className="icon-btn" aria-label={`Edit ${ch.name}`} title="Edit" onClick={() => startEdit(ch)}>
                        <Pencil size={16} aria-hidden="true" />
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
        <Modal title={editing ? "Edit channel" : "Add channel"} onClose={close} width={520}>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="label" htmlFor="ch-name">Name</label>
              <input id="ch-name" className="input" value={form.name} required minLength={2}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
            </div>
            {!editing && (
              <div className="form-group">
                <label className="label" htmlFor="ch-type">Type</label>
                <select id="ch-type" className="input" value={form.type}
                  onChange={e => setForm(f => ({ ...f, type: e.target.value }))}>
                  <option value="tv">TV</option>
                  <option value="radio">Radio</option>
                </select>
              </div>
            )}
            <div className="form-group">
              <label className="label" htmlFor="ch-stream">Stream URL</label>
              <input id="ch-stream" className="input" type="url" value={form.stream_url} required
                placeholder="https://example.com/live/stream.m3u8"
                onChange={e => setForm(f => ({ ...f, stream_url: e.target.value }))} />
            </div>
            <div className="form-group">
              <label className="label" htmlFor="ch-description">Description</label>
              <textarea id="ch-description" className="input" value={form.description} rows={2} style={{ resize: "vertical" }}
                onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <FilePicker label="Logo" value={form.logo_url}
              onChange={url => setForm(f => ({ ...f, logo_url: url }))}
              accept="image/*" placeholder="Paste a logo URL or upload" />
            <div className="form-group" style={{ maxWidth: 160 }}>
              <label className="label" htmlFor="ch-order">Sort order</label>
              <input id="ch-order" className="input" type="number" value={form.sort_order}
                onChange={e => setForm(f => ({ ...f, sort_order: e.target.value }))} />
            </div>
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
                  <input type="checkbox" checked={form.is_active}
                    onChange={e => setForm(f => ({ ...f, is_active: e.target.checked }))} />
                  <span className="toggle-slider" />
                </span>
                Active
              </label>
            </div>
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, flexWrap: "wrap" }}>
              <button type="button" className="btn-ghost" onClick={close}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saveMutation.isPending}>
                {saveMutation.isPending ? <span className="spinner" /> : (editing ? "Save" : "Add channel")}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
