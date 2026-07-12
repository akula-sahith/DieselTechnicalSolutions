# Estimate & Tax Invoice API Reference

## Base URL
```
http://localhost:3000/api
```

## Response Format
All endpoints follow a consistent response format:
```json
{
  "success": true/false,
  "message": "Success or error message",
  "data": {}
}
```

---

## Estimate Module

### 1. Create Estimate
**POST** `/estimates`

**Request Body:**
```json
{
  "estimateFor": {
    "customerName": "ABC Corporation",
    "address": "123 Industrial Park, City",
    "contactPerson": "John Doe",
    "contactNumber": "9876543210",
    "gstinNumber": "27AABCT1234H1Z0"
  },
  "placeOfSupply": "Delhi",
  "items": [
    {
      "itemName": "Diesel Engine",
      "hsnSac": "8412",
      "quantity": 2,
      "unit": "Pieces",
      "pricePerUnit": 50000,
      "taxApplicable": true,
      "gstPercentage": 18
    }
  ],
  "termsAndConditions": "Payment terms: Net 30 days",
  "authorizedSignatureUrl": "https://cloudinary.com/..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Estimate created successfully.",
  "data": {
    "estimate": {
      "_id": "507f1f77bcf86cd799439011",
      "estimateNumber": "EST-2026-0001",
      "estimateDate": "2024-01-15T10:30:00Z",
      "estimateFor": {
        "customerName": "ABC Corporation",
        "address": "123 Industrial Park, City",
        "contactPerson": "John Doe",
        "contactNumber": "9876543210",
        "gstinNumber": "27AABCT1234H1Z0"
      },
      "placeOfSupply": "Delhi",
      "items": [
        {
          "itemName": "Diesel Engine",
          "hsnSac": "8412",
          "quantity": 2,
          "unit": "Pieces",
          "pricePerUnit": 50000,
          "taxApplicable": true,
          "gstPercentage": 18,
          "sgst": 9000,
          "cgst": 9000,
          "amount": 118000
        }
      ],
      "subtotal": 100000,
      "totalTax": 18000,
      "totalAmount": 118000,
      "amountInWords": "One Lakh Eighteen Thousand Rupees Only",
      "termsAndConditions": "Payment terms: Net 30 days",
      "authorizedSignatureUrl": "https://cloudinary.com/...",
      "status": "draft",
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    },
    "payment": {
      "qrBase64": "data:image/png;base64,iVBORw0KGgoAAAANS...",
      "clickToPayLink": "upi://pay?pa=gps%40upi&pn=Diesel+Technical+Solutions&am=118000&cu=INR&tn=EST-2026-0001",
      "upiPaymentUri": "upi://pay?pa=gps%40upi&pn=Diesel+Technical+Solutions&am=118000&cu=INR&tn=EST-2026-0001",
      "payableAmount": 118000,
      "companyUpiId": "gps@upi",
      "companyName": "Diesel Technical Solutions"
    },
    "bankDetails": {
      "companyName": "Diesel Technical Solutions",
      "bankName": "ICICI Bank",
      "accountHolderName": "Diesel Technical Solutions",
      "accountNumber": "***2891",
      "ifscCode": "ICIC0000001",
      "upiId": "gps@upi",
      "gstNumber": "27AABFD1122H1Z5",
      "phoneNumber": "9876543210",
      "email": "dieseltechnicalsolutions@zohomail.in"
    }
  }
}
```

---

### 2. Get All Estimates
**GET** `/estimates?page=1&limit=10&search=ABC`

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Records per page (default: 10)
- `search` - Search by customer name, contact number

**Response:**
```json
{
  "success": true,
  "message": "Estimates retrieved successfully.",
  "data": {
    "estimates": [
      {
        "estimate": { ...same as create response... },
        "payment": { ...payment data with qrBase64, clickToPayLink... },
        "bankDetails": { ...company bank details... }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 25,
      "totalPages": 3
    }
  }
}
```

