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
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-semibold">VOD Management</h1>
        <button
          onClick={() => { setEditing(null); setForm(empty); setShowForm(true); }}
          className="flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg text-sm hover:bg-red-600 transition-colors"
        >
          <Plus size={16} /> Add Video
        </button>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-surface rounded-xl p-6 w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <h2 className="text-lg font-semibold mb-4">
              {editing ? "Edit Video" : "Add New Video"}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-3">
              {[
                { label: "Title *", key: "title", type: "text" },
                { label: "File URL *", key: "file_url", type: "url" },
                { label: "Thumbnail URL", key: "thumbnail_url", type: "url" },
                { label: "Category", key: "category", type: "text" },
                { label: "Duration (seconds)", key: "duration_secs", type: "number" },
              ].map(({ label, key, type }) => (
                <div key={key}>
                  <label className="block text-sm font-medium mb-1">{label}</label>
                  <input
                    type={type}
                    value={(form as unknown as Record<string, string>)[key]}
                    onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                    className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm"
                    required={label.includes("*")}
                  />
                </div>
              ))}
              <div>
                <label className="block text-sm font-medium mb-1">Description</label>
                <textarea
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  rows={3}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Type</label>
                <select
                  value={form.type}
                  onChange={e => setForm(f => ({ ...f, type: e.target.value }))}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-background text-sm"
                >
                  <option value="vod">VOD</option>
                  <option value="promo">Promo</option>
                  <option value="highlight">Highlight</option>
                </select>
              </div>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" checked={form.is_premium}
                    onChange={e => setForm(f => ({ ...f, is_premium: e.target.checked }))} />
                  Premium
                </label>
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" checked={form.is_published}
                    onChange={e => setForm(f => ({ ...f, is_published: e.target.checked }))} />
                  Published
                </label>
              </div>
              <div className="flex gap-3 pt-2">
                <button type="submit"
                  className="flex-1 bg-primary text-white py-2 rounded-lg text-sm font-medium hover:bg-red-600">
                  {editing ? "Save Changes" : "Add Video"}
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
      ) : items.length === 0 ? (
        <div className="text-center py-16 text-gray-500">
          <Film size={48} className="mx-auto mb-4 opacity-40" />
          <p>No videos yet. Add your first video.</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {items.map(item => (
            <div key={item.id}
              className="flex items-center gap-4 bg-white dark:bg-surface rounded-xl p-4 border border-gray-200 dark:border-gray-800">
              <div className="w-16 h-12 rounded-lg bg-gray-100 dark:bg-gray-800 flex items-center justify-center flex-shrink-0 overflow-hidden">
                {item.thumbnail_url
                  ? <img src={item.thumbnail_url} alt="" className="w-full h-full object-cover rounded-lg" />
                  : <Film size={24} className="text-gray-400" />}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-medium text-sm truncate">{item.title}</span>
                  {item.is_premium && (
                    <span className="bg-primary text-white text-xs px-2 py-0.5 rounded">PRO</span>
                  )}
                  {!item.is_published && (
                    <span className="bg-gray-200 dark:bg-gray-700 text-xs px-2 py-0.5 rounded">Draft</span>
                  )}
                </div>
                <div className="text-xs text-gray-500 mt-1">
                  {item.category && <span className="mr-2">{item.category}</span>}
                  <span>{item.view_count} views</span>
                </div>
              </div>
              <div className="flex items-center gap-2 flex-shrink-0">
                <button
                  onClick={() => toggleMutation.mutate({ id: item.id, isPremium: !item.is_premium })}
                  className={`p-2 rounded-lg transition-colors ${item.is_premium ? 'text-primary hover:bg-red-50 dark:hover:bg-red-900/20' : 'text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'}`}
                  title={item.is_premium ? "Set Free" : "Set Premium"}
                >
                  {item.is_premium ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
                <button onClick={() => startEdit(item)}
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