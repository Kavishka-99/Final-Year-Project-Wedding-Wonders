import express from "express";
import db from "../db.js";
import bcrypt from "bcryptjs";

const router = express.Router();

// ADD vendor
router.post("/", async (req, res) => {
  const { name, email, password, phone } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    const sql = "INSERT INTO vendors (name, email, password, phone) VALUES (?, ?, ?, ?)";
    
    db.query(sql, [name, email, hashedPassword, phone], (err, result) => {
      if (err) return res.status(500).json(err);

      res.json({
        success: true,
        message: "Vendor registered successfully"
      });
    });

  } catch (err) {
    res.status(500).json(err);
  }
});

export default router;