---

### 3. Get Estimate by ID
**GET** `/estimates/:id`

**Response:**
```json
{
  "success": true,
  "message": "Estimate retrieved successfully.",
  "data": {
    "estimate": { ...full estimate object... },
    "payment": { ...payment data... },
    "bankDetails": { ...company bank details... }
  }
}
```

---

### 4. Update Estimate
**PATCH** `/estimates/:id`

**Request Body:** Same as create, but all fields optional

**Response:** Same as create response with updated values

---

### 5. Convert Estimate to Tax Invoice
**POST** `/estimates/:id/convert-to-invoice`

**Request Body:**
```json
{
  "invoiceDate": "2024-01-20",
  "advanceAmountReceived": 50000,
  "advancePaymentMethod": "Bank Transfer",
  "advanceReferenceNumber": "TXN123456789",
  "transportationDetails": {
    "vehicleNumber": "DL01AB1234",
    "transportName": "XYZ Logistics",
    "lrNumber": "LR123456",
    "dispatchDetails": "Dispatched on 2024-01-20",
    "deliveryDetails": "Expected delivery 2024-01-25"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Estimate converted to Tax Invoice successfully.",
  "data": {
    "estimate": {
      "_id": "507f1f77bcf86cd799439011",
      "status": "converted"
    },
    "taxInvoice": {
      "_id": "507f1f77bcf86cd799439012",
      "invoiceNumber": "INV-2026-0001",
      "invoiceDate": "2024-01-20T00:00:00Z",
      "billTo": { ...customer details... },
      "items": [ ...items from estimate... ],
      "subtotal": 100000,
      "totalTax": 18000,
      "totalAmount": 118000,
      "amountInWords": "One Lakh Eighteen Thousand Rupees Only",
      // Tax Invoice does not include payment artifacts (QR/Click-to-Pay/bank details).
      // Payments are collected and tracked via the Estimate resource. The Tax Invoice is a billing document only.
      "linkedEstimateId": "507f1f77bcf86cd799439011",
      "status": "sent"
    }
  }
}
```

---

## Tax Invoice Module

### 1. Create Tax Invoice
**POST** `/tax-invoices`

**Request Body:**
```json
{
  "invoiceDate": "2024-01-15",
  "billTo": {
    "customerName": "ABC Corporation",
    "address": "123 Industrial Park, City",
    "contactPerson": "John Doe",
    "contactNumber": "9876543210",
    "gstinNumber": "27AABCT1234H1Z0"
  },
  "placeOfSupply": "Delhi",
  "transportationDetails": {
    "vehicleNumber": "DL01AB1234",
    "transportName": "XYZ Logistics",
    "lrNumber": "LR123456"
  },
  "items": [
    {
      "itemName": "Diesel Engine",
      "hsnSac": "8412",
      "quantity": 2,
      "unit": "Pieces",
      "pricePerUnit": 50000,
      "taxApplicable": true,
      "gstPercentage": 18
    }
  ],
  "paymentDetails": {
    "advanceAmountReceived": 0,
    "paymentMethod": "UPI"
  },
  "termsAndConditions": "Payment terms: Net 7 days",
  "authorizedSignatureUrl": "https://cloudinary.com/..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Tax Invoice created successfully.",
  "data": {
    "invoiceNumber": "INV-2026-0001",
    "invoiceDate": "2024-01-15T00:00:00Z",
    "billTo": { ...customer details... },
    "items": [ ...items with GST split... ],
    "totalAmount": 118000,
    "paymentDetails": {
      "totalAmount": 118000,
      "advanceAmountReceived": 0,
      "remainingAmount": 118000,
      "status": "Unpaid",
      "paymentHistory": []
    },
    "payment": {
      "qrBase64": "data:image/png;base64,...",
      "clickToPayLink": "upi://pay?pa=gps%40upi&...",
      "upiPaymentUri": "upi://pay?pa=gps%40upi&...",
      "payableAmount": 118000,
      "companyUpiId": "gps@upi",
      "companyName": "Diesel Technical Solutions"
    },
    "bankDetails": { ...company bank details... }
  }
}
```

