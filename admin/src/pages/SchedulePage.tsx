import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Pencil, Trash2, Calendar, ChevronLeft, ChevronRight } from "lucide-react";
import api from "../lib/api";
import { toast } from "../lib/toast";
import { addDays, longDate, stationDate, stationTime, stationToUtc } from "../lib/stationTime";
import Modal from "../components/Modal";
import ConfirmDialog from "../components/ConfirmDialog";

interface Channel {
  id: string;
  name: string;
  type: "tv" | "radio";
  is_active: boolean;
}

interface Programme {
  id: string;
  channel_id: string;
  title: string;
  description?: string | null;
  starts_at: string;
  ends_at: string;
}

const emptyForm = { title: "", description: "", date: "", start: "", end: "" };

export default function SchedulePage() {
  const qc = useQueryClient();

  // The schedule is planned in the station's timezone, set in Settings.
  const { data: config } = useQuery({
    queryKey: ["app-config"],
    queryFn: async () => (await api.get("/config")).data.data as { timezone?: string },
  });
  const timeZone = config?.timezone || "UTC";

  const [pickedChannel, setPickedChannel] = useState("");
  const [pickedDate, setPickedDate] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Programme | null>(null);
  const [deleting, setDeleting] = useState<Programme | null>(null);
  const [form, setForm] = useState(emptyForm);

  // The current time, refreshed every half minute so "On now" stays right.
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  const channelsQuery = useQuery({
    queryKey: ["channels"],
    queryFn: async () => (await api.get("/admin/channels")).data.data as Channel[],
  });
  const channels = (channelsQuery.data ?? []).filter((c) => c.is_active);

  // Until the user picks, show the first channel and today at the station.
  const channelId = pickedChannel || channels[0]?.id || "";
  const channel = channels.find((c) => c.id === channelId);
  const today = stationDate(new Date(now), timeZone);
  const date = pickedDate || today;

  const programmesQuery = useQuery({
    queryKey: ["schedule", channelId, date],
    queryFn: async () =>
      (await api.get(`/schedule/${channelId}?date=${date}`)).data.data as Programme[],
    enabled: !!channelId,
  });
  const programmes = programmesQuery.data ?? [];

  const close = () => { setShowForm(false); setEditing(null); setForm(emptyForm); };

  const startAdd = () => {
    setEditing(null);
    setForm({ ...emptyForm, date });
    setShowForm(true);
  };

  const startEdit = (p: Programme) => {
    setEditing(p);
    setForm({
      title: p.title,
      description: p.description ?? "",
      date: stationDate(p.starts_at, timeZone),
      start: stationTime(p.starts_at, timeZone),
      end: stationTime(p.ends_at, timeZone),
    });
    setShowForm(true);
  };

  // An end time at or before the start time means it ends the next day.
  const endsNextDay = form.start !== "" && form.end !== "" && form.end <= form.start;

  const saveMutation = useMutation({
    mutationFn: () => {
      const body = {
        title: form.title,
        description: form.description || null,
        starts_at: stationToUtc(form.date, form.start, timeZone).toISOString(),
        ends_at: stationToUtc(endsNextDay ? addDays(form.date, 1) : form.date, form.end, timeZone).toISOString(),
      };
      return editing
        ? api.put(`/admin/schedule/${editing.id}`, body)
        : api.post("/admin/schedule", { ...body, channel_id: channelId });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["schedule"] });
      toast.success(editing ? "Programme saved" : "Programme added");
      close();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/schedule/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["schedule"] });
      toast.success("Programme deleted");
    },
    onSettled: () => setDeleting(null),
  });

  const statusOf = (p: Programme) => {
    if (new Date(p.ends_at).getTime() <= now) return "Ended";
    if (new Date(p.starts_at).getTime() <= now) return "On now";
    return "Upcoming";
  };

  return (
    <div style={{ padding: "28px 32px" }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Schedule</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>
            The programme guide for each channel. Times are in station time ({timeZone}).
          </p>
        </div>
        <button className="btn-primary" onClick={startAdd} disabled={!channelId}>
          <Plus size={16} aria-hidden="true" /> Add programme
        </button>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", alignItems: "flex-end", gap: 12, marginBottom: 16 }}>
        <div style={{ flex: "1 1 220px", maxWidth: 320 }}>
          <label className="label" htmlFor="schedule-channel">Channel</label>
          <select id="schedule-channel" className="input" value={channelId}
            onChange={(e) => setPickedChannel(e.target.value)}>
            {channels.map((c) => (
              <option key={c.id} value={c.id}>{c.name} ({c.type === "tv" ? "TV" : "Radio"})</option>
            ))}
          </select>
        </div>
        <div>
          <label className="label" htmlFor="schedule-date">Day</label>
          <div style={{ display: "flex", gap: 4 }}>
            <button className="icon-btn" aria-label="Previous day" onClick={() => setPickedDate(addDays(date, -1))}>
              <ChevronLeft size={18} aria-hidden="true" />
            </button>
            <input id="schedule-date" className="input" type="date" value={date} style={{ width: 170 }}
              onChange={(e) => setPickedDate(e.target.value)} />
            <button className="icon-btn" aria-label="Next day" onClick={() => setPickedDate(addDays(date, 1))}>
              <ChevronRight size={18} aria-hidden="true" />
            </button>
          </div>
        </div>
        <button className="btn-ghost" onClick={() => setPickedDate("")} disabled={date === today}>Today</button>
      </div>

      <h2 style={{ fontSize: 15, fontWeight: 600, margin: "0 0 12px", color: "var(--text-2)" }}>
        {channel ? `${channel.name} · ` : ""}{longDate(date)}
      </h2>

      {channelsQuery.isLoading || (programmesQuery.isLoading && !!channelId) ? (
        <div style={{ display: "flex", justifyContent: "center", padding: 48 }}>
          <span className="spinner" style={{ width: 28, height: 28 }} />
        </div>
      ) : channelsQuery.isError || programmesQuery.isError ? (
        <div className="empty-state">
          <Calendar size={40} aria-hidden="true" />
          <p>Could not load the schedule.</p>
          <button className="btn-ghost" style={{ marginTop: 16 }}
            onClick={() => { channelsQuery.refetch(); programmesQuery.refetch(); }}>
            Try again
          </button>
        </div>
      ) : channels.length === 0 ? (
        <div className="empty-state"><Calendar size={40} aria-hidden="true" /><p>Add a channel first, then build its schedule here.</p></div>
      ) : programmes.length === 0 ? (
        <div className="empty-state"><Calendar size={40} aria-hidden="true" /><p>Nothing is scheduled for this day.</p></div>
      ) : (
        <div className="card" style={{ overflowX: "auto" }}>
          <table className="table" style={{ minWidth: 640 }}>
            <thead>
              <tr>
                <th style={{ width: 140 }}>Time</th>
                <th>Programme</th>
                <th style={{ width: 150 }}>Status</th>
                <th style={{ width: 100 }}><span style={{ position: "absolute", left: -9999 }}>Actions</span></th>
              </tr>
            </thead>
            <tbody>
              {programmes.map((p, i) => {
                const status = statusOf(p);
                const previous = programmes[i - 1];
                const overlaps = previous !== undefined
                  && new Date(p.starts_at).getTime() < new Date(previous.ends_at).getTime();
                return (
                  <tr key={p.id}>
                    <td style={{ fontVariantNumeric: "tabular-nums", fontWeight: 600, whiteSpace: "nowrap" }}>
                      {stationTime(p.starts_at, timeZone)} – {stationTime(p.ends_at, timeZone)}
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{p.title}</div>
                      {p.description && <div style={{ fontSize: 13, color: "var(--text-3)" }}>{p.description}</div>}
                      {overlaps && (
                        <div style={{ fontSize: 13, color: "var(--danger)", marginTop: 2 }}>
                          Starts before the previous programme ends.
                        </div>
                      )}
                    </td>
                    <td>
                      <span className={`badge ${status === "On now" ? "badge-red" : "badge-gray"}`}>{status}</span>
                    </td>
                    <td>
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <button className="icon-btn" aria-label={`Edit ${p.title}`} title="Edit" onClick={() => startEdit(p)}>
                          <Pencil size={16} aria-hidden="true" />
                        </button>
                        <button className="icon-btn" aria-label={`Delete ${p.title}`} title="Delete" onClick={() => setDeleting(p)}>
                          <Trash2 size={16} aria-hidden="true" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {showForm && (
        <Modal title={editing ? "Edit programme" : `Add programme to ${channel?.name ?? "channel"}`} onClose={close} width={520}>
          <form onSubmit={(e) => { e.preventDefault(); saveMutation.mutate(); }}>
            <div className="form-group">
              <label className="label" htmlFor="prog-title">Title</label>
              <input id="prog-title" className="input" value={form.title} required minLength={2}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} />
            </div>
            <div className="form-group">
              <label className="label" htmlFor="prog-description">Description</label>
              <textarea id="prog-description" className="input" rows={2} style={{ resize: "vertical" }}
                value={form.description}
                onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
            </div>
            <div className="form-group">
              <label className="label" htmlFor="prog-date">Day</label>
              <input id="prog-date" className="input" type="date" required value={form.date}
                onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))} />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label className="label" htmlFor="prog-start">Starts</label>
                <input id="prog-start" className="input" type="time" required value={form.start}
                  onChange={(e) => setForm((f) => ({ ...f, start: e.target.value }))} />
              </div>
              <div className="form-group">
                <label className="label" htmlFor="prog-end">Ends</label>
                <input id="prog-end" className="input" type="time" required value={form.end}
                  onChange={(e) => setForm((f) => ({ ...f, end: e.target.value }))} />
              </div>
            </div>
            <p style={{ fontSize: 13, color: "var(--text-3)", margin: "0 0 20px" }}>
              Times are in station time ({timeZone}).
              {endsNextDay && " This programme ends the next day."}
            </p>
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, flexWrap: "wrap" }}>
              <button type="button" className="btn-ghost" onClick={close}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saveMutation.isPending}>
                {saveMutation.isPending ? <span className="spinner" /> : (editing ? "Save" : "Add programme")}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {deleting && (
        <ConfirmDialog
          title="Delete programme?"
          message={`"${deleting.title}" will be removed from the guide. This cannot be undone.`}
          confirmLabel="Delete"
          busy={deleteMutation.isPending}
          onConfirm={() => deleteMutation.mutate(deleting.id)}
          onCancel={() => setDeleting(null)}
        />
      )}
    </div>
  );
}
