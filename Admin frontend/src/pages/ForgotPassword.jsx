import { useState } from "react";
import axios from "axios";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");

  const submit = async (e) => {
    e.preventDefault();

    const res = await axios.post("http://localhost:5001/api/auth/forgot-password", {
      email
    });

    alert("Your reset token: " + res.data.token);
  };

  return (
    <div>
      <h2>Forgot Password</h2>

      <input placeholder="Email" onChange={(e) => setEmail(e.target.value)} />

      <button onClick={submit}>Send Token</button>
    </div>
  );
}