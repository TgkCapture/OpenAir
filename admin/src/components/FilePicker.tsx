import { useId, useRef, useState } from "react";
import { Upload, X } from "lucide-react";
import { uploadFile } from "../lib/upload";
import { errorMessage } from "../lib/toast";

interface FilePickerProps {
  label: string;
  value: string;
  onChange: (url: string) => void;
  accept?: string;
  placeholder?: string;
}

/** A field that takes a file by URL, by upload, or by drag and drop. */
export default function FilePicker({
  label, value, onChange, accept = "*/*", placeholder = "Paste a URL or upload a file",
}: FilePickerProps) {
  const inputId = useId();
  const fileRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState("");

  const handleFile = async (file: File) => {
    setUploading(true);
    setError("");
    setProgress(0);
    try {
      onChange(await uploadFile(file, setProgress));
    } catch (err) {
      // The server says why: too large, wrong type, and so on.
      setError(errorMessage(err));
    } finally {
      setUploading(false);
      setProgress(0);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file && !uploading) handleFile(file);
  };

  const isImage = /\.(jpg|jpeg|png|gif|webp)$/i.test(value);

  return (
    <div className="form-group">
      <label className="label" htmlFor={inputId}>{label}</label>

      <div style={{ display: "flex", gap: 8, marginBottom: 8 }}>
        <input
          id={inputId}
          type="url"
          className="input"
          value={value}
          onChange={e => onChange(e.target.value)}
          placeholder={placeholder}
          style={{ flex: 1 }}
        />
        {value && (
          <button type="button" className="icon-btn" aria-label={`Clear ${label}`} onClick={() => onChange("")}>
            <X size={16} aria-hidden="true" />
          </button>
        )}
      </div>

      <button
        type="button"
        disabled={uploading}
        onDrop={handleDrop}
        onDragOver={e => e.preventDefault()}
        onClick={() => fileRef.current?.click()}
        style={{
          width: "100%",
          minHeight: 44,
          border: "1px dashed var(--border-strong)",
          borderRadius: "var(--radius-sm)",
          padding: "10px 12px",
          cursor: uploading ? "default" : "pointer",
          background: "var(--bg-surface)",
          color: "var(--text-2)",
          fontFamily: "var(--font)",
          fontSize: 13,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 8,
        }}
      >
        {uploading ? (
          <>
            <span className="spinner" style={{ width: 16, height: 16 }} />
            Uploading… {progress}%
          </>
        ) : (
          <>
            <Upload size={15} aria-hidden="true" />
            Choose a file, or drag one here
          </>
        )}
      </button>

      {uploading && (
        <div
          role="progressbar"
          aria-label={`Uploading ${label}`}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={progress}
          style={{ height: 4, background: "var(--border)", borderRadius: 2, marginTop: 8 }}
        >
          <div style={{ height: "100%", background: "var(--primary)", borderRadius: 2, width: `${progress}%`, transition: "width 0.2s" }} />
        </div>
      )}

      {value && !uploading && (
        <div style={{ marginTop: 8 }}>
          {isImage ? (
            <img src={value} alt=""
              style={{ height: 64, borderRadius: 8, objectFit: "cover", border: "1px solid var(--border)" }}
              onError={e => { (e.target as HTMLImageElement).style.display = "none"; }} />
          ) : (
            <a href={value} target="_blank" rel="noreferrer"
              style={{ fontSize: 12, color: "var(--text-2)", wordBreak: "break-all" }}>
              {value}
            </a>
          )}
        </div>
      )}

      {error && <p role="alert" style={{ color: "var(--danger)", fontSize: 13, margin: "8px 0 0" }}>{error}</p>}

      <input ref={fileRef} type="file" accept={accept} style={{ display: "none" }}
        onChange={e => {
          const f = e.target.files?.[0];
          if (f) handleFile(f);
          e.target.value = ""; // Allow choosing the same file again.
        }} />
    </div>
  );
}
