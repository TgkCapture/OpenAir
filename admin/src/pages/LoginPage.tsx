import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Eye, EyeOff } from "lucide-react";
import api from "../lib/api";
import { errorMessage } from "../lib/toast";
import { useAuthStore } from "../store/authStore";

export default function LoginPage() {
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await api.post("/auth/login", { email, password });
      const { user, access_token, refresh_token } = res.data.data;
      if (user.role !== "admin") {
        setError("This account is not an admin account.");
        return;
      }
      setAuth(access_token, refresh_token, user);
      navigate("/dashboard");
    } catch (err) {
      const status = (err as { response?: { status?: number } })?.response?.status;
      setError(status === 401 ? "The email or password is not right." : errorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
      <div style={{ width: "100%", maxWidth: 400 }}>
        <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: "-0.02em", marginBottom: 32 }}>
          OpenAir <span style={{ color: "var(--text-3)", fontWeight: 500 }}>Studio</span>
        </div>

        <h1 style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-0.02em", margin: "0 0 6px" }}>Sign in</h1>
        <p style={{ color: "var(--text-3)", margin: "0 0 28px" }}>Manage your channels, content and schedule.</p>

        <form onSubmit={handleLogin} className="card" style={{ padding: 24 }}>
          {error && (
            <p role="alert" style={{ margin: "0 0 16px", color: "var(--danger)", fontWeight: 500 }}>{error}</p>
          )}

          <div className="form-group">
            <label className="label" htmlFor="login-email">Email</label>
            <input id="login-email" type="email" className="input" value={email} required autoComplete="email"
              onChange={e => setEmail(e.target.value)} />
          </div>

          <div className="form-group">
            <label className="label" htmlFor="login-password">Password</label>
            <div style={{ display: "flex", gap: 8 }}>
              <input id="login-password" type={showPassword ? "text" : "password"} className="input"
                value={password} required autoComplete="current-password"
                onChange={e => setPassword(e.target.value)} />
              <button type="button" className="icon-btn" style={{ border: "1px solid var(--border-strong)", flexShrink: 0 }}
                aria-label={showPassword ? "Hide password" : "Show password"}
                onClick={() => setShowPassword(s => !s)}>
                {showPassword ? <EyeOff size={17} aria-hidden="true" /> : <Eye size={17} aria-hidden="true" />}
              </button>
            </div>
          </div>

          <button type="submit" className="btn-primary" disabled={loading} style={{ width: "100%", marginTop: 8 }}>
            {loading ? <span className="spinner" /> : "Sign in"}
          </button>
        </form>

        <p style={{ fontSize: 13, color: "var(--text-3)", marginTop: 20 }}>For station staff with an admin account.</p>
      </div>
    </div>
  );
}
