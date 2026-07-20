# Flutter Frontend Integration Guide - Payment System

## Quick Reference for Frontend Developers

The backend now handles ALL payment logic. Here's what you need to update in Flutter:

---

## ❌ What to REMOVE from Frontend

### Remove from Forms
- Bank account number input field
- IFSC code input field
- UPI ID input field
- Account holder name input field
- QR code upload field

### Remove from Models
```dart
// REMOVE these fields:
String? bankName;
String? accountNumber;
String? ifscCode;
String? upiId;
String? accountHolderName;
String? qrCodeUrl;
```

### Remove from API Requests
```dart
// DON'T SEND these anymore:
"bankDetails": {
  "bankName": "ICICI Bank",
  "accountNumber": "1234567890123891",
  "ifscCode": "ICIC0000001",
  "upiId": "gps@upi"
}
```

---

## ✅ What to ADD to Frontend

### 1. Display QR Code from Response

**Old Way (Backend sent nothing)**:
```dart
// App generated QR - STOP DOING THIS
generateQRCode(estimateNumber);
```

**New Way (Backend provides QR)**:
```dart
// Add to estimate/invoice response model:
class PaymentData {
  final String qrBase64;      // Base64 PNG image
  final String clickToPayLink; // UPI deep link
  final String upiPaymentUri;  // Raw UPI URI
  final double payableAmount;  // Amount to pay
  final String companyUpiId;   // Company UPI
  final String companyName;    // Company name
}

// In UI, display QR:
Container(
  child: Image.memory(
    base64Decode(paymentData.qrBase64),
    width: 200,
    height: 200,
  ),
)
```

### 2. Add Click-to-Pay Button

```dart
ElevatedButton(
  onPressed: () {
    // Open UPI app with payment link
    launchUrl(Uri.parse(paymentData.clickToPayLink));
  },
  child: Text('Click to Pay'),
)
```

### 3. Display Company Bank Details

**Old Way (Sent from app)**:
```dart
// STOP - don't send from app
```

**New Way (Received from backend)**:
```dart
class BankDetails {
  final String companyName;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;      // Masked: ***2891
  final String ifscCode;
  final String upiId;
  final String gstNumber;
  final String phoneNumber;
  final String email;
}

// In UI, display:
Text("Pay to: ${bankDetails.companyName}"),
Text("Bank: ${bankDetails.bankName}"),
Text("Account: ${bankDetails.accountNumber}"),
Text("IFSC: ${bankDetails.ifscCode}"),
Text("UPI: ${bankDetails.upiId}"),
```

### 4. Handle Partial Payments for Invoices

**When Converting Estimate → Invoice**:
```dart
// Send advance payment if applicable
POST /api/estimates/:id/convert-to-invoice
{
  "advanceAmountReceived": 50000,  // Optional advance
  "advancePaymentMethod": "Bank Transfer",
  "advanceReferenceNumber": "REF123",
  "transportationDetails": {
    "vehicleNumber": "DL01AB1234",
    "transportName": "ABC Logistics"
    // ...
  }
}

// Response includes:
{
  "payment": {
    "payableAmount": 68000  // Remaining amount!
    "qrBase64": "..."       // QR for remaining
  },
  "paymentDetails": {
    "totalAmount": 118000,
    "advanceAmountReceived": 50000,
    "remainingAmount": 68000,
    "status": "Partially Paid"
  }
}
```

### 5. Update Payment on Invoice

```dart
// When customer makes payment
PATCH /api/tax-invoices/:id/payment
{
  "amountReceived": 68000,
  "paymentDate": "2024-01-22",
  "paymentMethod": "UPI",
  "referenceNumber": "UPI1234567890"
}

// Response:
{
  "paymentDetails": {
    "totalAmount": 118000,
    "advanceAmountReceived": 118000,
    "remainingAmount": 0,
    "status": "Paid",  // Auto-calculated!
    "paymentHistory": [
      { "amountReceived": 50000, "paymentDate": "...", "paymentMethod": "Bank Transfer" },
      { "amountReceived": 68000, "paymentDate": "...", "paymentMethod": "UPI" }
    ]
  },
  "payment": {
    "payableAmount": 0
    "qrBase64": "..."
  }
}
```

---

## 📝 Updated API Contracts

