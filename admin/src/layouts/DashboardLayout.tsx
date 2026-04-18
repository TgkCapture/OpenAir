import { Outlet, NavLink } from "react-router-dom";
import {
  LayoutDashboard, Tv, Film, Mic, Calendar,
  Users, BarChart2, Settings, LogOut, Radio
} from "lucide-react";
import { useAuthStore } from "../store/authStore";

const navItems = [
  { to: "/dashboard", icon: LayoutDashboard, label: "Dashboard" },
  { to: "/channels",  icon: Tv,              label: "Channels" },
  { to: "/vod",       icon: Film,            label: "VOD" },
  { to: "/podcasts",  icon: Mic,             label: "Podcasts" },
  { to: "/schedule",  icon: Calendar,        label: "Schedule" },
  { to: "/users",     icon: Users,           label: "Users" },
  { to: "/analytics", icon: BarChart2,       label: "Analytics" },
  { to: "/settings",  icon: Settings,        label: "Settings" },
];

export default function DashboardLayout() {
  const { user, logout } = useAuthStore();

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-background">
      <aside className="w-60 flex flex-col bg-white dark:bg-surface border-r border-gray-200 dark:border-gray-800">
        <div className="h-16 flex items-center px-6 border-b border-gray-200 dark:border-gray-800">
          <Radio className="text-primary mr-2" size={20} />
          <span className="font-semibold text-lg">OpenAir Admin</span>
        </div>
        <nav className="flex-1 py-4 px-3 space-y-1">
          {navItems.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                  isActive
                    ? "bg-primary/10 text-primary font-medium"
                    : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
                }`
              }
            >
              <Icon size={18} />
              {label}
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-gray-200 dark:border-gray-800">
          <div className="text-sm text-gray-600 dark:text-gray-400 mb-2 truncate">
            {user?.email}
          </div>
          <button
            onClick={logout}
            className="flex items-center gap-2 text-sm text-red-500 hover:text-red-600 transition-colors"
          >
            <LogOut size={16} /> Logout
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}