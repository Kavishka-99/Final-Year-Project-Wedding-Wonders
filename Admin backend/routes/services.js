import express from "express";

const router = express.Router();

// GET all services
router.get("/", (req, res) => {
  res.json({ message: "Services API working ✅" });
});

export default router;