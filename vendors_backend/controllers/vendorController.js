import db from "../db.js";
import multer from "multer";
import path from "path";
import bcrypt from "bcryptjs";
import crypto from "crypto";
import validator from "validator";

// ---------------- IMAGE UPLOAD ----------------
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

export const upload = multer({ storage });

// ---------------- GET SERVICES ----------------
export const getVendorServices = (req, res) => {
  const { vendor_id } = req.params;

  const sql = "SELECT * FROM services WHERE vendor_id = ?";
  db.query(sql, [vendor_id], (err, results) => {
    if (err) {
      console.error("DB Error:", err);
      return res.status(500).json({ error: "Database error" });
    }

    return res.status(200).json(results);
  });
};

// ---------------- ADD SERVICE ----------------
export const addService = (req, res) => {
  const {
    vendor_id,
    title,
    description,
    category,
    location,
    price,
    availability,
  } = req.body;

  const image = req.file ? req.file.filename : null;

  if (
    !vendor_id ||
    !title ||
    !description ||
    !category ||
    !location ||
    !price ||
    !availability ||
    !image
  ) {
    return res.status(400).json({ error: "All fields are required" });
  }

  const sql =
    "INSERT INTO services (vendor_id, title, description, category, location, price, availability, image) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

  db.query(
    sql,
    [
      vendor_id,
      title,
      description,
      category,
      location,
      price,
      availability,
      image,
    ],
    (err) => {
      if (err) {
        console.error("DB Error:", err);
        return res.status(500).json({ error: "Database error" });
      }

      return res.status(200).json({
        success: true,
        message: "Service added successfully",
      });
    }
  );
};

// ---------------- SIGNIN ----------------
export const signinVendor = (req, res) => {
  const { email, password } = req.body;

  // ✅ Validation
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: "Email and password are required",
    });
  }

  if (!validator.isEmail(email)) {
    return res.status(400).json({
      success: false,
      message: "Invalid email format",
    });
  }

  if (password.length < 6) {
    return res.status(400).json({
      success: false,
      message: "Password must be at least 6 characters",
    });
  }

  const sql = "SELECT * FROM vendors WHERE email = ?";

  db.query(sql, [email], async (err, result) => {
    if (err) {
      console.error("DB Error:", err);
      return res.status(500).json({
        success: false,
        message: "Database error",
      });
    }

    if (!result || result.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found",
      });
    }

    const vendor = result[0];

    try {
      const isMatch = await bcrypt.compare(password, vendor.password);

      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: "Invalid password",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Signin successful",
        vendor: {
          id: vendor.id,
          name: vendor.name,
          email: vendor.email,
        },
      });
    } catch (error) {
      console.error("Compare Error:", error);
      return res.status(500).json({
        success: false,
        message: "Server error",
      });
    }
  });
};

// ---------------- FORGOT PASSWORD ----------------
export const forgotPassword = (req, res) => {
  const { email } = req.body;

  if (!validator.isEmail(email)) {
    return res.status(400).json({
      success: false,
      message: "Invalid email",
    });
  }

  const token = crypto.randomBytes(32).toString("hex");

  const sql = "UPDATE vendors SET reset_token = ? WHERE email = ?";

  db.query(sql, [token, email], (err, result) => {
    if (err) {
      console.error("DB Error:", err);
      return res.status(500).json({
        success: false,
        message: "Database error",
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: "Email not found",
      });
    }

    return res.json({
      success: true,
      message: "Reset token generated",
      token: token,
    });
  });
};

// ---------------- RESET PASSWORD ----------------
export const resetPassword = async (req, res) => {
  const { token, newPassword } = req.body;

  if (!newPassword || newPassword.length < 6) {
    return res.status(400).json({
      success: false,
      message: "Password must be at least 6 characters",
    });
  }

  try {
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    const sql =
      "UPDATE vendors SET password = ?, reset_token = NULL WHERE reset_token = ?";

    db.query(sql, [hashedPassword, token], (err, result) => {
      if (err) {
        console.error("DB Error:", err);
        return res.status(500).json({
          success: false,
          message: "Database error",
        });
      }

      if (result.affectedRows === 0) {
        return res.status(400).json({
          success: false,
          message: "Invalid token",
        });
      }

      return res.json({
        success: true,
        message: "Password reset successful",
      });
    });
  } catch (error) {
    console.error("Hash Error:", error);
    return res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
};