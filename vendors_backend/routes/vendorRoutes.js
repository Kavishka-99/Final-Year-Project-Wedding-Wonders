import express from "express";
import { addService, upload, getVendorServices } from "../controllers/vendorController.js";

const router = express.Router();

router.post("/addService", upload.single("image"), addService);
router.get("/getServices/:vendor_id", getVendorServices);

router.get("/dashboard/:id", (req, res) => {
  const vendorId = req.params.id;

  const sqlVendor = "SELECT name, email FROM vendors WHERE id = ?";
  const sqlServices = "SELECT COUNT(*) AS services FROM services WHERE vendor_id = ?";
  const sqlBookings = "SELECT COUNT(*) AS bookings FROM bookings WHERE vendor_id = ?";

  db.query(sqlVendor, [vendorId], (err, vendorResult) => {
    if (err) return res.status(500).json(err);

    db.query(sqlServices, [vendorId], (err, serviceResult) => {
      db.query(sqlBookings, [vendorId], (err, bookingResult) => {

        return res.json({
          name: vendorResult[0]?.name || "",
          email: vendorResult[0]?.email || "",
          rating: 4.5,
          services: serviceResult[0]?.services || 0,
          bookings: bookingResult[0]?.bookings || 0,
          earnings: 5000,
        });

      });
    });
  });
});

export default router;
