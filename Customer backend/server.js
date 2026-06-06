const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const cron = require("node-cron");
const multer = require("multer"); // ✅ for profile image upload
const path = require("path");
const fs = require("fs");
const db = require("./db");

// Load environment variables from .env (e.g., HF_API_KEY)
require('dotenv').config();

const { HfInference } = require("@huggingface/inference");
const hf = new HfInference(process.env.HF_API_KEY);



const app = express();
app.use(cors());
app.use(bodyParser.json());

// Serve uploaded profile images
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const SECRET = process.env.SECRET || "your-secret-key"; // Change this for security

// DEBUG: Test HF API key
app.get("/api/debug/hf-key", (req, res) => {
  const key = process.env.HF_API_KEY;
  if (!key) return res.json({ status: "error", message: "HF_API_KEY not set" });
  res.json({
    status: "ok",
    keySet: true,
    keyPrefix: key.substring(0, 15) + "...",
    keyLength: key.length,
  });
});

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", server: "running" });
});

//------------------------------------
// 🧍 USER AUTHENTICATION
//------------------------------------

app.post("/register", async (req, res) => {
  const { name, email, password, phone, wedding_date, partner_email, pin } =
    req.body;
  const hashedPass = await bcrypt.hash(password, 10);
  const hashedPin = await bcrypt.hash(pin, 10);

  db.query(
    "INSERT INTO users (name, email, password, phone, wedding_date, partner_email, pin) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [name, email, hashedPass, phone, wedding_date, partner_email, hashedPin],
    (err) => {
      if (err) return res.json({ status: "error", message: err });
      res.json({ status: "success", message: "User registered successfully" });
    }
  );
});

app.post("/login", (req, res) => {
  const { email, password } = req.body;
  db.query("SELECT * FROM users WHERE email = ?", [email], async (err, result) => {
    if (err || result.length === 0)
      return res.json({ status: "error", message: "Invalid credentials" });
    const user = result[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.json({ status: "error", message: "Invalid credentials" });
    res.json({ status: "success", message: "Login successful", user });
  });
});

app.post("/login-pin", (req, res) => {
  const { email, pin } = req.body;
  db.query("SELECT * FROM users WHERE email = ?", [email], async (err, result) => {
    if (err || result.length === 0)
      return res.json({ status: "error", message: "Invalid PIN" });
    const user = result[0];
    const isMatch = await bcrypt.compare(pin, user.pin);
    if (!isMatch)
      return res.json({ status: "error", message: "Invalid PIN" });
    res.json({ status: "success", message: "PIN login successful", user });
  });
});

//------------------------------------
// 🔐 PASSWORD RESET
//------------------------------------

app.post("/forgot-password", (req, res) => {
  const { email } = req.body;
  db.query("SELECT * FROM users WHERE email = ?", [email], (err, result) => {
    if (err || result.length === 0)
      return res.json({ status: "error", message: "Email not found" });

    const token = jwt.sign({ email }, SECRET, { expiresIn: "15m" });
    const resetLink = `http://localhost:3000/reset-password/${token}`;

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "your-email@gmail.com",
        pass: "your-email-password",
      },
    });

    transporter.sendMail({
      from: "your-email@gmail.com",
      to: email,
      subject: "Password Reset",
      html: `<p>Click <a href="${resetLink}">here</a> to reset your password</p>`,
    });

    res.json({ status: "success", message: "Password reset email sent" });
  });
});

app.post("/reset-password/:token", async (req, res) => {
  const { token } = req.params;
  const { password } = req.body;
  try {
    const decoded = jwt.verify(token, SECRET);
    const hashedPass = await bcrypt.hash(password, 10);
    db.query(
      "UPDATE users SET password = ? WHERE email = ?",
      [hashedPass, decoded.email],
      (err) => {
        if (err) return res.json({ status: "error", message: err });
        res.json({ status: "success", message: "Password updated successfully" });
      }
    );
  } catch (e) {
    res.json({ status: "error", message: "Invalid or expired token" });
  }
});

