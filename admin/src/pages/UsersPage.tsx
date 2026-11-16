import { useMemo, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Search, UserX, UserCheck, Users } from "lucide-react";
import api from "../lib/api";
import { toast } from "../lib/toast";
import { useAuthStore } from "../store/authStore";
import ConfirmDialog from "../components/ConfirmDialog";

interface User {
  id: string; email: string; full_name: string;
  role: string; is_active: boolean; created_at: string;
}

export default function UsersPage() {
  const qc = useQueryClient();
  const me = useAuthStore((s) => s.user);
  const [search, setSearch] = useState("");
  const [suspending, setSuspending] = useState<User | null>(null);

  const { data: users = [], isLoading, isError, refetch } = useQuery({
    queryKey: ["users"],
    queryFn: async () => (await api.get("/admin/users")).data.data as User[],
  });

  const statusMutation = useMutation({
    mutationFn: ({ user, isActive }: { user: User; isActive: boolean }) =>
      api.patch(`/admin/users/${user.id}/status`, { is_active: isActive }),
    onSuccess: (_, { user, isActive }) => {
      qc.invalidateQueries({ queryKey: ["users"] });
      toast.success(isActive ? `${user.full_name} can sign in again` : `${user.full_name} is suspended`);
    },
    onSettled: () => setSuspending(null),
  });

  const visible = useMemo(() => {
    const needle = search.trim().toLowerCase();
    if (!needle) return users;
    return users.filter((u) =>
      u.email.toLowerCase().includes(needle) || u.full_name.toLowerCase().includes(needle));
  }, [users, search]);

  return (
    <div style={{ padding: "28px 32px" }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Users</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-3)" }}>
            {isLoading ? "Everyone with an account." : `${users.length} ${users.length === 1 ? "account" : "accounts"}.`}
          </p>
        </div>
      </div>

      <div className="search-wrap" style={{ marginBottom: 16, maxWidth: 360 }}>
        <Search size={16} aria-hidden="true" />
        <input className="input" type="search" aria-label="Search users" placeholder="Search by name or email"
          value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {isLoading ? (
        <div style={{ display: "flex", justifyContent: "center", padding: 48 }}>
          <span className="spinner" style={{ width: 28, height: 28 }} />
        </div>
      ) : isError ? (
        <div className="empty-state">
          <Users size={40} aria-hidden="true" />
          <p>Could not load users.</p>
          <button className="btn-ghost" style={{ marginTop: 16 }} onClick={() => refetch()}>Try again</button>
        </div>
      ) : visible.length === 0 ? (
        <div className="empty-state"><Users size={40} aria-hidden="true" /><p>No users match your search.</p></div>
      ) : (
        <div className="card" style={{ overflowX: "auto" }}>
          <table className="table" style={{ minWidth: 640 }}>
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Status</th>
                <th>Joined</th>
                <th><span style={{ position: "absolute", left: -9999 }}>Actions</span></th>
              </tr>
            </thead>
            <tbody>
              {visible.map(user => {
                const isMe = user.id === me?.id;
                return (
                  <tr key={user.id}>
                    <td>
                      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                        <div className="avatar" aria-hidden="true">{user.full_name.charAt(0).toUpperCase()}</div>
                        <div style={{ minWidth: 0 }}>
                          <div style={{ fontWeight: 600 }}>{user.full_name}{isMe && <span style={{ color: "var(--text-3)", fontWeight: 400 }}> (you)</span>}</div>
                          <div style={{ fontSize: 13, color: "var(--text-3)" }}>{user.email}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className={`badge ${user.role === "admin" ? "badge-purple" : "badge-gray"}`}>
                        {user.role === "admin" ? "Admin" : "Viewer"}
                      </span>
                    </td>
                    <td>
                      <span style={{ display: "inline-flex", alignItems: "center", gap: 8, fontWeight: user.is_active ? 600 : 400, color: user.is_active ? "var(--text)" : "var(--text-3)" }}>
                        <span aria-hidden="true" style={{
                          width: 8, height: 8, borderRadius: 4, boxSizing: "border-box",
                          ...(user.is_active ? { background: "var(--success)" } : { border: "2px solid var(--text-3)" }),
                        }} />
                        {user.is_active ? "Active" : "Suspended"}
                      </span>
                    </td>
                    <td style={{ color: "var(--text-2)" }}>
                      {new Date(user.created_at).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" })}
                    </td>
                    <td>
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        {/* You cannot suspend your own account from here. */}
                        {!isMe && (user.is_active ? (
                          <button className="icon-btn" aria-label={`Suspend ${user.full_name}`} title="Suspend"
                            onClick={() => setSuspending(user)}>
                            <UserX size={16} aria-hidden="true" />
                          </button>
                        ) : (
                          <button className="icon-btn" aria-label={`Reactivate ${user.full_name}`} title="Reactivate"
                            disabled={statusMutation.isPending}
                            onClick={() => statusMutation.mutate({ user, isActive: true })}>
                            <UserCheck size={16} aria-hidden="true" />
                          </button>
                        ))}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {suspending && (
        <ConfirmDialog
          title="Suspend account?"
          message={`${suspending.full_name} (${suspending.email}) will not be able to sign in until the account is reactivated.`}
          confirmLabel="Suspend"
          busy={statusMutation.isPending}
          onConfirm={() => statusMutation.mutate({ user: suspending, isActive: false })}
          onCancel={() => setSuspending(null)}
        />
      )}
    </div>
  );
}
