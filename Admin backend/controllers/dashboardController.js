import db from "../db.js";

export const getDashboardStats = async (req, res) => {
  try {
    const [vendors] = await db.query("SELECT COUNT(*) AS totalVendors FROM vendors");
    const [customers] = await db.query("SELECT COUNT(*) AS totalCustomers FROM customers");
    const [approved] = await db.query("SELECT COUNT(*) AS approved FROM vendors WHERE status='approved'");
    const [rejected] = await db.query("SELECT COUNT(*) AS rejected FROM vendors WHERE status='rejected'");
    const [subscribed] = await db.query("SELECT COUNT(*) AS subscribed FROM vendors WHERE is_subscribed=1");
    const [paid] = await db.query("SELECT COUNT(*) AS paid FROM vendors WHERE payment_status='paid'");

    res.json({
      success: true,
      data: {
        totalVendors: vendors[0].totalVendors,
        totalCustomers: customers[0].totalCustomers,
        approved: approved[0].approved,
        rejected: rejected[0].rejected,
        subscribed: subscribed[0].subscribed,
        paid: paid[0].paid,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};