//------------------------------------
// 🧑‍💼 USER PROFILE (NEW)
//------------------------------------

// ✅ Configure file upload for profile picture
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = "./uploads";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(
      null,
      Date.now() + "-" + Math.round(Math.random() * 1e9) + path.extname(file.originalname)
    );
  },
});
const upload = multer({ storage });

// ✅ Get user profile
app.get("/api/users/:id", (req, res) => {
  const userId = req.params.id;
  db.query(
    "SELECT id, name, email, phone, wedding_date, profile_image FROM users WHERE id = ?",
    [userId],
    (err, result) => {
      if (err) return res.status(500).json({ message: "Database error" });
      if (result.length === 0)
        return res.status(404).json({ message: "User not found" });
      res.json(result[0]);
    }
  );
});

// ✅ Update user profile (with optional image)
app.put("/api/users/:id", upload.single("profile_image"), (req, res) => {
  const userId = req.params.id;
  const { name, email, phone, wedding_date } = req.body;
  const imagePath = req.file ? `/uploads/${req.file.filename}` : null;

  db.query(
    "UPDATE users SET name=?, email=?, phone=?, wedding_date=?, profile_image=COALESCE(?, profile_image) WHERE id=?",
    [name, email, phone, wedding_date, imagePath, userId],
    (err) => {
      if (err) return res.status(500).json({ message: "Database error" });
      res.json({ message: "Profile updated successfully" });
    }
  );
});

//------------------------------------
// ✅ TO-DO LIST
//------------------------------------
app.get("/todos/:userId", (req, res) => {
  const userId = req.params.userId;
  const { priority, start, end } = req.query;
  let sql = "SELECT * FROM todo_items WHERE user_id = ?";
  const params = [userId];
  if (priority) {
    sql += " AND priority = ?";
    params.push(priority);
  }
  if (start && end) {
    sql += " AND due_date BETWEEN ? AND ?";
    params.push(start, end);
  }

  db.query(sql, params, (err, result) => {
    if (err) return res.status(500).send(err);
    res.json(result);
  });
});

app.post("/todos", (req, res) => {
  const { user_id, title, description, due_date, priority, recurring } = req.body;
  db.query(
    "INSERT INTO todo_items (user_id, title, description, due_date, priority, recurring) VALUES (?, ?, ?, ?, ?, ?)",
    [user_id, title, description, due_date, priority, recurring],
    (err, result) => {
      if (err) return res.status(500).send(err);
      res.json({ message: "Todo added successfully", id: result.insertId });
    }
  );
});

app.put("/todos/:id", (req, res) => {
  const id = req.params.id;
  const { is_done } = req.body;
  db.query("UPDATE todo_items SET is_done = ? WHERE id = ?", [is_done, id], (err) => {
    if (err) return res.status(500).send(err);
    res.json({ message: "Todo updated successfully" });
  });
});

app.delete("/todos/:id", (req, res) => {
  db.query("DELETE FROM todo_items WHERE id = ?", [req.params.id], (err) => {
    if (err) return res.status(500).send(err);
    res.json({ message: "Todo deleted successfully" });
  });
});

/// insert before the AI image route in server.js

let txCounter = 1;
const budgets = {};        // userId -> {category:planned}
const transactions = [];   // flat list

app.get('/budget/categories/:userId', (req, res) => {
  const user = req.params.userId;
  res.json(Object.entries(budgets[user]||{}).map(([c,p])=>({category:c,planned:p})));
});

app.post('/budget/category', (req,res)=>{
  const {user_id,category,planned} = req.body;
  budgets[user_id] ||= {};
  budgets[user_id][category] = planned;
  res.json({status:'ok'});
});

app.get('/budget/:userId', (req,res)=>{
  const user = req.params.userId;
  let list = transactions.filter(t=>t.user_id==user);
  if (req.query.category && req.query.category!=='All') {
    list = list.filter(t=>t.category===req.query.category);
  }
  if (req.query.start && req.query.end) {
    const s=new Date(req.query.start);
    const e=new Date(req.query.end);
    list = list.filter(t=>{
      const d=new Date(t.date);
      return d>=s && d<=e;
    });
  }
  res.json(list);
});

