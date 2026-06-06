const db = require("../db");
const bcrypt = require("bcrypt");

// Vendor Signup
exports.signupVendor = async (req, res) => {
  const { name, email, password, phone } = req.body;

  if (!name || !email || !password || !phone) {
    return res.status(400).json({ message: "All fields required" });
  }

  try {
    // Check if email exists
    db.query(
      "SELECT * FROM vendors WHERE email = ?",
      [email],
      async (err, results) => {
        if (results.length > 0) {
          return res.status(400).json({ message: "Email already exists" });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert vendor
        db.query(
          "INSERT INTO vendors (name, email, password, phone) VALUES (?, ?, ?, ?)",
          [name, email, hashedPassword, phone],
          (err, result) => {
            if (err) {
              return res.status(500).json({ message: "DB error", err });
            }

            res.status(201).json({
              message: "Vendor registered successfully",
              vendorId: result.insertId,
            });
          }
        );
      }
    );
  } catch (error) {
    res.status(500).json({ message: "Server error", error });
  }
};