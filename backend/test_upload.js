import axios from "axios";
import FormData from "form-data";
import fs from "fs";

const form = new FormData();

const report = {
  jobRef: "JOB-1001",
  dateTime: "2026-06-28T10:30:00.000Z",
  customerName: "Diesel Solutions LLC",
  siteLocation: "Dubai Industrial Area",
  contactPerson: "Ahmed Khan",
  contactNumber: "+971501234567",

  generatorMakeModel: "Cummins C150D5",
  capacity: "125 kVA",
  engineSerialNo: "ENG-001234",
  alternatorSerialNo: "ALT-001234",
  hourMeter: "8450",
  hours: "8450",
  batteryStatusVolt: "12.6 V",

  serviceChecklist: [
    {
      parameter: "Engine Oil Level & Quality",
      status: "ok",
    },
    {
      parameter: "Coolant Level & Protection",
      status: "req",
    },
    {
      parameter: "Battery Terminals & Charging",
      status: "ok",
    },
  ],

  partsUsed: [
    {
      partDescription: "Battery 12V 90Ah",
      qty: "1",
    },
    {
      partDescription: "B Check Kit",
      qty: "1",
    },
  ],

  observations:
    "Replaced new battery and completed oil service. Generator running normally.",

  nextServiceDueDate: "2026-12-28",
  nextServiceDueHours: "500",

  technicianName: "Siva",
  customerRepresentativeName: "John Smith",

  technicianDate: "2026-06-28",
  customerDate: "2026-06-28",
};

// Send JSON as a string
form.append("report", JSON.stringify(report));

// Replace with your actual image paths
form.append(
  "technicianSignature",
  fs.createReadStream("./signature.png")
);

form.append(
  "customerPhoto",
  fs.createReadStream("./customer.png")
);

try {
  const response = await axios.post(
    "http://localhost:5000/api/reports",
    form,
    {
      headers: form.getHeaders(),
      maxBodyLength: Infinity,
    }
  );

  console.log(response.data);
} catch (err) {
  console.error(err.response?.data || err.message);
}