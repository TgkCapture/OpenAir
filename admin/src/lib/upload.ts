import api from "./api";

export async function uploadFile(
  file: File,
  onProgress?: (pct: number) => void
): Promise<string> {
  const form = new FormData();
  form.append("file", file);

  const res = await api.post("/admin/upload", form, {
    headers: { "Content-Type": "multipart/form-data" },
    onUploadProgress: (e) => {
      if (onProgress && e.total) {
        onProgress(Math.round((e.loaded * 100) / e.total));
      }
    },
  });

  return res.data.data.url as string;
}