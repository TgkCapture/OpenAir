import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Search, UserX, UserCheck, Shield, Users } from "lucide-react";
import api from "../lib/api";

interface User {
  id: string; email: string; full_name: string;
  role: string; is_active: boolean; created_at: string;
}

export default function UsersPage() {
  const qc = useQueryClient();
  const [search, setSearch] = useState("");

  const { data: users = [], isLoading } = useQuery({
    queryKey: ["users"],
    queryFn: async () => (await api.get("/admin/users")).data.data as User[],
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
    <div style={{ padding: "32px" }}>
      <div className="page-header">
        <h1 className="page-title">Users</h1>
        <span style={{ fontSize: 13, color: "var(--text-3)" }}>{users.length} total</span>
      </div>

      <div className="search-wrap" style={{ marginBottom: 20, maxWidth: 360 }}>
        <Search size={14} />
        <input className="input" placeholder="Search by name or email…"
          value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {isLoading ? (
        <div style={{ display: "flex", justifyContent: "center", padding: 48 }}>
          <span className="spinner" style={{ width: 28, height: 28 }} />
        </div>
      ) : filtered.length === 0 ? (
        <div className="empty-state"><Users size={40} /><p>No users found</p></div>
      ) : (
        <div className="card" style={{ overflow: "hidden" }}>
          <table className="table">
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Status</th>
                <th>Joined</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(user => (
                <tr key={user.id}>
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <div style={{ width: 32, height: 32, borderRadius: "50%", background: "var(--primary-soft)", color: "var(--primary)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 12, flexShrink: 0 }}>
                        {user.full_name.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <div style={{ fontWeight: 600, fontSize: 13 }}>{user.full_name}</div>
                        <div style={{ fontSize: 11, color: "var(--text-3)" }}>{user.email}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span className={`badge ${user.role === "admin" ? "badge-purple" : "badge-gray"}`}>
                      {user.role === "admin" && <Shield size={10} style={{ marginRight: 3 }} />}
                      {user.role}
                    </span>
                  </td>
                  <td>
                    <span className={`badge ${user.is_active ? "badge-green" : "badge-red"}`}>
                      {user.is_active ? "Active" : "Suspended"}
                    </span>
                  </td>
                  <td style={{ color: "var(--text-3)", fontSize: 12 }}>
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                  <td>
                    <button
                      onClick={() => toggleMutation.mutate({ id: user.id, isActive: !user.is_active })}
                      title={user.is_active ? "Suspend" : "Activate"}
                      style={{ padding: 6, background: "none", border: "none", cursor: "pointer", color: user.is_active ? "#DC2626" : "#16A34A", borderRadius: 6 }}>
                      {user.is_active ? <UserX size={15} /> : <UserCheck size={15} />}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}