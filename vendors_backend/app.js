import express from "express";
import cors from "cors";
import bodyParser from "body-parser";
import http from "http";
import { Server } from "socket.io";

import db from "./db.js";
import serviceRoutes from "./routes/serviceRoutes.js";
import vendorRoutes from "./routes/vendorRoutes.js";
import signupRoutes from "./routes/signup.js";
import authRoutes from "./routes/authRoutes.js";
import chatRoutes from "./routes/chatRoutes.js";

const app = express();
const server = http.createServer(app); // ✅ important

// Socket.io setup
const io = new Server(server, {
  cors: {
    origin: "*",
  },
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use("/uploads", express.static("uploads"));

// Routes
app.use("/api/chat", chatRoutes);
app.use("/api/vendor", vendorRoutes);
app.use("/api/signup", signupRoutes);
app.use("/api", authRoutes);
app.use("/api/services", serviceRoutes);

// Socket logic
io.on("connection", (socket) => {
  console.log("User connected:", socket.id);

  socket.on("send_message", (data) => {
    db.query(
      "INSERT INTO messages (customer_id, vendor_id, sender, message) VALUES (?, ?, ?, ?)",
      [
        data.customer_id,
        data.vendor_id,
        data.sender,
        data.message,
      ]
    );

    // Send to others only
    socket.broadcast.emit("receive_message", data);
  });

  socket.on("disconnect", () => {
    console.log("User disconnected:", socket.id);
  });
});

// Server start
const PORT = 3000;

server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});