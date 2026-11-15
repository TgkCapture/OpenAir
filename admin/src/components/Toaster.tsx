import { AlertCircle, CheckCircle2, X } from "lucide-react";
import { useToastStore } from "../lib/toast";

/** Renders the messages raised with `toast.success` and `toast.error`. */
export default function Toaster() {
  const { toasts, dismiss } = useToastStore();

  return (
    <div className="toaster" role="status" aria-live="polite">
      {toasts.map((t) => (
        <div key={t.id} className="toast">
          {t.kind === "error" ? <AlertCircle size={18} aria-hidden="true" /> : <CheckCircle2 size={18} aria-hidden="true" />}
          <span className="toast-message">
            {t.kind === "error" && <span style={{ position: "absolute", left: -9999 }}>Error: </span>}
            {t.message}
          </span>
          <button className="toast-close" aria-label="Dismiss" onClick={() => dismiss(t.id)}>
            <X size={16} aria-hidden="true" />
          </button>
        </div>
      ))}
    </div>
  );
}
