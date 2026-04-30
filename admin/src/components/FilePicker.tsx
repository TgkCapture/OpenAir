import { useRef, useState } from "react";
import { Upload, X, Loader } from "lucide-react";
import { uploadFile } from "../lib/upload";

interface FilePickerProps {
  label: string;
  value: string;
  onChange: (url: string) => void;
  accept?: string;
  placeholder?: string;
}

export default function FilePicker({
  label, value, onChange, accept = "*/*", placeholder = "Paste URL or upload file",
}: FilePickerProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState("");

  const handleFile = async (file: File) => {
    setUploading(true);
    setError("");
    setProgress(0);
    try {
      const url = await uploadFile(file, setProgress);
      onChange(url);
    } catch {
      setError("Upload failed — try pasting a URL instead");
    } finally {
      setUploading(false);
      setProgress(0);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  };

  return (
    <div className="form-group">
      <label className="label">{label}</label>

      {/* URL input */}
      <div style={{ display: "flex", gap: 8, marginBottom: 8 }}>
        <input
          type="url"
          className="input"
          value={value}
          onChange={e => onChange(e.target.value)}
          placeholder={placeholder}
          style={{ flex: 1 }}
        />
        {value && (
          <button type="button" onClick={() => onChange("")}
            style={{ padding: "0 10px", background: "var(--bg)", border: "1px solid var(--border)", borderRadius: "var(--radius-sm)", cursor: "pointer", color: "var(--text-3)" }}>
            <X size={14} />
          </button>
        )}
      </div>

      {/* Drop zone */}
      <div
        onDrop={handleDrop}
        onDragOver={e => e.preventDefault()}
        onClick={() => inputRef.current?.click()}
        style={{
          border: "1px dashed var(--border-strong)",
          borderRadius: "var(--radius-sm)",
          padding: "12px",
          cursor: "pointer",
          textAlign: "center",
          background: "var(--bg)",
          transition: "border-color 0.15s",
        }}
        onMouseEnter={e => (e.currentTarget.style.borderColor = "var(--primary)")}
        onMouseLeave={e => (e.currentTarget.style.borderColor = "var(--border-strong)")}
      >
        {uploading ? (
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, color: "var(--text-3)", fontSize: 13 }}>
            <Loader size={14} className="spinner" style={{ borderColor: "var(--border)", borderTopColor: "var(--primary)" }} />
            Uploading... {progress}%
          </div>
        ) : (
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 6, color: "var(--text-3)", fontSize: 12 }}>
            <Upload size={13} />
            Click or drag & drop to upload
          </div>
        )}
      </div>

      {/* Progress bar */}
      {uploading && (
        <div style={{ height: 3, background: "var(--border)", borderRadius: 2, marginTop: 6 }}>
          <div style={{ height: "100%", background: "var(--primary)", borderRadius: 2, width: `${progress}%`, transition: "width 0.2s" }} />
        </div>
      )}

      {/* Preview */}
      {value && !uploading && (
        <div style={{ marginTop: 8 }}>
          {/\.(jpg|jpeg|png|gif|webp)$/i.test(value) || value.startsWith("blob:") ? (
            <img src={value} alt="preview"
              style={{ height: 64, borderRadius: 6, objectFit: "cover", border: "1px solid var(--border)" }}
              onError={e => { (e.target as HTMLImageElement).style.display = "none"; }} />
          ) : (
            <a href={value} target="_blank" rel="noreferrer"
              style={{ fontSize: 11, color: "var(--primary)", wordBreak: "break-all" }}>
              {value}
            </a>
          )}
        </div>
      )}

      {error && <p style={{ color: "#DC2626", fontSize: 12, margin: "6px 0 0" }}>{error}</p>}

      <input ref={inputRef} type="file" accept={accept} style={{ display: "none" }}
        onChange={e => { const f = e.target.files?.[0]; if (f) handleFile(f); }} />
    </div>
  );
}