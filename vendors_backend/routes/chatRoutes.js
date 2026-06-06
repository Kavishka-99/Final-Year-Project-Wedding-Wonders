import express from "express";
const router = express.Router();

import { sendMessage, getMessages } from "../controllers/chatController.js";

// Send message
router.post("/send", sendMessage);

// Get messages
router.get("/:customerId/:vendorId", getMessages);

export default router;