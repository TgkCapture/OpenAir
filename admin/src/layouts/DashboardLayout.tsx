import { Outlet, NavLink, useNavigate } from "react-router-dom";
import {
  LayoutDashboard, Tv, Film, Mic, Calendar,
  Users, BarChart2, Settings, LogOut, Radio, Bell,
} from "lucide-react";
import { useAuthStore } from "../store/authStore";

const NAV = [
  { to: "/dashboard",     icon: LayoutDashboard, label: "Dashboard" },
  { to: "/channels",      icon: Tv,              label: "Channels" },
  { to: "/vod",           icon: Film,            label: "VOD" },
  { to: "/podcasts",      icon: Mic,             label: "Podcasts" },
  { to: "/schedule",      icon: Calendar,        label: "Schedule" },
  { to: "/users",         icon: Users,           label: "Users" },
  { to: "/analytics",     icon: BarChart2,       label: "Analytics" },
  { to: "/notifications", icon: Bell,            label: "Notifications" },
  { to: "/settings",      icon: Settings,        label: "Settings" },
];

export default function DashboardLayout() {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div style={{ display: "flex", height: "100vh", background: "var(--bg)" }}>

      {/* ── Sidebar ── */}
      <aside style={{
        width: "var(--sidebar-width)",
        flexShrink: 0,
        background: "var(--bg-sidebar)",
        borderRight: "1px solid var(--border)",
        display: "flex",
        flexDirection: "column",
        height: "100vh",
        position: "sticky",
        top: 0,
      }}>

        {/* Logo */}
        <div style={{
          height: 56,
          display: "flex",
          alignItems: "center",
          padding: "0 16px",
          borderBottom: "1px solid var(--border)",
          gap: 10,
          flexShrink: 0,
        }}>
          <img
            src="/icon.png"
            alt="OpenAir"
            style={{ width: 28, height: 28, borderRadius: 6, objectFit: "cover" }}
            onError={(e) => { (e.target as HTMLImageElement).style.display = "none"; }}
          />
          <span style={{ fontWeight: 700, fontSize: 14, color: "var(--text)" }}>
            OpenAir
          </span>
          <span style={{
            marginLeft: "auto",
            fontSize: 10,
            fontWeight: 700,
            padding: "2px 6px",
            background: "var(--primary-soft)",
            color: "var(--primary)",
            borderRadius: 4,
            letterSpacing: "0.05em",
          }}>
            ADMIN
          </span>
        </div>

        {/* Nav */}
        <nav style={{ flex: 1, padding: "8px", overflowY: "auto" }}>
          {NAV.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                `nav-item${isActive ? " active" : ""}`
              }
            >
              <Icon size={15} />
              {label}
            </NavLink>
          ))}
        </nav>

        {/* User footer */}
        <div style={{
          padding: "12px",
          borderTop: "1px solid var(--border)",
          flexShrink: 0,
        }}>
          <div style={{
            display: "flex",
            alignItems: "center",
            gap: 8,
            padding: "8px",
            borderRadius: "var(--radius-sm)",
            background: "var(--bg)",
            marginBottom: 4,
          }}>
            <div style={{
              width: 28, height: 28,
              borderRadius: "50%",
              background: "var(--primary-soft)",
              display: "flex", alignItems: "center", justifyContent: "center",
              color: "var(--primary)",
              fontWeight: 700,
              fontSize: 12,
              flexShrink: 0,
            }}>
              {user?.full_name?.charAt(0).toUpperCase() ?? "A"}
            </div>
            <div style={{ minWidth: 0, flex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: "var(--text)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {user?.full_name ?? "Admin"}
              </div>
              <div style={{ fontSize: 11, color: "var(--text-3)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {user?.email}
              </div>
            </div>
          </div>
          <button className="nav-item" onClick={handleLogout} style={{ width: "100%", color: "#E63946" }}>
            <LogOut size={14} />
            Sign out
          </button>
        </div>
      </aside>

      {/* ── Main content ── */}
      <main style={{ flex: 1, overflowY: "auto", minWidth: 0 }}>
        <Outlet />
      </main>
    </div>
  );
}