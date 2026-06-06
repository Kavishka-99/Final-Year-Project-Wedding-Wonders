// src/pages/Users.jsx
import { useEffect, useState } from "react";
import api from "../api";

export default function Users() {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      const res = await api.get("/users");
      setUsers(res.data);
    } catch (err) {
      console.log(err);
    }
  };

  return (
    <div style={{ padding: 20 }}>
      <h2>Users</h2>

      {users.map((u) => (
        <div key={u.id} style={{ padding: 10, borderBottom: "1px solid #ddd" }}>
          <p>Name: {u.name}</p>
          <p>Email: {u.email}</p>
          <p>Status: {u.status}</p>
        </div>
      ))}
    </div>
  );
}