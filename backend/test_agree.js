import axios from "axios";
import FormData from "form-data";
import fs from "fs";

const form = new FormData();

const agreement = {
  documentType: "Quotation",

  customerName: "SMR Srujana Apartment",
  completeAddress:
    "SR Nagar, Hyderabad, Telangana - 500038",

  contactPerson: "Mr. Chakradhar",
  mobileNumber: "9440092345",

  gstRequired: true,
  gstPercentage: 18,

  descriptionItems: [
    {
      description:
        "06 Visits in 1 Year (12-06-2026 to 11-06-2027) for 6 DG Sets",
      quantity: 1,
      rate: 8500,
    },
    {
      description:
        "Emergency Breakdown Support",
      quantity: 1,
      rate: 2500,
    },
  ],

  termsAndConditions:
    "AMC customers will receive priority support and scheduled preventive maintenance.",

  paymentTerms:
    "100% Advance Payment.",

  offerValidity:
    "30 Days",

  notes:
    "The above price is only for service visits. Spares extra at actual.",

  footerText:
    "Thank you for your business.",
};

// JSON Payload
form.append("agreement", JSON.stringify(agreement));

// Customer Signature
form.append(
  "customerSignature",
  fs.createReadStream("./customer.png")
);

try {
  const response = await axios.post(
    "http://localhost:5000/api/agreements",
    form,
    {
      headers: form.getHeaders(),
      maxBodyLength: Infinity,
    }
  );

  console.log("================================");
  console.log("Agreement Created Successfully");
  console.log("================================");
  console.log(response.data);
} catch (err) {
  console.log("================================");
  console.log("Agreement Creation Failed");
  console.log("================================");

  if (err.response) {
    console.log(err.response.data);
  } else {
    console.log(err.message);
  }
}