app.post('/budget/transaction', (req,res)=>{
  const t={id:txCounter++,...req.body};
  transactions.push(t);
  res.json({status:'ok',id:t.id});
});

app.delete('/budget/transaction/:id',(req,res)=>{
  const id=+req.params.id;
  const idx = transactions.findIndex(t=>t.id===id);
  if(idx!==-1) transactions.splice(idx,1);
  res.json({status:'ok'});
});

//------------------------------------
// 👥 GUEST MANAGEMENT
//------------------------------------
app.post("/api/guests", (req, res) => {
  const { user_id, prefix, name, email, whatsapp } = req.body;
  if (!name || !email || !whatsapp)
    return res.status(400).json({ message: "Missing fields" });

  db.query(
    "INSERT INTO guests (user_id, prefix, name, email, whatsapp) VALUES (?, ?, ?, ?, ?)",
    [user_id || 1, prefix, name, email, whatsapp],
    (err, result) => {
      if (err) return res.status(500).json({ message: "Database error" });
      db.query("INSERT INTO user_history (user_id, activity) VALUES (?, ?)", [
        user_id || 1,
        `Added new guest: ${name}`,
      ]);
      res.status(201).json({ id: result.insertId, message: "Guest Added" });
    }
  );
});

app.get("/api/guests", (req, res) => {
  db.query("SELECT * FROM guests ORDER BY created_at DESC", (err, results) => {
    if (err) return res.status(500).json({ message: "Database error" });
    res.json(results);
  });
});

app.put("/api/guests/:id", (req, res) => {
  const { prefix, name, email, whatsapp, is_invited, user_id } = req.body;
  const { id } = req.params;
  db.query(
    "UPDATE guests SET prefix=?, name=?, email=?, whatsapp=?, is_invited=? WHERE id=?",
    [prefix, name, email, whatsapp, is_invited, id],
    (err) => {
      if (err) return res.status(500).json({ message: "Database error" });
      db.query("INSERT INTO user_history (user_id, activity) VALUES (?, ?)", [
        user_id || 1,
        `Updated guest: ${name}`,
      ]);
      res.json({ message: "Guest Updated" });
    }
  );
});

app.delete("/api/guests/:id", (req, res) => {
  const { id } = req.params;
  const { user_id, name } = req.body;
  db.query("DELETE FROM guests WHERE id=?", [id], (err) => {
    if (err) return res.status(500).json({ message: "Database error" });
    db.query("INSERT INTO user_history (user_id, activity) VALUES (?, ?)", [
      user_id || 1,
      `Deleted guest with ID ${id}`,
    ]);
    res.json({ message: "Guest Deleted" });
  });
});

app.patch("/api/guests/invite/:id", (req, res) => {
  const { id } = req.params;
  const { user_id } = req.body;
  db.query("UPDATE guests SET is_invited = TRUE WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ message: "Database error" });
    db.query("INSERT INTO user_history (user_id, activity) VALUES (?, ?)", [
      user_id || 1,
      `Guest ID ${id} marked as invited`,
    ]);
    res.json({ message: "Guest marked as invited" });
  });
});

// ------------------------------------
// 🤖 AI IMAGE GENERATOR (Hugging Face Stable Diffusion, free)
// ------------------------------------

// Helper: save image and log activity
function saveImageAndHistory(user_id, prompt, imageUrl, res) {
  // 💾 Save to MySQL
  db.query(
    "INSERT INTO images (user_id, prompt, image_url) VALUES (?, ?, ?)",
    [user_id || null, prompt, imageUrl.substring(0, 65535)], // Truncate if too long for DB
    (err) => {
      if (err) console.error("AI image save error:", err);
    }
  );

  // 🕓 Also log in user history
  if (user_id) {
    db.query(
      "INSERT INTO user_history (user_id, activity) VALUES (?, ?)",
      [user_id, `Generated AI image for prompt: "${prompt}"`],
      (err) => {
        if (err) console.error("History save error:", err);
      }
    );
  }

  res.json({ status: "success", imageUrl });
}

