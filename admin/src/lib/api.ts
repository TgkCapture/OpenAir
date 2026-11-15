import axios, { AxiosError, type InternalAxiosRequestConfig } from "axios";
import { useAuthStore } from "../store/authStore";

const baseURL = import.meta.env.VITE_API_URL || "http://localhost:8000/api/v1";

const api = axios.create({
  baseURL,
  headers: { "Content-Type": "application/json" },
});

type RetriableRequest = InternalAxiosRequestConfig & { _retried?: boolean };

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

let refreshing: Promise<boolean> | null = null;

/**
 * Renews the access token. Requests that fail at the same moment share one
 * refresh call, because a refresh token only works once. Uses a bare axios
 * call so a failed refresh can never trigger another refresh.
 */
function refreshTokens(): Promise<boolean> {
  refreshing ??= (async () => {
    const { refreshToken, setTokens, logout } = useAuthStore.getState();
    if (!refreshToken) {
      logout();
      return false;
    }
    try {
      const res = await axios.post(`${baseURL}/auth/refresh`, {
        refresh_token: refreshToken,
      });
      const { access_token, refresh_token } = res.data.data;
      setTokens(access_token, refresh_token);
      return true;
    } catch (err) {
      // Only a rejected token ends the session; a network failure keeps it.
      if ((err as AxiosError).response?.status === 401) logout();
      return false;
    }
  })().finally(() => {
    refreshing = null;
  });
  return refreshing;
}

api.interceptors.response.use(
  (res) => res,
  async (err: AxiosError) => {
    const request = err.config as RetriableRequest | undefined;
    const canRetry =
      err.response?.status === 401 &&
      request !== undefined &&
      !request._retried &&
      !request.url?.startsWith("/auth/");

    if (canRetry && (await refreshTokens())) {
      // The access token was renewed: replay the request once.
      request._retried = true;
      return api(request);
    }

    // The session is over: send the user to the login page.
    const onLoginPage = window.location.pathname === "/login";
    if (canRetry && !useAuthStore.getState().token && !onLoginPage) {
      window.location.href = "/login";
    }
    return Promise.reject(err);
  }
);

/** Signs this browser out on the server, then clears the local session. */
export async function logout(): Promise<void> {
  const { refreshToken, logout: clear } = useAuthStore.getState();
  try {
    await api.post("/auth/logout", refreshToken ? { refresh_token: refreshToken } : {});
  } catch {
    // The local session is cleared even when the server cannot be reached.
  }
  clear();
}

export default api;
