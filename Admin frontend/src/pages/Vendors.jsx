import { useEffect, useState } from "react";
import axios from "axios";

export default function Vendors() {
  const [vendors, setVendors] = useState([]);

  useEffect(() => {
    axios.get("http://localhost:5001/api/vendors")
      .then(res => setVendors(res.data));
  }, []);

  const approve = (id) => {
    axios.put(`http://localhost:5001/api/vendors/approve/${id}`)
      .then(() => window.location.reload());
  };

  return (
    <div>
      <h2>Vendors</h2>
      {vendors.map(v => (
        <div key={v.id}>
          {v.name} - {v.status}
          <button onClick={() => approve(v.id)}>Approve</button>
        </div>
      ))}
    </div>
  );
}