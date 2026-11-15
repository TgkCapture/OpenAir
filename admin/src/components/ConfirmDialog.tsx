import Modal from "./Modal";

interface ConfirmDialogProps {
  title: string;
  message: string;
  /** The label of the button that goes ahead, for example "Delete". */
  confirmLabel: string;
  busy?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

/** Asks the user to confirm an action that cannot be undone. */
export default function ConfirmDialog({
  title, message, confirmLabel, busy = false, onConfirm, onCancel,
}: ConfirmDialogProps) {
  return (
    <Modal title={title} onClose={onCancel} width={420}>
      <p style={{ margin: "0 0 24px", color: "var(--text-2)" }}>{message}</p>
      <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, flexWrap: "wrap" }}>
        <button type="button" className="btn-ghost" onClick={onCancel}>Cancel</button>
        <button
          type="button"
          className="btn-primary"
          style={{ background: "var(--danger)", color: "var(--bg-card)" }}
          disabled={busy}
          onClick={onConfirm}
        >
          {busy ? <span className="spinner" /> : confirmLabel}
        </button>
      </div>
    </Modal>
  );
}