---

### 2. Get All Tax Invoices
**GET** `/tax-invoices?page=1&limit=10`

**Query Parameters:**
- `page` - Page number
- `limit` - Records per page

**Response:** Returns array of billing-only invoices (no payment QR or bank details attached)

---

### 3. Get Tax Invoice by ID
**GET** `/tax-invoices/:id`

**Response:**
```json
{
  "success": true,
  "message": "Tax Invoice retrieved successfully.",
  "data": {
    "invoiceNumber": "INV-2026-0001",
    "totalAmount": 118000,
    "paymentDetails": { ...payment tracking... },
    "payment": { ...payment data with QR for remaining amount... },
    "bankDetails": { ...company bank details... }
  }
}
```

---

### 4. Update Tax Invoice
**PATCH** `/tax-invoices/:id`

**Request Body:** Partial update of invoice fields

**Response:** Updated invoice with regenerated payment data

---

### Update Payment Status
Invoice-level payment updates are not supported. Use the Estimate payment flow to collect payment; once payment is complete, create the Tax Invoice. The backend upserts/creates the `Customer` record and appends invoice history during conversion.

---

## Payment System Architecture

### Key Features:
1. **Backend-Only Configuration**: All company payment details stored in backend config
2. **Dynamic QR Generation**: QR codes generated on every request, never stored
3. **Payment Tracking**: Full payment history with multiple payment support
4. **Partial Payments**: Support for advance and remaining amount tracking
5. **Auto-Numbering**: Estimate (EST-YYYY-NNNN) and Invoice (INV-YYYY-NNNN)
6. **GST Calculation**: Automatic SGST/CGST calculation backend-only

### Response Fields:

**payment object:**
- `qrBase64` - Base64 encoded QR code PNG (for QR display)
- `clickToPayLink` - UPI URI (for Click-to-Pay button)
- `upiPaymentUri` - Raw UPI URI (alternative link)
- `payableAmount` - Amount to be paid (total or remaining)
- `companyUpiId` - Company UPI ID for display
- `companyName` - Company name for customer reference

**bankDetails object:**
- `companyName` - Display name
- `bankName` - Bank name
- `accountHolderName` - Account holder
- `accountNumber` - Masked account number (last 4 digits only)
- `ifscCode` - IFSC code
- `upiId` - UPI ID
- `gstNumber` - GST registration number
- `phoneNumber` - Contact number
- `email` - Email address

### Payment Flow:
1. Estimate created → Payment QR generated for full amount
2. Estimate converted to Invoice with advance amount → Invoice payment QR for remaining amount
3. Invoice payment updated → Payment history tracked, status auto-calculated
4. Multiple payments supported → Sum of paymentHistory = total received

---

## Error Responses

**400 Bad Request:**
```json
{
  "success": false,
  "message": "Validation error message",
  "data": { "details": "..." }
}
```

**404 Not Found:**
```json
{
  "success": false,
  "message": "Resource not found",
  "data": {}
}
```

**500 Server Error:**
```json
{
  "success": false,
  "message": "Failed to process request",
  "data": { "details": "Error details" }
}
```

---

## Important Notes

1. **No Frontend Bank Details**: Frontend never sends or receives bank account details
2. **Dynamic QR Codes**: Each API response generates fresh QR codes (valid for 10+ days)
3. **Payment Calculations**: All amounts calculated backend-only; frontend displays only
4. **Auto-Numbering**: Sequence generated server-side, never by client
5. **GST Handling**: GST automatically calculated per item; supports multiple rates
6. **Timestamps**: All dates in ISO 8601 format with UTC timezone
