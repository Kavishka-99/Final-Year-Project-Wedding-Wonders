import { useEffect, useState } from "react";
import api from "../api";
import Sidebar from "../Layout/Sidebar";

export default function Dashboard() {
  const [vendors, setVendors] = useState([]);
  const [services, setServices] = useState([]);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const v = await api.get("/vendors");
      const s = await api.get("/services");

      setVendors(v.data);
      setServices(s.data);
    } catch (err) {
      console.log(err.response?.data || err.message);
    }
  };

  return (
    <div style={{ display: "flex" }}>
      <Sidebar />

      <div style={{ marginLeft: 240, padding: 20 }}>
        <h1>Dashboard</h1>

        <h3>Vendors: {vendors.length}</h3>
        <h3>Services: {services.length}</h3>
      </div>
    </div>
  );
}