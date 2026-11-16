import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Mic, ChevronRight, ArrowLeft, Trash2 } from "lucide-react";
import api from "../lib/api";
import { toast } from "../lib/toast";
import FilePicker from "../components/FilePicker";
import Modal from "../components/Modal";
import ConfirmDialog from "../components/ConfirmDialog";

interface Podcast {
  id: string; title: string; description?: string;
  artwork_url?: string; author?: string; category?: string;
  is_premium: boolean; is_active: boolean;
}
interface Episode {
  id: string; title: string; audio_url: string;
  duration_secs?: number; episode_number?: number; is_premium: boolean;
}

const emptyPodcast = { title: "", description: "", artwork_url: "", author: "", category: "", is_premium: false };
const emptyEpisode = { title: "", audio_url: "", duration_secs: "", episode_number: "", is_premium: false };

function formatLength(secs?: number): string {
  if (!secs) return "";
  const m = Math.floor(secs / 60);
  return `${m}:${String(secs % 60).padStart(2, "0")}`;
}

const actionsHeader = <th><span style={{ position: "absolute", left: -9999 }}>Actions</span></th>;

function AccessBadge({ premium }: { premium: boolean }) {
  return <span className={`badge ${premium ? "badge-red" : "badge-gray"}`}>{premium ? "Premium" : "Free"}</span>;
}

function PremiumToggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <label style={{ display: "flex", alignItems: "center", gap: 10, cursor: "pointer", marginBottom: 20 }}>
      <span className="toggle">
        <input type="checkbox" checked={checked} onChange={e => onChange(e.target.checked)} />
        <span className="toggle-slider" />
      </span>
      Premium
    </label>
  );
}

