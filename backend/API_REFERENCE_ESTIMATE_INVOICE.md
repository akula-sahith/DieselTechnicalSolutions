# Estimate & Tax Invoice Module - API Reference

## Overview

Two new business document modules have been integrated into the DTS backend:

1. **Estimate** - Generate quotations with auto-numbered offers (EST-2026-0001, EST-2026-0002, etc.)
2. **Tax Invoice** - Generate tax invoices with auto-numbered documents (INV-2026-0001, INV-2026-0002, etc.)

Both modules follow the existing DTS backend patterns and architecture.

---

## Architecture Pattern

### Response Format
All endpoints return consistent JSON responses:

**Success (200/201):**
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { /* actual data */ }
}
```

**Error (4xx/5xx):**
```json
{
  "success": false,
  "message": "Error description",
  "error": { "details": "Technical details" }
}
```

### Business Rules

#### All Financial Calculations are Backend-Only
- ❌ Frontend must NOT calculate amounts
- ❌ Frontend must NOT calculate taxes  
- ❌ Frontend must NOT calculate totals
- ✅ Backend calculates all financial values
- ✅ Backend validates all received values

#### Auto-Number Generation
- Estimate numbers: `EST-YYYY-NNNN` (auto-incremented, unique)
- Invoice numbers: `INV-YYYY-NNNN` (auto-incremented, unique)
- Numbers generated **only by backend** during creation
- Frontend must **never** send these numbers

#### GST Calculation
- GST percentage options: 0, 0.25, 3, 5, 12, 18, 28, 40
- Backend splits GST into SGST and CGST: `SGST = GST/2`, `CGST = GST/2`
- If tax disabled: GST = 0, SGST = 0, CGST = 0

#### Item Amounts
- `amount = (quantity × pricePerUnit) + SGST + CGST`
- Always calculated on backend

---

## ESTIMATE API

### Create Estimate
**POST** `/api/estimates`

**Request Body (multipart/form-data or JSON):**
```json
{
  "estimate": {
    "estimateDate": "2026-07-07",
    "estimateFor": {
      "customerName": "ABC Company",
      "address": "123 Main Street, City, State 12345",
      "contactPerson": "John Doe",
      "contactNumber": "+91-9876543210",
      "gstinNumber": "36AAFGU5055K1Z1"
    },
    "placeOfSupply": "36-Telangana",
    "items": [
      {
        "itemName": "Engine oil 50 liters",
        "hsnSac": "1509.90",
        "quantity": 1,
        "unit": "-",
        "pricePerUnit": 29000,
        "taxApplicable": true,
        "gstPercentage": 18
      },
      {
        "itemName": "Lube oil filter",
        "hsnSac": "8481.80",
        "quantity": 1,
        "unit": "Pcs",
        "pricePerUnit": 3800,
        "taxApplicable": true,
        "gstPercentage": 18
      }
    ],
    "bankDetails": {
      "bankName": "ICICI Bank",
      "accountNumber": "1234567890",
      "ifscCode": "ICIC0000001",
      "upiId": "gps@upi",
      "qrCodeUrl": "https://..."
    },
    "termsAndConditions": "Thank you for doing business with us.\n*100% advance is mandatory"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Estimate created successfully.",
  "data": {
    "_id": "507f1f77bcf86cd799439011",
    "estimateNumber": "EST-2026-0001",
    "estimateDate": "2026-07-07T00:00:00Z",
    "estimateFor": {...},
    "items": [
      {
        "itemName": "Engine oil 50 liters",
        "quantity": 1,
        "pricePerUnit": 29000,
        "taxApplicable": true,
        "gstPercentage": 18,
        "sgst": 2610,
        "cgst": 2610,
        "amount": 34220
      },
      {
        "itemName": "Lube oil filter",
        "quantity": 1,
        "pricePerUnit": 3800,
        "taxApplicable": true,
        "gstPercentage": 18,
        "sgst": 342,
        "cgst": 342,
        "amount": 4484
      }
    ],
    "subtotal": 32800,
    "totalTax": 6108,
    "totalAmount": 38908,
    "amountInWords": "Thirty Eight Thousand Nine Hundred and Eight Rupees Only",
    "status": "draft",
    "createdAt": "2026-07-07T10:30:00Z",
    "updatedAt": "2026-07-07T10:30:00Z"
  }
}
```

### List Estimates
**GET** `/api/estimates`

**Query Parameters:**
```
page=1                          // Default: 1
limit=10                        // Default: 10, Max: 50
search=EST-2026-0001            // Search by number/customer/phone
status=draft                    // Filter by: draft, sent, accepted, rejected, converted
customerName=ABC Company        // Filter by customer
estimateNumber=EST-2026-0001    // Filter by estimate number
dateFrom=2026-07-01             // Date range (ISO format)
dateTo=2026-07-31               // Date range (ISO format)
```

**Response (200):**
```json
{
  "success": true,
  "message": "Estimates retrieved successfully.",
  "data": {
    "estimates": [
      { /* estimate documents */ }
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

### Get Estimate by ID
**GET** `/api/estimates/:id`

**Response (200):**
```json
{
  "success": true,
  "message": "Estimate retrieved successfully.",
  "data": { /* full estimate document */ }
}
```

### Update Estimate
**PUT** `/api/estimates/:id`

**Notes:**
- Cannot update estimates with status "converted"
- All financial values automatically recalculated
- Send full payload (partial updates merge with existing data)

**Response (200):**
```json
{
  "success": true,
  "message": "Estimate updated successfully.",
  "data": { /* updated estimate */ }
}
```

### Delete Estimate
**DELETE** `/api/estimates/:id`

**Notes:**
- Cannot delete estimates with status "converted"

**Response (200):**
```json
{
  "success": true,
  "message": "Estimate deleted successfully.",
  "data": {}
}
```

### Convert Estimate to Tax Invoice
**POST** `/api/estimates/:id/convert-to-invoice`

**Request Body (JSON):**
```json
{
  "taxInvoice": {
    "invoiceDate": "2026-07-07",
    "transportationDetails": {
      "vehicleNumber": "TS-09-AB-1234",
      "transportName": "ABC Logistics",
      "lrNumber": "LR-2026-0001",
      "dispatchDetails": "Dispatched on 2026-07-07",
      "deliveryDetails": "To be delivered within 3 days"
    }
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Estimate converted to Tax Invoice successfully.",
  "data": {
    "estimate": {
      "_id": "507f1f77bcf86cd799439011",
      "status": "converted"
    },
    "taxInvoice": { /* full invoice document */ }
  }
}
```

**Automatic Copying:**
- ✅ Customer Details (name, address, contact, GSTIN)
- ✅ All Items (with calculated amounts, SGST, CGST)
- ✅ Total amounts (subtotal, taxes, total)
- ✅ Amount in words
- ❌ Bank details (not copied to Tax Invoice; payment info lives on Estimate)
- ✅ Terms & Conditions
- ✅ Signature URLs
- ❌ Only transportation details need to be supplied

---

## TAX INVOICE API

### Create Tax Invoice
**POST** `/api/tax-invoices`

**Request Body:**
```json
{
  "taxInvoice": {
    "invoiceDate": "2026-07-07",
    "billTo": {
      "customerName": "ABC Company",
      "address": "123 Main Street, City, State 12345",
      "contactPerson": "John Doe",
      "contactNumber": "+91-9876543210",
      "gstinNumber": "36AAFGU5055K1Z1"
    },
    "placeOfSupply": "36-Telangana",
    "transportationDetails": {
      "vehicleNumber": "TS-09-AB-1234",
      "transportName": "ABC Logistics",
      "lrNumber": "LR-2026-0001",
      "dispatchDetails": "Dispatched on 2026-07-07",
      "deliveryDetails": "To be delivered within 3 days"
    },
    "items": [ /* same as Estimate */ ],
    // `bankDetails` is not accepted from the client; company payment info is provided by the backend and attached only to Estimates.
    "termsAndConditions": "Thank you for doing business with us.\n*You want a tax bill that will be his higher.",
    "paymentDetails": {
      "amountReceived": 0
    }
  }
}
```

**Response (201):** Same structure as Estimate but with `invoiceNumber`. Tax Invoices do not include payment QRs, Click-to-Pay links, or bank details.

### List Tax Invoices
**GET** `/api/tax-invoices`

**Query Parameters:**
```
page=1
limit=10
search=INV-2026-0001            // Search by number/customer/phone
customerName=ABC Company
invoiceNumber=INV-2026-0001
dateFrom=2026-07-01
dateTo=2026-07-31
```

### Get Tax Invoice by ID
**GET** `/api/tax-invoices/:id`

Returns full invoice with linked estimate (if converted from estimate).

### Update Tax Invoice
**PUT** `/api/tax-invoices/:id`

Updates invoice and recalculates all amounts automatically.

### Update Payment Status
Invoice-level payment updates are not supported. Payments must be collected via the Estimate (which includes the payment QR, Click-to-Pay link, and company bank details). After full payment is confirmed on an Estimate, a Tax Invoice may be created; the backend will also upsert or create a `Customer` record and append invoice history.

### Delete Tax Invoice
**DELETE** `/api/tax-invoices/:id`

---

## Data Structures

### Item Schema
```javascript
{
  itemName: string,           // Required
  hsnSac: string,            // Optional
  quantity: number,          // Required, > 0
  unit: string,              // Optional, default: "-"
  pricePerUnit: number,      // Required, > 0
  taxApplicable: boolean,    // true/false
  gstPercentage: number,     // 0|0.25|3|5|12|18|28|40
  sgst: number,              // Backend calculated
  cgst: number,              // Backend calculated
  amount: number             // Backend calculated
}
```

### Customer Details Schema (Estimate)
```javascript
{
  customerName: string,      // Required
  address: string,           // Required
  contactPerson: string,     // Optional
  contactNumber: string,     // Required
  gstinNumber: string        // Optional
}
```

### Bill To Schema (Tax Invoice)
Same as Customer Details.

### Transportation Details Schema
```javascript
{
  vehicleNumber: string,
  transportName: string,
  lrNumber: string,
  dispatchDetails: string,
  deliveryDetails: string
}
```

### Bank Details Schema
```javascript
{
  bankName: string,
  accountNumber: string,
  ifscCode: string,
  upiId: string,
  qrCodeUrl: string
}
```

### Payment Details Schema (Tax Invoice Only)
```javascript
{
  status: "Unpaid" | "Partially Paid" | "Paid",
  amountReceived: number,
  pendingAmount: number,
  paymentDate: Date
}
```

---

## Error Handling

### Common Error Responses

**400 - Validation Error:**
```json
{
  "success": false,
  "message": "At least one item is required.",
  "error": { "details": "..." }
}
```

**400 - Invalid Payload:**
```json
{
  "success": false,
  "message": "Invalid JSON payload.",
  "error": { "details": "..." }
}
```

**400 - Duplicate Number:**
```json
{
  "success": false,
  "message": "Estimate number already exists.",
  "error": { "details": "..." }
}
```

**404 - Not Found:**
```json
{
  "success": false,
  "message": "Estimate not found.",
  "error": {}
}
```

**500 - Server Error:**
```json
{
  "success": false,
  "message": "Failed to create estimate.",
  "error": { "details": "..." }
}
```

---

## Validation Rules

### Estimate/Invoice Creation
- ✅ At least 1 item required
- ✅ Customer name, address, contact number required
- ✅ Each item must have: name, quantity > 0, price > 0
- ✅ GST percentage must be one of: 0, 0.25, 3, 5, 12, 18, 28, 40
- ✅ Estimate/Invoice number auto-generated (never from frontend)

### Payment Update (Tax Invoice)
- ✅ amountReceived must be >= 0
- ✅ amountReceived must be <= total amount (for "Paid" status)
- ✅ Payment status auto-calculated from amount

---

## Database Indexes

### Estimate Collection
- estimateNumber (unique)
- estimateDate
- estimateFor.customerName
- estimateFor.contactNumber

### Tax Invoice Collection
- invoiceNumber (unique)
- invoiceDate
- billTo.customerName
- billTo.contactNumber
- paymentDetails.status
- linkedEstimateId (for tracking conversions)

---

## Examples

### Example 1: Create and Convert Estimate to Invoice

**Step 1: Create Estimate**
```bash
curl -X POST http://localhost:5000/api/estimates \
  -H "Content-Type: application/json" \
  -d '{
    "estimate": {
      "estimateFor": {
        "customerName": "XYZ Corp",
        "address": "123 Street, City",
        "contactNumber": "+91-9876543210"
      },
      "items": [{
        "itemName": "Service",
        "quantity": 1,
        "pricePerUnit": 10000,
        "taxApplicable": true,
        "gstPercentage": 18
      }]
    }
  }'
```

**Step 2: Convert to Invoice**
```bash
curl -X POST http://localhost:5000/api/estimates/{estimateId}/convert-to-invoice \
  -H "Content-Type: application/json" \
  -d '{
    "taxInvoice": {
      "transportationDetails": {
        "vehicleNumber": "TS-09-AB-1234"
      }
    }
  }'
```

### Example 2: Track Payment

**Update Payment**
```bash
curl -X PATCH http://localhost:5000/api/tax-invoices/{invoiceId}/payment \
  -H "Content-Type: application/json" \
  -d '{
    "amountReceived": 5000,
    "paymentDate": "2026-07-10"
  }'
```

---

## Testing

### Unit Tests
```bash
# Run all tests
npm test

# Test financial calculations
node --test tests/financial.utils.test.js

# Test existing agreement module
node --test tests/agreement.helpers.test.js
```

### Development
```bash
# Start development server
npm run dev

# Health check
curl http://localhost:5000/health
```

---

## Notes

- All dates use ISO 8601 format (YYYY-MM-DD)
- All monetary values are in Indian Rupees (₹)
- GST calculations assume Indian tax system (SGST = State GST, CGST = Central GST)
- Amount in words generated in English
- Estimate status: draft → sent → accepted/rejected/converted
- Estimate to Invoice conversion is one-way (cannot be reversed)
- Deleted estimates/invoices cannot be recovered
