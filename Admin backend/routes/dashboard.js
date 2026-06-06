import express from "express";
import { getDashboardStats } from "../controllers/dashboardController.js";

const router = express.Router();

// Dashboard stats
router.get("/dashboard-stats", getDashboardStats);

export default router;