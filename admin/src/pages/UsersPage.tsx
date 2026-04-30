import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Search, Shield, UserX, UserCheck } from "lucide-react";
import api from "../lib/api";

interface User {
  id: string;
  email: string;
  full_name: string;
  role: string;
  is_active: boolean;
  created_at: string;
}

export default function UsersPage() {
  const qc = useQueryClient();
  const [search, setSearch] = useState("");

  const { data: users = [], isLoading } = useQuery({
    queryKey: ["users"],
    queryFn: async () => {
      const res = await api.get("/admin/users");
      return res.data.data as User[];
    },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      api.patch(`/admin/users/${id}/status`, { is_active: isActive }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["users"] }),
  });

  const filtered = users.filter(u =>
    u.email.toLowerCase().includes(search.toLowerCase()) ||
    u.full_name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div style={{ padding: "32px 32px 48px" }}>
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h1 className="page-title" style={{ marginBottom: 4 }}>User Management</h1>
        <p style={{ fontSize: 13, color: "var(--text-3)", margin: 0 }}>
          Manage user accounts and permissions
        </p>
      </div>

      {/* Search bar */}
      <div style={{ position: "relative", marginBottom: 24 }}>
        <Search size={16} style={{
          position: "absolute", left: 12, top: "50%",
          transform: "translateY(-50%)", color: "var(--text-3)",
        }} />
        <input
          type="text"
          placeholder="Search by name or email..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          style={{
            width: "100%", padding: "10px 12px 10px 36px",
            borderRadius: "var(--radius-md)", border: "1px solid var(--border)",
            background: "var(--bg)", color: "var(--text)", fontSize: 13,
          }}
        />
      </div>

      {/* Users table */}
      {isLoading ? (
        <div style={{ display: "flex", justifyContent: "center", padding: "48px 0" }}>
          <div style={{
            width: 32, height: 32, border: "2px solid var(--primary)",
            borderTopColor: "transparent", borderRadius: "50%",
            animation: "spin 0.8s linear infinite",
          }} />
        </div>
      ) : (
        <div style={{
          background: "var(--bg-surface)", borderRadius: "var(--radius-lg)",
          border: "1px solid var(--border)", overflow: "auto",
        }}>
          <table style={{ width: "100%", fontSize: 13, borderCollapse: "collapse" }}>
            <thead style={{ background: "var(--bg)", borderBottom: "1px solid var(--border)" }}>
              <tr>
                {["Name", "Email", "Role", "Status", "Joined", "Actions"].map(h => (
                  <th key={h} style={{
                    textAlign: "left", padding: "12px 16px",
                    fontSize: 11, fontWeight: 700, color: "var(--text-3)",
                    textTransform: "uppercase", letterSpacing: "0.05em",
                  }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody style={{ borderTop: "1px solid var(--border)" }}>
              {filtered.map(user => (
                <tr key={user.id} style={{
                  borderBottom: "1px solid var(--border)",
                  transition: "background 0.2s",
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = "var(--bg)";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = "transparent";
                }}>
                  <td style={{ padding: "12px 16px" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                      <div style={{
                        width: 32, height: 32, borderRadius: "50%",
                        background: "var(--primary-soft)", display: "flex",
                        alignItems: "center", justifyContent: "center",
                        color: "var(--primary)", fontWeight: 700, fontSize: 12,
                        flexShrink: 0,
                      }}>
                        {user.full_name.charAt(0).toUpperCase()}
                      </div>
                      <span style={{ fontWeight: 500, color: "var(--text)" }}>
                        {user.full_name}
                      </span>
                    </div>
                  </td>
                  <td style={{ padding: "12px 16px", color: "var(--text-2)" }}>
                    {user.email}
                  </td>
                  <td style={{ padding: "12px 16px" }}>
                    <span style={{
                      display: "inline-flex", alignItems: "center", gap: 4,
                      padding: "2px 8px", borderRadius: 4, fontSize: 11, fontWeight: 600,
                      background: user.role === "admin"
                        ? "rgba(139, 92, 246, 0.1)"
                        : "var(--bg)",
                      color: user.role === "admin" ? "#8B5CF6" : "var(--text-2)",
                      border: user.role !== "admin" ? "1px solid var(--border)" : "none",
                    }}>
                      {user.role === "admin" && <Shield size={10} />}
                      {user.role}
                    </span>
                  </td>
                  <td style={{ padding: "12px 16px" }}>
                    <span style={{
                      padding: "2px 8px", borderRadius: 4, fontSize: 11, fontWeight: 600,
                      background: user.is_active
                        ? "rgba(16, 185, 129, 0.1)"
                        : "rgba(239, 68, 68, 0.1)",
                      color: user.is_active ? "#10B981" : "#DC2626",
                    }}>
                      {user.is_active ? "Active" : "Suspended"}
                    </span>
                  </td>
                  <td style={{ padding: "12px 16px", color: "var(--text-3)", fontSize: 12 }}>
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                  <td style={{ padding: "12px 16px" }}>
                    <button
                      onClick={() => toggleMutation.mutate({ id: user.id, isActive: !user.is_active })}
                      style={{
                        padding: 6, borderRadius: "var(--radius-md)",
                        border: "none", cursor: "pointer", display: "flex",
                        background: "transparent",
                        color: user.is_active ? "#DC2626" : "#10B981",
                        transition: "all 0.2s",
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.background = user.is_active
                          ? "rgba(220, 38, 38, 0.1)"
                          : "rgba(16, 185, 129, 0.1)";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.background = "transparent";
                      }}
                      title={user.is_active ? "Suspend" : "Activate"}
                    >
                      {user.is_active ? <UserX size={16} /> : <UserCheck size={16} />}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          
          {filtered.length === 0 && (
            <div style={{
              textAlign: "center", padding: "48px 0",
              color: "var(--text-3)", fontSize: 13,
            }}>
              No users found
            </div>
          )}
        </div>
      )}
    </div>
  );
}