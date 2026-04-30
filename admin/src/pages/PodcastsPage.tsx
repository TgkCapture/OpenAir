import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Mic, ChevronRight, ChevronLeft, X } from "lucide-react";
import api from "../lib/api";
import FilePicker from "../components/FilePicker";

interface Podcast {
  id: string; title: string; description?: string;
  artwork_url?: string; author?: string; category?: string;
  is_premium: boolean; is_active: boolean;
}
interface Episode {
  id: string; title: string; audio_url: string;
  duration_secs?: number; episode_number?: number; is_premium: boolean;
}

export default function PodcastsPage() {
  const qc = useQueryClient();
  const [selected, setSelected] = useState<Podcast | null>(null);
  const [showPodForm, setShowPodForm] = useState(false);
  const [showEpForm, setShowEpForm] = useState(false);
  const [podForm, setPodForm] = useState({ title: "", description: "", artwork_url: "", author: "", category: "", is_premium: false });
  const [epForm, setEpForm] = useState({ title: "", audio_url: "", duration_secs: "", episode_number: "", is_premium: false });

  const { data: podcasts = [], isLoading } = useQuery({
    queryKey: ["podcasts-admin"],
    queryFn: async () => (await api.get("/podcasts")).data.data as Podcast[],
  });

  const { data: episodes = [] } = useQuery({
    queryKey: ["episodes-admin", selected?.id],
    queryFn: async () => (await api.get(`/podcasts/${selected!.id}/episodes`)).data.data as Episode[],
    enabled: !!selected,
  });

  const createPodcast = useMutation({
    mutationFn: (data: object) => api.post("/admin/podcasts", data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["podcasts-admin"] }); setShowPodForm(false); setPodForm({ title: "", description: "", artwork_url: "", author: "", category: "", is_premium: false }); },
  });

  const createEpisode = useMutation({
    mutationFn: (data: object) => api.post("/admin/podcasts/episodes", data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["episodes-admin", selected?.id] }); setShowEpForm(false); setEpForm({ title: "", audio_url: "", duration_secs: "", episode_number: "", is_premium: false }); },
  });

  return (
    <div style={{ padding: "32px" }}>
      <div className="page-header">
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          {selected && (
            <button onClick={() => setSelected(null)}
              style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-2)", padding: 4 }}>
              <ChevronLeft size={18} />
            </button>
          )}
          <h1 className="page-title">{selected ? selected.title : "Podcasts"}</h1>
        </div>
        <button className="btn-primary"
          onClick={() => selected ? setShowEpForm(true) : setShowPodForm(true)}>
          <Plus size={14} /> {selected ? "Add Episode" : "Add Podcast"}
        </button>
      </div>

      {/* Podcast form */}
      {showPodForm && (
        <div className="modal-overlay">
          <div className="modal">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
              <h2 className="modal-title" style={{ margin: 0 }}>Add Podcast</h2>
              <button onClick={() => setShowPodForm(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-3)" }}><X size={18} /></button>
            </div>
            <form onSubmit={e => { e.preventDefault(); createPodcast.mutate({ ...podForm, description: podForm.description || null, artwork_url: podForm.artwork_url || null, author: podForm.author || null, category: podForm.category || null }); }}>
              <div className="form-group">
                <label className="label">Title *</label>
                <input className="input" value={podForm.title} required onChange={e => setPodForm(f => ({ ...f, title: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label">Author</label>
                <input className="input" value={podForm.author} onChange={e => setPodForm(f => ({ ...f, author: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label">Category</label>
                <input className="input" value={podForm.category} onChange={e => setPodForm(f => ({ ...f, category: e.target.value }))} />
              </div>
              <FilePicker label="Artwork" value={podForm.artwork_url} onChange={url => setPodForm(f => ({ ...f, artwork_url: url }))} accept="image/*" placeholder="Paste image URL or upload" />
              <div className="form-group">
                <label className="label">Description</label>
                <textarea className="input" value={podForm.description} rows={2} style={{ resize: "none" }} onChange={e => setPodForm(f => ({ ...f, description: e.target.value }))} />
              </div>
              <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
                <button type="submit" className="btn-primary" style={{ flex: 1, justifyContent: "center" }} disabled={createPodcast.isPending}>
                  {createPodcast.isPending ? <span className="spinner" /> : "Create Podcast"}
                </button>
                <button type="button" className="btn-ghost" onClick={() => setShowPodForm(false)}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Episode form */}
      {showEpForm && (
        <div className="modal-overlay">
          <div className="modal">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
              <h2 className="modal-title" style={{ margin: 0 }}>Add Episode</h2>
              <button onClick={() => setShowEpForm(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-3)" }}><X size={18} /></button>
            </div>
            <form onSubmit={e => { e.preventDefault(); createEpisode.mutate({ podcast_id: selected!.id, ...epForm, duration_secs: epForm.duration_secs ? parseInt(epForm.duration_secs) : null, episode_number: epForm.episode_number ? parseInt(epForm.episode_number) : null }); }}>
              <div className="form-group">
                <label className="label">Title *</label>
                <input className="input" value={epForm.title} required onChange={e => setEpForm(f => ({ ...f, title: e.target.value }))} />
              </div>
              <FilePicker label="Audio File *" value={epForm.audio_url} onChange={url => setEpForm(f => ({ ...f, audio_url: url }))} accept="audio/*" placeholder="Paste audio URL or upload MP3" />
              <div className="form-row">
                <div className="form-group">
                  <label className="label">Episode #</label>
                  <input className="input" type="number" value={epForm.episode_number} onChange={e => setEpForm(f => ({ ...f, episode_number: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label className="label">Duration (secs)</label>
                  <input className="input" type="number" value={epForm.duration_secs} onChange={e => setEpForm(f => ({ ...f, duration_secs: e.target.value }))} />
                </div>
              </div>
              <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
                <button type="submit" className="btn-primary" style={{ flex: 1, justifyContent: "center" }} disabled={createEpisode.isPending}>
                  {createEpisode.isPending ? <span className="spinner" /> : "Add Episode"}
                </button>
                <button type="button" className="btn-ghost" onClick={() => setShowEpForm(false)}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Podcast list */}
      {!selected && (
        isLoading ? (
          <div style={{ display: "flex", justifyContent: "center", padding: 48 }}><span className="spinner" style={{ width: 28, height: 28 }} /></div>
        ) : podcasts.length === 0 ? (
          <div className="empty-state"><Mic size={40} /><p>No podcasts yet.</p></div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {podcasts.map(p => (
              <div key={p.id} className="card" style={{ display: "flex", alignItems: "center", gap: 14, padding: "14px 16px", cursor: "pointer" }}
                onClick={() => setSelected(p)}>
                <div style={{ width: 44, height: 44, borderRadius: 8, background: "var(--bg)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, overflow: "hidden" }}>
                  {p.artwork_url ? <img src={p.artwork_url} style={{ width: "100%", height: "100%", objectFit: "cover" }} alt="" /> : <Mic size={18} style={{ color: "var(--text-3)" }} />}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{p.title}</span>
                    {p.is_premium && <span className="badge badge-red">PRO</span>}
                  </div>
                  {p.author && <p style={{ fontSize: 11, color: "var(--text-3)", margin: "2px 0 0" }}>{p.author}</p>}
                </div>
                <ChevronRight size={16} style={{ color: "var(--text-3)", flexShrink: 0 }} />
              </div>
            ))}
          </div>
        )
      )}

      {/* Episode list */}
      {selected && (
        episodes.length === 0 ? (
          <div className="empty-state"><Mic size={40} /><p>No episodes yet. Add the first one.</p></div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {episodes.map((ep, i) => (
              <div key={ep.id} className="card" style={{ display: "flex", alignItems: "center", gap: 14, padding: "12px 16px" }}>
                <div style={{ width: 28, height: 28, borderRadius: 6, background: "var(--primary-soft)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontSize: 11, fontWeight: 700, color: "var(--primary)" }}>
                  {ep.episode_number ?? i + 1}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{ep.title}</span>
                    {ep.is_premium && <span className="badge badge-red">PRO</span>}
                  </div>
                  {ep.duration_secs && <p style={{ fontSize: 11, color: "var(--text-3)", margin: "1px 0 0" }}>{Math.floor(ep.duration_secs / 60)}m {ep.duration_secs % 60}s</p>}
                </div>
              </div>
            ))}
          </div>
        )
      )}
    </div>
  );
}