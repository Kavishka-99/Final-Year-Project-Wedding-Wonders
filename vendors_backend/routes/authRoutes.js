import express from "express";
import {
  signinVendor,
  forgotPassword,
  resetPassword,
} from "../controllers/vendorController.js";

const router = express.Router();

router.post("/signin", signinVendor);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);

export default router;