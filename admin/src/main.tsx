import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import { MutationCache, QueryClient, QueryClientProvider } from "@tanstack/react-query";
import App from "./App";
import Toaster from "./components/Toaster";
import { applyTheme, getTheme } from "./lib/theme";
import { errorMessage, toast } from "./lib/toast";
import "./index.css";

// Set the theme before the first paint so the page does not flash.
applyTheme(getTheme());

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 60_000, retry: 1 },
  },
  // Every failed save, delete or send shows a message, so no page can fail
  // silently. A 401 is handled by the API client, which signs the user out.
  mutationCache: new MutationCache({
    onError: (error) => {
      const status = (error as { response?: { status?: number } })?.response?.status;
      if (status !== 401) toast.error(errorMessage(error));
    },
  }),
});

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <App />
        <Toaster />
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>
);
