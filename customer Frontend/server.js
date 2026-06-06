const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const cron = require("node-cron");
const multer = require("multer"); // for profile image upload
const path = require("path");
const fs = require("fs");
const db = require("./db");

require('dotenv').config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const SECRET = process.env.SECRET || "your-secret-key";

// (omitted other routes for brevity in this local copy)

// AI IMAGE GENERATOR (Hugging Face Stable Diffusion, free)
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
    console.log(`Using HF_API_KEY: ${process.env.HF_API_KEY.substring(0, 10)}...`);
    
    // Call Hugging Face Inference API (Stable Diffusion 1.5)
    const hfResponse = await fetch(
      "https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-5",
      {
        headers: {
          Authorization: `Bearer ${process.env.HF_API_KEY}`,
        },
        method: "POST",
        body: JSON.stringify({ inputs: prompt }),
      }
    );

    console.log(`HF Response status: ${hfResponse.status}`);

    if (!hfResponse.ok) {
      const errorText = await hfResponse.text();
      console.error(`Hugging Face API error ${hfResponse.status}:`, errorText);
      return res.status(hfResponse.status).json({
        status: "error",
        message: `Failed to generate image. ${errorText}`,
      });
    }

    // HF returns image bytes; convert to base64 data URL
    const buffer = await hfResponse.buffer();
    const imageUrl = `data:image/png;base64,${buffer.toString('base64')}`;
    console.log(`Image generated successfully, size: ${buffer.length} bytes`);

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
    console.error("AI Image Generation Error:", err);
    res.status(500).json({
      status: "error",
      message: `Failed to generate image. ${err.message}`,
    });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