### All Estimate/Invoice Responses Now Include:

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "estimate": { "...document fields..." },
    "payment": {
      "qrBase64": "data:image/png;base64,iVBORw0KG...",
      "clickToPayLink": "upi://pay?pa=gps%40upi&...",
      "upiPaymentUri": "upi://pay?pa=gps%40upi&...",
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

### Model Updates

```dart
// Estimate Model
class Estimate {
  String estimateNumber;
  DateTime estimateDate;
  CustomerDetails estimateFor;
  List<EstimateItem> items;
  double subtotal;
  double totalTax;
  double totalAmount;
  String amountInWords;
  PaymentData payment;              // NEW
  BankDetails bankDetails;          // NEW
  String termsAndConditions;
  String? authorizedSignatureUrl;
  String status;  // draft, sent, accepted, rejected, converted
}

// Tax Invoice Model
class TaxInvoice {
  String invoiceNumber;
  DateTime invoiceDate;
  CustomerDetails billTo;
  List<EstimateItem> items;
  double subtotal;
  double totalTax;
  double totalAmount;
  String amountInWords;
  PaymentDetails paymentDetails;    // NEW
  PaymentData payment;              // NEW
  BankDetails bankDetails;          // NEW
  String? linkedEstimateId;
}

// NEW Classes
class PaymentData {
  String qrBase64;
  String clickToPayLink;
  String upiPaymentUri;
  double payableAmount;
  String companyUpiId;
  String companyName;
}

class PaymentDetails {
  double totalAmount;
  double advanceAmountReceived;
  double remainingAmount;
  String status;  // "Unpaid", "Partially Paid", "Paid"
  List<PaymentRecord> paymentHistory;
}

class PaymentRecord {
  double amountReceived;
  DateTime paymentDate;
  String paymentMethod;  // "UPI", "Bank Transfer", etc.
  String referenceNumber;
}

class BankDetails {
  String companyName;
  String bankName;
  String accountHolderName;
  String accountNumber;  // Masked: ***2891
  String ifscCode;
  String upiId;
  String gstNumber;
  String phoneNumber;
  String email;
}
```

---

## 🔄 Updated Workflows

### Estimate Creation Flow

```
Flutter App
├─ User fills estimate form
│  ├─ Customer name, address, contact
│  ├─ Add items (no bank details!)
│  └─ Terms & conditions
└─ POST /api/estimates
   └─ Backend:
      ├─ Validates items
      ├─ Calculates GST/totals
      ├─ Generates EST-2026-0001
      ├─ Generates QR from backend config
      └─ Returns {estimate, payment, bankDetails}

Flutter App receives:
├─ Display estimate number
├─ Show QR code from payment.qrBase64
├─ Display company details from bankDetails
└─ Show Click-to-Pay button linking to clickToPayLink
```

### Estimate → Invoice Conversion Flow

```
Flutter App (with advance payment)
├─ User selects "Convert to Invoice"
├─ Optional: Enter advance amount
├─ Enter transportation details
└─ POST /api/estimates/:id/convert-to-invoice
   └─ Backend:
      ├─ Copies customer & items from estimate
      ├─ Generates INV-2026-0001
      ├─ Calculates remainingAmount
      ├─ Generates QR for remaining (NOT total!)
      ├─ Tracks advance in paymentHistory
      └─ Returns {invoice with payment for remaining}

Flutter App receives:
├─ Display invoice number
├─ Show QR for remaining amount only
├─ Update payment status to "Partially Paid" if advance > 0
└─ Show payment tracking (advance vs remaining)
```

### Payment Update Flow

```
Flutter App
├─ User confirms payment received
└─ PATCH /api/tax-invoices/:id/payment
   └─ Backend:
      ├─ Appends payment to paymentHistory
      ├─ Recalculates advanceAmountReceived (sum)
      ├─ Calculates remainingAmount
      ├─ Auto-calculates status (Unpaid → Partially Paid → Paid)
      ├─ Generates new QR for remaining
      └─ Returns {invoice with updated payment}

Flutter App receives:
├─ Update payment status
├─ Show updated payment history
├─ Display new QR code if more payments needed
└─ Mark as "Paid" when remainingAmount = 0
```

---

## 🎯 Key Changes Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Bank Details** | Sent from app | Stored on backend only |
| **QR Code** | Generated by app | Generated by backend |
| **Amount Calculation** | App calculates | Backend calculates |
| **GST Split** | App splits | Backend splits |
| **Invoice Number** | Suggested by app | Generated by backend |
| **Payment Status** | User selects | Backend calculates |
| **API Response** | Document only | Document + payment + bankDetails |
| **Partial Payments** | Not supported | Tracked in paymentHistory |

---

## 🚀 Implementation Checklist for Flutter

- [ ] Remove bank details input fields from forms
- [ ] Remove bank details from models
- [ ] Update API models to include PaymentData and BankDetails classes
- [ ] Update estimate creation API call (remove bankDetails)
- [ ] Update estimate list to display QR codes
- [ ] Add Click-to-Pay button using payment.clickToPayLink
- [ ] Display company bank details from bankDetails response
- [ ] Update invoice creation to accept advanceAmountReceived
- [ ] Update invoice payment update to send paymentMethod and referenceNumber
- [ ] Display payment history from paymentDetails.paymentHistory
- [ ] Display payment status from paymentDetails.status
- [ ] Add logic to handle remainingAmount for invoice payment QR
- [ ] Test estimate creation flow
- [ ] Test estimate to invoice conversion
- [ ] Test multiple payments on invoice
- [ ] Test payment status transitions

---

## 📋 Example Dart Code

### Display QR Code
```dart
Future<void> displayEstimate(String estimateId) async {
  final response = await apiClient.get('/estimates/$estimateId');
  final data = response['data'];
  
  // NEW: Extract payment data
  final qrBase64 = data['payment']['qrBase64'];
  final clickToPay = data['payment']['clickToPayLink'];
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Estimate ${data['estimate']['estimateNumber']}'),
      content: Column(
        children: [
          // Display QR
          Image.memory(
            base64Decode(qrBase64),
            width: 200,
            height: 200,
          ),
          SizedBox(height: 16),
          // Click to Pay button
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse(clickToPay)),
            child: Text('Click to Pay'),
          ),
          SizedBox(height: 16),
          // Display bank details
          Text('Pay to: ${data['bankDetails']['companyName']}'),
          Text('UPI: ${data['bankDetails']['upiId']}'),
        ],
      ),
    ),
  );
}
```

### Convert Estimate with Advance
```dart
Future<void> convertToInvoice(String estimateId, double advanceAmount) async {
  final response = await apiClient.post(
    '/estimates/$estimateId/convert-to-invoice',
    data: {
      'advanceAmountReceived': advanceAmount,
      'advancePaymentMethod': 'Bank Transfer',
      'transportationDetails': {
        'vehicleNumber': 'DL01AB1234',
        'transportName': 'ABC Logistics',
      },
    },
  );
  
  final invoice = response['data']['taxInvoice'];
  
  // NEW: Payment QR is for remaining amount
  final remainingAmount = invoice['paymentDetails']['remainingAmount'];
  final qrBase64 = invoice['payment']['qrBase64'];
  
  print('Invoice created: ${invoice['invoiceNumber']}');
  print('Remaining to pay: ₹$remainingAmount');
  print('Payment status: ${invoice['paymentDetails']['status']}');
}
```

### Update Invoice Payment
```dart
Future<void> recordPayment(String invoiceId, double amount) async {
  final response = await apiClient.patch(
    '/tax-invoices/$invoiceId/payment',
    data: {
      'amountReceived': amount,
      'paymentDate': DateTime.now().toIso8601String(),
      'paymentMethod': 'UPI',
      'referenceNumber': 'UPI1234567890',
    },
  );
  
  final paymentDetails = response['data']['paymentDetails'];
  
  // Backend auto-calculated:
  print('Status: ${paymentDetails['status']}');
  print('Remaining: ₹${paymentDetails['remainingAmount']}');
  print('Payment history: ${paymentDetails['paymentHistory'].length} payments');
}
```

---

## ✨ Benefits

✅ **Security**: No sensitive bank data in app
✅ **Simplicity**: No payment calculation logic needed
✅ **Flexibility**: Backend can change payment methods anytime
✅ **Auditability**: Full payment history on server
✅ **Compliance**: Centralized payment management
✅ **Scalability**: Easy to add payment gateway integration later

---

## 📞 Support

For questions about backend API, see:
- `API_REFERENCE_PAYMENT_SYSTEM.md` - Complete API docs
- `PAYMENT_SYSTEM_COMPLETION_REPORT.md` - Architecture details
