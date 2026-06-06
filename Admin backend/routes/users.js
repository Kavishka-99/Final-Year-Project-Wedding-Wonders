import express from "express";
import db from "../db.js"; // adjust path if needed
import auth from "../middleware/auth.js";

const router = express.Router();

// GET ALL USERS
router.get("/", auth, (req, res) => {
  db.query("SELECT * FROM users", (err, data) => {
    if (err) return res.status(500).json(err);
    res.json(data);
  });
});

// GET SINGLE USER
router.get("/:id", auth, (req, res) => {
  db.query("SELECT * FROM users WHERE id = ?", [req.params.id], (err, data) => {
    if (err) return res.status(500).json(err);
    res.json(data[0]);
  });
});

// DELETE USER
router.delete("/:id", auth, (req, res) => {
  db.query("DELETE FROM users WHERE id = ?", [req.params.id], (err) => {
    if (err) return res.status(500).json(err);
    res.json({ message: "User deleted" });
  });
});

export default router;