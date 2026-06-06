import express from "express";
import db from "../db.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// GET ALL VENDORS (PROTECTED)
router.get("/", auth, async (req, res) => {
  try {
    const [data] = await db.query("SELECT * FROM vendors");
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// APPROVE VENDOR
router.put("/approve/:id", auth, async (req, res) => {
  try {
    await db.query("UPDATE vendors SET status='approved' WHERE id=?", [
      req.params.id,
    ]);

    res.json({ message: "Vendor approved" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// REJECT VENDOR (IMPORTANT ADDITION)
router.put("/reject/:id", auth, async (req, res) => {
  try {
    await db.query("UPDATE vendors SET status='rejected' WHERE id=?", [
      req.params.id,
    ]);

    res.json({ message: "Vendor rejected" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;