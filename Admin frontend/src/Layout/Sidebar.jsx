// src/Layout/Sidebar.jsx
import { Link } from "react-router-dom";
import { logout } from "../utils/auth";

export default function Sidebar() {
  return (
    <div
      style={{
        width: 220,
        height: "100vh",
        background: "#111",
        color: "white",
        padding: 20,
        position: "fixed",
      }}
    >
      <h3>Admin Panel</h3>

      <nav style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        <Link to="/dashboard" style={{ color: "white" }}>Dashboard</Link>
        <Link to="/vendors" style={{ color: "white" }}>Vendors</Link>
        <Link to="/users" style={{ color: "white" }}>Users</Link>
        <Link to="/settings" style={{ color: "white" }}>Settings</Link>
      </nav>

      <button
        onClick={logout}
        style={{
          marginTop: 30,
          background: "red",
          color: "white",
          padding: 8,
          border: "none",
          cursor: "pointer",
        }}
      >
        Logout
      </button>
    </div>
  );
}