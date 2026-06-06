import db from "../db.js";

export const addService = (req, res) => {
  const {
    vendor_id,
    title,
    description,
    category,
    location,
    price,
    availability
  } = req.body;

  const image = req.file ? req.file.filename : null;

  const sql = `
    INSERT INTO services 
    (vendor_id, title, description, category, location, price, availability, image)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `;

  db.query(
    sql,
    [vendor_id, title, description, category, location, price, availability, image],
    (err, result) => {
      if (err) {
        console.log(err);
        return res.status(500).json(err);
      }
      res.json({ message: "Service added" });
    }
  );
};
export const getVendorServices = (req, res) => {
  const { vendorId } = req.params;

  const sql = "SELECT * FROM services WHERE vendor_id = ?";

  db.query(sql, [vendorId], (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
};

export const deleteService = (req, res) => {
  const { id } = req.params;

  db.query("DELETE FROM services WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json(err);
    res.json({ message: "Deleted successfully" });
  });
};

export const updateService = (req, res) => {
  const { id } = req.params;
  const { name, description, price } = req.body;

  const sql = `
    UPDATE services 
    SET name = ?, description = ?, price = ?
    WHERE id = ?
  `;

  db.query(sql, [name, description, price, id], (err) => {
    if (err) return res.status(500).json(err);
    res.json({ message: "Updated successfully" });
  });
};

