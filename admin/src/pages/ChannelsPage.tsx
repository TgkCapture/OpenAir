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
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-semibold">Channels</h1>
        <button
          onClick={() => { setEditing(null); setForm(empty); setShowForm(true); }}
          className="flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg text-sm hover:bg-red-600 transition-colors"
        >
          <Plus size={16} /> Add Channel
        </button>
      </div>

      <div className="flex gap-2 mb-6">
        {(["all", "tv", "radio"] as const).map(f => (
          <button key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
              filter === f
                ? "bg-primary text-white"
                : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
            }`}
          >
            {f === "all" ? "All" : f === "tv" ? "TV" : "Radio"}
          </button>
        ))}
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-surface rounded-xl p-6 w-full max-w-md">
            <h2 className="text-lg font-semibold mb-4">
              {editing ? "Edit Channel" : "Add Channel"}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-3">
              <div>
                <label className="block text-sm font-medium mb-1">Name *</label>
                <input type="text" value={form.name} required
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Type</label>
                <select value={form.type}
                  onChange={e => setForm(f => ({ ...f, type: e.target.value }))}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm">
                  <option value="tv">TV</option>
                  <option value="radio">Radio</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Stream URL *</label>
                <input type="url" value={form.stream_url} required
                  onChange={e => setForm(f => ({ ...f, stream_url: e.target.value }))}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Logo URL</label>
                <input type="url" value={form.logo_url}
                  onChange={e => setForm(f => ({ ...f, logo_url: e.target.value }))}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Sort Order</label>
                <input type="number" value={form.sort_order}
                  onChange={e => setForm(f => ({ ...f, sort_order: e.target.value }))}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm" />
              </div>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" checked={form.is_premium}
                    onChange={e => setForm(f => ({ ...f, is_premium: e.target.checked }))} />
                  Premium
                </label>
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" checked={form.is_active}
                    onChange={e => setForm(f => ({ ...f, is_active: e.target.checked }))} />
                  Active
                </label>
              </div>
              <div className="flex gap-3 pt-2">
                <button type="submit"
                  className="flex-1 bg-primary text-white py-2 rounded-lg text-sm font-medium hover:bg-red-600">
                  {editing ? "Save" : "Add Channel"}
                </button>
                <button type="button"
                  onClick={() => { setShowForm(false); setEditing(null); }}
                  className="flex-1 border border-gray-300 dark:border-gray-700 py-2 rounded-lg text-sm">
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 text-gray-500">
          <Tv size={48} className="mx-auto mb-4 opacity-40" />
          <p>No channels yet.</p>
        </div>
      ) : (
        <div className="grid gap-3">
          {filtered.map(ch => (
            <div key={ch.id}
              className="flex items-center gap-4 bg-white dark:bg-surface rounded-xl p-4 border border-gray-200 dark:border-gray-800">
              <div className="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex items-center justify-center flex-shrink-0">
                {ch.type === "tv" ? <Tv size={20} className="text-gray-500" /> : <Radio size={20} className="text-gray-500" />}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-medium text-sm">{ch.name}</span>
                  <span className={`text-xs px-2 py-0.5 rounded uppercase font-medium ${ch.type === 'tv' ? 'bg-blue-100 text-blue-700' : 'bg-green-100 text-green-700'}`}>
                    {ch.type}
                  </span>
                  {ch.is_premium && <span className="bg-primary text-white text-xs px-2 py-0.5 rounded">PRO</span>}
                </div>
                <p className="text-xs text-gray-500 truncate mt-0.5">{ch.stream_url}</p>
              </div>
              <div className="flex items-center gap-1 flex-shrink-0">
                {ch.is_active
                  ? <CheckCircle size={16} className="text-green-500" />
                  : <XCircle size={16} className="text-gray-400" />}
                <button
                  onClick={() => toggleMutation.mutate({ id: ch.id, isPremium: !ch.is_premium })}
                  className="p-2 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                  title={ch.is_premium ? "Set Free" : "Set Premium"}>
                  {ch.is_premium ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
                <button onClick={() => startEdit(ch)}
                  className="p-2 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors">
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