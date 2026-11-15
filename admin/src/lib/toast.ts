import { create } from "zustand";

export type ToastKind = "success" | "error";

export interface ToastItem {
  id: number;
  kind: ToastKind;
  message: string;
}

interface ToastState {
  toasts: ToastItem[];
  show: (kind: ToastKind, message: string) => void;
  dismiss: (id: number) => void;
}

let nextId = 1;

export const useToastStore = create<ToastState>((set, get) => ({
  toasts: [],
  show: (kind, message) => {
    const id = nextId++;
    // Keep at most three on screen; the oldest drops off.
    set((state) => ({ toasts: [...state.toasts, { id, kind, message }].slice(-3) }));
    // Errors stay longer so they can be read.
    window.setTimeout(() => get().dismiss(id), kind === "error" ? 7000 : 4000);
  },
  dismiss: (id) => set((state) => ({ toasts: state.toasts.filter((t) => t.id !== id) })),
}));

/** Show a short message in the corner of the screen, from anywhere. */
export const toast = {
  success: (message: string) => useToastStore.getState().show("success", message),
  error: (message: string) => useToastStore.getState().show("error", message),
};

/** The API's own error message when it sent one, otherwise a general one. */
export function errorMessage(error: unknown): string {
  const response = (error as { response?: { status?: number; data?: { error?: { message?: string } } } })
    ?.response;
  if (!response) return "Cannot reach the server. Check your connection and try again.";
  return response.data?.error?.message ?? "Something went wrong. Please try again.";
}