// ------------------------------------
// 🤖 AI IMAGE GENERATOR (Hugging Face Stable Diffusion, free)
// ------------------------------------
app.post("/api/ai-image", async (req, res) => {
  const { user_id, prompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ status: "error", message: "Prompt is required" });
  }

  if (!process.env.HF_API_KEY) {
    console.error('HF_API_KEY not set');
    return res.status(500).json({ status: 'error', message: 'HF_API_KEY not set on server' });
  }

  try {
    // DEPRECATED: The old api-inference.huggingface.co endpoint now returns 410 (Gone)
    // ACTION REQUIRED: Use the official @huggingface/inference JavaScript client or Hugging Face's official docs
    // to access Inference Providers. See: https://huggingface.co/docs/inference-providers/
    // For now, returning a helpful error message with migration guidance.
    
    const migrationMsg = `
      The Hugging Face Inference API endpoint has been migrated.
      To fix this:
      1. Install the official client: npm install @huggingface/inference
      2. Use InferenceClient for text-to-image generation
      Docs: https://huggingface.co/docs/inference-providers/
    `;
    
    console.warn("Image generation endpoint requires migration to Inference Providers");
    
    return res.status(410).json({
      status: "error",
      message: "Image generation service migrated. Please update your integration.",
      details: migrationMsg.trim(),
    });
  } catch (err) {
    console.error("AI Image Generation Error:", err);
    res.status(500).json({
      status: "error",
      message: process.env.NODE_ENV === 'production' ? 'Image generation failed' : err.message,
    });
  }
});

// � AI IMAGE GENERATOR (Hugging Face, free)
app.post("/api/ai-image", async (req, res) => {
  const { user_id, prompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ status: "error", message: "Prompt is required" });
  }

  if (!process.env.HF_API_KEY) {
    console.error('HF_API_KEY not set');
    return res.status(500).json({ status: 'error', message: 'HF_API_KEY not set on server' });
  }

  try {
    console.log(`Generating image for prompt: "${prompt}"`);
    
    // Call Hugging Face with official client
    const blob = await hf.textToImage({
      model: "stabilityai/stable-diffusion-2",
      inputs: prompt,
    });

    console.log(`Image generated, blob size: ${blob.size} bytes`);

    // Convert blob to buffer
    const buffer = await blob.arrayBuffer();
    const imageUrl = `data:image/png;base64,${Buffer.from(buffer).toString('base64')}`;
    console.log(`Image converted to base64, URL length: ${imageUrl.length}`);

    // Save to MySQL (best-effort)
    db.query(
      "INSERT INTO images (user_id, prompt, image_url) VALUES (?, ?, ?)",
      [user_id || null, prompt, imageUrl.substring(0, 65535)],
      (err) => {
        if (err) console.error("AI image save error:", err);
      }
    );

    if (user_id) {
      db.query(
        "INSERT INTO user_history (user_id, activity) VALUES (?, ?)",
        [user_id, `Generated AI image for prompt: "${prompt}"`],
        (err) => {
          if (err) console.error("History save error:", err);
        }
      );
    }

    res.json({ status: "success", imageUrl });
  } catch (err) {
    console.error("AI Image Generation Error:", err.message || err);
    res.status(500).json({
      status: "error",
      message: `Failed to generate image. ${err.message}`,
    });
  }
});
app.get("/api/ai-images/:userId", (req, res) => {
  const userId = req.params.userId;
  db.query(
    "SELECT * FROM images WHERE user_id = ? ORDER BY created_at DESC",
    [userId],
    (err, results) => {
      if (err) return res.status(500).json({ message: "Database error" });
      res.json(results);
    }
  );
});

//------------------------------------
// 🚀 SERVER
//------------------------------------
app.listen(5000, () => console.log("🚀 Server running on port 5000"));
