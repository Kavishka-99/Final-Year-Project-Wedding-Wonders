import express from "express";
import db from "../db.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { sendOTP } from "../utils/sendEmail.js";

const router = express.Router();


router.post("/forgot-password", (req, res) => {
  res.json({ message: "Route working" });
});


// =======================
// LOGIN
// =======================
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const [rows] = await db.query(
      "SELECT * FROM admin WHERE email = ?",
      [email]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    const user = rows[0];

    // compare password
    const match = await bcrypt.compare(password, user.password);

    if (!match) {
      return res.status(401).json({ message: "Wrong password" });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email },
      "secretkey",
      { expiresIn: "1d" }
    );

    res.json({
      success: true,
      message: "Login successful",
      user,
      token
    });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});


// =======================
// SEND OTP
// =======================
router.post("/forgot-password", async (req, res) => {
  const { email } = req.body;

  try {
    const [user] = await db.query(
      "SELECT * FROM vendors WHERE email = ?",
      [email]
    );

    if (!user.length) {
      return res.status(404).json({ message: "User not found" });
    }

    const otp = Math.floor(100000 + Math.random() * 900000);
    const expiry = new Date(Date.now() + 5 * 60 * 1000);

    await db.query(
      "UPDATE vendors SET otp=?, otp_expiry=? WHERE email=?",
      [otp, expiry, email]
    );

    await sendOTP(email, otp);

    res.json({ message: "OTP sent successfully" });

  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
});


// =======================
// RESET PASSWORD
// =======================
router.post("/reset-password", async (req, res) => {
  const { email, otp, newPassword } = req.body;

  try {
    const [user] = await db.query(
      "SELECT * FROM vendors WHERE email=?",
      [email]
    );

    if (!user.length) {
      return res.status(404).json({ message: "User not found" });
    }

    const dbUser = user[0];

    if (dbUser.otp != otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (new Date(dbUser.otp_expiry) < new Date()) {
      return res.status(400).json({ message: "OTP expired" });
    }

    const hashed = await bcrypt.hash(newPassword, 10);

    await db.query(
      "UPDATE vendors SET password=?, otp=NULL, otp_expiry=NULL WHERE email=?",
      [hashed, email]
    );

    res.json({ message: "Password reset successful" });

  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;