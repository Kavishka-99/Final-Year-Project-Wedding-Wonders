import { useState } from "react";
import axios from "axios";
import { useNavigate, Link } from "react-router-dom";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const navigate = useNavigate();

  const login = async () => {
    try {
      const res = await axios.post("http://localhost:5001/api/auth/login", {
        email,
        password
      });

      localStorage.setItem("user", JSON.stringify(res.data.user));
      localStorage.setItem("token", res.data.token);

      navigate("/dashboard");

    } catch (err) {
      alert(err.response?.data?.message || "Login failed");
    }
  };

  return (
    <div style={{ textAlign: "center", marginTop: 100 }}>
      <h2>Admin Login</h2>

      <input placeholder="Email" onChange={e => setEmail(e.target.value)} />
      <br />

      <input type="password" placeholder="Password" onChange={e => setPassword(e.target.value)} />
      <br />

      <button onClick={login}>Login</button>

      <p><Link to="/forgot-password">Forgot Password?</Link></p>
      <p><Link to="/reset-password">Reset Password</Link></p>
    </div>
  );
}