export default function PodcastsPage() {
  const qc = useQueryClient();
  const [selected, setSelected] = useState<Podcast | null>(null);
  const [showPodForm, setShowPodForm] = useState(false);
  const [showEpForm, setShowEpForm] = useState(false);
  const [podForm, setPodForm] = useState(emptyPodcast);
  const [epForm, setEpForm] = useState(emptyEpisode);
  const [deletingPodcast, setDeletingPodcast] = useState<Podcast | null>(null);
  const [deletingEpisode, setDeletingEpisode] = useState<Episode | null>(null);

  const podcastsQuery = useQuery({
    queryKey: ["podcasts-admin"],
    queryFn: async () => (await api.get("/admin/podcasts")).data.data as Podcast[],
  });
  const podcasts = podcastsQuery.data ?? [];

  const episodesQuery = useQuery({
    queryKey: ["episodes-admin", selected?.id],
    queryFn: async () => (await api.get(`/podcasts/${selected!.id}/episodes`)).data.data as Episode[],
    enabled: !!selected,
  });
  const episodes = episodesQuery.data ?? [];

  const closePodForm = () => { setShowPodForm(false); setPodForm(emptyPodcast); };
  const closeEpForm = () => { setShowEpForm(false); setEpForm(emptyEpisode); };

  const createPodcast = useMutation({
    mutationFn: (data: object) => api.post("/admin/podcasts", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["podcasts-admin"] });
      toast.success("Podcast added");
      closePodForm();
    },
  });

  const createEpisode = useMutation({
    mutationFn: (data: object) => api.post("/admin/podcasts/episodes", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["episodes-admin", selected?.id] });
      toast.success("Episode added");
      closeEpForm();
    },
  });

  const deletePodcast = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/podcasts/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["podcasts-admin"] });
      toast.success("Podcast deleted");
    },
    onSettled: () => setDeletingPodcast(null),
  });

  const deleteEpisode = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/podcasts/episodes/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["episodes-admin", selected?.id] });
      toast.success("Episode deleted");
    },
    onSettled: () => setDeletingEpisode(null),
  });

  const submitPodcast = (e: React.FormEvent) => {
    e.preventDefault();
    createPodcast.mutate({
      ...podForm,
      description: podForm.description || null,
      artwork_url: podForm.artwork_url || null,
      author: podForm.author || null,
      category: podForm.category || null,
    });
  };

  const submitEpisode = (e: React.FormEvent) => {
    e.preventDefault();
    createEpisode.mutate({
      podcast_id: selected!.id,
      ...epForm,
      duration_secs: epForm.duration_secs ? parseInt(epForm.duration_secs) : null,
      episode_number: epForm.episode_number ? parseInt(epForm.episode_number) : null,
    });
  };

  const spinner = (
    <div style={{ display: "flex", justifyContent: "center", padding: 48 }}>
      <span className="spinner" style={{ width: 28, height: 28 }} />
    </div>
  );

  return (
    <div style={{ padding: "28px 32px" }}>
      <div className="page-header">
        <div style={{ display: "flex", alignItems: "center", gap: 8, minWidth: 0 }}>
          {selected && (
            <button className="icon-btn" aria-label="Back to podcasts" onClick={() => setSelected(null)}>
              <ArrowLeft size={18} aria-hidden="true" />
            </button>
          )}
          <div style={{ minWidth: 0 }}>
            <h1 className="page-title">{selected ? selected.title : "Podcasts"}</h1>
            <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>
              {selected ? "Episodes in this podcast." : "Shows and their episodes."}
            </p>
          </div>
        </div>
        <button className="btn-primary" onClick={() => (selected ? setShowEpForm(true) : setShowPodForm(true))}>
          <Plus size={16} aria-hidden="true" /> {selected ? "Add episode" : "Add podcast"}
        </button>
      </div>

      {/* Podcast list */}
      {!selected && (
        podcastsQuery.isLoading ? spinner
        : podcastsQuery.isError ? (
          <div className="empty-state">
            <Mic size={40} aria-hidden="true" />
            <p>Could not load podcasts.</p>
            <button className="btn-ghost" style={{ marginTop: 16 }} onClick={() => podcastsQuery.refetch()}>Try again</button>
          </div>
        ) : podcasts.length === 0 ? (
          <div className="empty-state"><Mic size={40} aria-hidden="true" /><p>No podcasts yet. Add the first one.</p></div>
        ) : (
          <div className="card" style={{ overflowX: "auto" }}>
            <table className="table" style={{ minWidth: 640 }}>
              <thead>
                <tr><th>Title</th><th>Author</th><th>Category</th><th>Access</th><th>Status</th>{actionsHeader}</tr>
              </thead>
              <tbody>
                {podcasts.map(p => (
                  <tr key={p.id}>
                    <td>
                      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                        <div style={{ width: 36, height: 36, borderRadius: 8, background: "var(--bg-surface)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, overflow: "hidden" }}>
                          {p.artwork_url
                            ? <img src={p.artwork_url} style={{ width: "100%", height: "100%", objectFit: "cover" }} alt="" />
                            : <Mic size={16} aria-hidden="true" style={{ color: "var(--text-3)" }} />}
                        </div>
                        <span style={{ fontWeight: 600 }}>{p.title}</span>
                      </div>
                    </td>
                    <td style={{ color: "var(--text-2)" }}>{p.author ?? ""}</td>
                    <td style={{ color: "var(--text-2)" }}>{p.category ?? ""}</td>
                    <td><AccessBadge premium={p.is_premium} /></td>
                    <td style={{ color: p.is_active ? "var(--text)" : "var(--text-3)", fontWeight: p.is_active ? 600 : 400 }}>
                      {p.is_active ? "Active" : "Inactive"}
                    </td>
                    <td>
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <button className="icon-btn" aria-label={`Delete ${p.title}`} title="Delete" onClick={() => setDeletingPodcast(p)}>
                          <Trash2 size={16} aria-hidden="true" />
                        </button>
                        <button className="icon-btn" aria-label={`Open episodes of ${p.title}`} title="Episodes" onClick={() => setSelected(p)}>
                          <ChevronRight size={18} aria-hidden="true" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )
      )}

      {/* Episode list */}
      {selected && (
        episodesQuery.isLoading ? spinner
        : episodesQuery.isError ? (
          <div className="empty-state">
            <Mic size={40} aria-hidden="true" />
            <p>Could not load episodes.</p>
            <button className="btn-ghost" style={{ marginTop: 16 }} onClick={() => episodesQuery.refetch()}>Try again</button>
          </div>
        ) : episodes.length === 0 ? (
          <div className="empty-state"><Mic size={40} aria-hidden="true" /><p>No episodes yet. Add the first one.</p></div>
        ) : (
          <div className="card" style={{ overflowX: "auto" }}>
            <table className="table" style={{ minWidth: 520 }}>
              <thead>
                <tr><th style={{ width: 72 }}>Episode</th><th>Title</th><th>Length</th><th>Access</th>{actionsHeader}</tr>
              </thead>
              <tbody>
                {episodes.map((ep, i) => (
                  <tr key={ep.id}>
                    <td style={{ color: "var(--text-2)" }}>{ep.episode_number ?? i + 1}</td>
                    <td style={{ fontWeight: 600 }}>{ep.title}</td>
                    <td style={{ color: "var(--text-2)" }}>{formatLength(ep.duration_secs)}</td>
                    <td><AccessBadge premium={ep.is_premium} /></td>
                    <td>
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <button className="icon-btn" aria-label={`Delete ${ep.title}`} title="Delete" onClick={() => setDeletingEpisode(ep)}>
                          <Trash2 size={16} aria-hidden="true" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )
      )}

      {showPodForm && (
        <Modal title="Add podcast" onClose={closePodForm} width={520}>
          <form onSubmit={submitPodcast}>
            <div className="form-group">
              <label className="label" htmlFor="pod-title">Title</label>
              <input id="pod-title" className="input" value={podForm.title} required minLength={2}
                onChange={e => setPodForm(f => ({ ...f, title: e.target.value }))} />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label className="label" htmlFor="pod-author">Author</label>
                <input id="pod-author" className="input" value={podForm.author}
                  onChange={e => setPodForm(f => ({ ...f, author: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label" htmlFor="pod-category">Category</label>
                <input id="pod-category" className="input" value={podForm.category}
                  onChange={e => setPodForm(f => ({ ...f, category: e.target.value }))} />
              </div>
            </div>
            <FilePicker label="Artwork" value={podForm.artwork_url}
              onChange={url => setPodForm(f => ({ ...f, artwork_url: url }))}
              accept="image/*" placeholder="Paste an image URL or upload" />
            <div className="form-group">
              <label className="label" htmlFor="pod-description">Description</label>
              <textarea id="pod-description" className="input" value={podForm.description} rows={2} style={{ resize: "vertical" }}
                onChange={e => setPodForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <PremiumToggle checked={podForm.is_premium} onChange={v => setPodForm(f => ({ ...f, is_premium: v }))} />
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, flexWrap: "wrap" }}>
              <button type="button" className="btn-ghost" onClick={closePodForm}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={createPodcast.isPending}>
                {createPodcast.isPending ? <span className="spinner" /> : "Add podcast"}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {showEpForm && (
        <Modal title="Add episode" onClose={closeEpForm} width={520}>
          <form onSubmit={submitEpisode}>
            <div className="form-group">
              <label className="label" htmlFor="ep-title">Title</label>
              <input id="ep-title" className="input" value={epForm.title} required minLength={2}
                onChange={e => setEpForm(f => ({ ...f, title: e.target.value }))} />
            </div>
            <FilePicker label="Audio file" value={epForm.audio_url}
              onChange={url => setEpForm(f => ({ ...f, audio_url: url }))}
              accept="audio/*" placeholder="Paste an audio URL or upload an MP3" />
            <div className="form-row">
              <div className="form-group">
                <label className="label" htmlFor="ep-number">Episode number</label>
                <input id="ep-number" className="input" type="number" min={1} value={epForm.episode_number}
                  onChange={e => setEpForm(f => ({ ...f, episode_number: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label" htmlFor="ep-duration">Length in seconds</label>
                <input id="ep-duration" className="input" type="number" min={0} value={epForm.duration_secs}
                  onChange={e => setEpForm(f => ({ ...f, duration_secs: e.target.value }))} />
              </div>
            </div>
            <PremiumToggle checked={epForm.is_premium} onChange={v => setEpForm(f => ({ ...f, is_premium: v }))} />
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, flexWrap: "wrap" }}>
              <button type="button" className="btn-ghost" onClick={closeEpForm}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={createEpisode.isPending || !epForm.audio_url}>
                {createEpisode.isPending ? <span className="spinner" /> : "Add episode"}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {deletingPodcast && (
        <ConfirmDialog
          title="Delete podcast?"
          message={`"${deletingPodcast.title}" and all of its episodes will be removed for everyone. This cannot be undone.`}
          confirmLabel="Delete"
          busy={deletePodcast.isPending}
          onConfirm={() => deletePodcast.mutate(deletingPodcast.id)}
          onCancel={() => setDeletingPodcast(null)}
        />
      )}

      {deletingEpisode && (
        <ConfirmDialog
          title="Delete episode?"
          message={`"${deletingEpisode.title}" will be removed for everyone. This cannot be undone.`}
          confirmLabel="Delete"
          busy={deleteEpisode.isPending}
          onConfirm={() => deleteEpisode.mutate(deletingEpisode.id)}
          onCancel={() => setDeletingEpisode(null)}
        />
      )}
    </div>
  );
}
