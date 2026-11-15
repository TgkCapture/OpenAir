import { useEffect, useState } from "react";
import { Outlet, NavLink, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  LayoutDashboard, Tv, Film, Mic, Calendar,
  Users, BarChart2, Settings, LogOut, Bell, Moon, Sun,
} from "lucide-react";
import { useAuthStore } from "../store/authStore";
import api, { logout } from "../lib/api";
import { applyBrandColor, getTheme, setTheme, type Theme } from "../lib/theme";

const NAV = [
  { to: "/dashboard",     icon: LayoutDashboard, label: "Dashboard" },
  { to: "/channels",      icon: Tv,              label: "Channels" },
  { to: "/vod",           icon: Film,            label: "Videos" },
  { to: "/podcasts",      icon: Mic,             label: "Podcasts" },
  { to: "/schedule",      icon: Calendar,        label: "Schedule" },
  { to: "/users",         icon: Users,           label: "Users" },
  { to: "/analytics",     icon: BarChart2,       label: "Analytics" },
  { to: "/notifications", icon: Bell,            label: "Notifications" },
  { to: "/settings",      icon: Settings,        label: "Settings" },
];

interface Branding {
  broadcaster: string;
  primary_color: string;
}

export default function DashboardLayout() {
  const { user } = useAuthStore();
  const navigate = useNavigate();
  const [theme, setThemeState] = useState<Theme>(getTheme);

  // Shares its cache with the Settings page, so saving a new name or colour
  // there updates the sidebar and the brand colour straight away.
  const { data: branding } = useQuery({
    queryKey: ["app-config"],
    queryFn: async () => (await api.get("/config")).data.data as Branding,
  });

  useEffect(() => {
    applyBrandColor(branding?.primary_color);
  }, [branding?.primary_color]);

  const toggleTheme = () => {
    const next: Theme = theme === "dark" ? "light" : "dark";
    setTheme(next);
    setThemeState(next);
  };

  const handleLogout = async () => {
    await logout();
    navigate("/login");
  };

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span>{branding?.broadcaster ?? "OpenAir"}</span>
          <span className="muted">Studio</span>
        </div>

        <nav className="sidebar-nav" aria-label="Main">
          {NAV.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) => `nav-item${isActive ? " active" : ""}`}
            >
              <Icon size={17} aria-hidden="true" />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="avatar" aria-hidden="true">
              {user?.full_name?.charAt(0).toUpperCase() ?? "A"}
            </div>
            <div style={{ minWidth: 0, flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {user?.full_name ?? "Admin"}
              </div>
              <div style={{ fontSize: 12, color: "var(--text-3)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {user?.email}
              </div>
            </div>
          </div>
          <button className="nav-item" onClick={toggleTheme}>
            {theme === "dark" ? <Sun size={17} aria-hidden="true" /> : <Moon size={17} aria-hidden="true" />}
            {theme === "dark" ? "Light theme" : "Dark theme"}
          </button>
          <button className="nav-item danger" onClick={handleLogout}>
            <LogOut size={17} aria-hidden="true" />
            Sign out
          </button>
        </div>
      </aside>

      <main className="app-main">
        <Outlet />
      </main>
    </div>
  );
}
