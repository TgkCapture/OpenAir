import { useState } from "react";
import { useNavigate } from "react-router-dom";
import api from "../lib/api";
import { useAuthStore } from "../store/authStore";

export default function LoginPage() {
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await api.post("/auth/login", { email, password });
      const { user, access_token } = res.data.data;
      if (user.role !== "admin") {
        setError("Access denied. Admin accounts only.");
        setLoading(false);
        return;
      }
      setAuth(access_token, user);
      navigate("/dashboard");
    } catch (err: unknown) {
      const e = err as { response?: { data?: { error?: { message?: string } } } };
      setError(e.response?.data?.error?.message ?? "Invalid email or password");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: "100vh",
      display: "flex",
      background: "var(--bg)",
      fontFamily: "var(--font)",
    }}>

      {/* ── Left panel ── */}
      <div style={{
        display: "none",
        width: "45%",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "48px",
        background: "#0A0A0C",
        position: "relative",
        overflow: "hidden",
      }}
        className="left-panel"
      >
        <style>{`
          @media (min-width: 1024px) {
            .left-panel { display: flex !important; }
          }
        `}</style>

        {/* Glow */}
        <div style={{
          position: "absolute", top: -80, left: -80,
          width: 320, height: 320, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(230,57,70,0.2), transparent 70%)",
          pointerEvents: "none",
        }} />
        <div style={{
          position: "absolute", bottom: -60, right: -60,
          width: 240, height: 240, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(230,57,70,0.1), transparent 70%)",
          pointerEvents: "none",
        }} />

        <div style={{ position: "relative", zIndex: 1, textAlign: "center", width: "100%", maxWidth: 320 }}>
          <img
            src="/icon.png"
            alt="OpenAir"
            style={{
              width: 88, height: 88,
              borderRadius: 22, objectFit: "cover",
              marginBottom: 20,
              boxShadow: "0 12px 40px rgba(230,57,70,0.4)",
            }}
          />
          <h1 style={{ fontSize: 36, fontWeight: 800, color: "white", margin: "0 0 6px", letterSpacing: "-0.03em" }}>
            OpenAir
          </h1>
          <p style={{ fontSize: 15, color: "#6B7280", marginBottom: 48 }}>
            Broadcast Management Platform
          </p>

          {[
            { icon: "📺", title: "Manage Channels", desc: "Configure TV & radio streams" },
            { icon: "🎬", title: "Upload Content", desc: "VOD, podcasts and promos" },
            { icon: "📊", title: "Analytics", desc: "Track viewers & engagement" },
          ].map(({ icon, title, desc }) => (
            <div key={title} style={{
              display: "flex", alignItems: "flex-start", gap: 12,
              padding: "12px 14px", borderRadius: 10, marginBottom: 8,
              background: "rgba(255,255,255,0.04)",
              border: "1px solid rgba(255,255,255,0.06)",
              textAlign: "left",
            }}>
              <span style={{ fontSize: 18, lineHeight: 1 }}>{icon}</span>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: "white" }}>{title}</div>
                <div style={{ fontSize: 12, color: "#6B7280", marginTop: 1 }}>{desc}</div>
              </div>
            </div>
          ))}

          <p style={{ fontSize: 11, color: "#374151", marginTop: 40 }}>
            github.com/TgkCapture/openair
          </p>
        </div>
      </div>

      {/* ── Right form panel ── */}
      <div style={{
        flex: 1,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "24px",
      }}>
        <div style={{ width: "100%", maxWidth: 400 }}>

          {/* Mobile logo */}
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 40 }}
            className="mobile-logo"
          >
            <style>{`
              @media (min-width: 1024px) { .mobile-logo { display: none !important; } }
            `}</style>
            <img src="/icon.png" alt="OpenAir"
              style={{ width: 36, height: 36, borderRadius: 8, objectFit: "cover" }} />
            <span style={{ fontSize: 18, fontWeight: 700 }}>OpenAir Admin</span>
          </div>

          <div style={{ marginBottom: 32 }}>
            <h2 style={{ fontSize: 26, fontWeight: 800, margin: "0 0 6px", letterSpacing: "-0.02em" }}>
              Welcome back
            </h2>
            <p style={{ fontSize: 14, color: "var(--text-2)", margin: 0 }}>
              Sign in to manage your broadcast platform
            </p>
          </div>

          {error && (
            <div style={{
              display: "flex", alignItems: "flex-start", gap: 10,
              padding: "12px 14px", borderRadius: 10, marginBottom: 20,
              background: "rgba(239,68,68,0.08)",
              border: "1px solid rgba(239,68,68,0.25)",
              color: "#DC2626", fontSize: 13,
            }}>
              <span>⚠</span>
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleLogin}>
            <div className="form-group">
              <label className="label">Email address</label>
              <input
                type="email"
                className="input"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="admin@openair.dev"
                required
                autoComplete="email"
              />
            </div>

            <div className="form-group">
              <label className="label">Password</label>
              <div style={{ position: "relative" }}>
                <input
                  type={showPass ? "text" : "password"}
                  className="input"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  autoComplete="current-password"
                  style={{ paddingRight: 42 }}
                />
                <button
                  type="button"
                  onClick={() => setShowPass(s => !s)}
                  style={{
                    position: "absolute", right: 12, top: "50%",
                    transform: "translateY(-50%)",
                    background: "none", border: "none", cursor: "pointer",
                    color: "var(--text-3)", padding: 4,
                    display: "flex", alignItems: "center",
                  }}
                >
                  {showPass ? (
                    <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                        d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 4.411m0 0L21 21" />
                    </svg>
                  ) : (
                    <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  )}
                </button>
              </div>
            </div>

            <button
              type="submit"
              className="btn-primary"
              disabled={loading}
              style={{ width: "100%", justifyContent: "center", padding: "12px", fontSize: 14, marginTop: 8 }}
            >
              {loading ? (
                <>
                  <span className="spinner" style={{ width: 16, height: 16, borderWidth: 2 }} />
                  Signing in...
                </>
              ) : "Sign in"}
            </button>
          </form>

          <p style={{ textAlign: "center", fontSize: 12, color: "var(--text-3)", marginTop: 32 }}>
            OpenAir Admin · Authorised personnel only
          </p>
        </div>
      </div>
    </div>
  );
}