import express from "express";
import {
  addService,
  getVendorServices,
  deleteService,
  updateService
} from "../controllers/serviceController.js";

const router = express.Router();

router.post("/", addService);
router.get("/vendor/:vendorId", getVendorServices);
router.delete("/:id", deleteService);
router.put("/:id", updateService);

export default router;