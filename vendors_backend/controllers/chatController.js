import db from "../db.js";

// Send Message
export const sendMessage = (req, res) => {
  const { customer_id, vendor_id, sender, message } = req.body;

  const sql = `
    INSERT INTO messages (customer_id, vendor_id, sender, message)
    VALUES (?, ?, ?, ?)
  `;

  db.query(sql, [customer_id, vendor_id, sender, message], (err) => {
    if (err) return res.status(500).json(err);
    res.json({ success: true });
  });
};

// Get Messages
export const getMessages = (req, res) => {
  const { customerId, vendorId } = req.params;

  const sql = `
    SELECT * FROM messages
    WHERE customer_id = ? AND vendor_id = ?
    ORDER BY created_at ASC
  `;

  db.query(sql, [customerId, vendorId], (err, result) => {
    if (err) return res.status(500).json(err);
    res.json(result);
  });
};