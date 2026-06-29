# Postman Request Body for Create Report

Use this as a JSON example for the create report endpoint.

## Endpoint
- POST http://localhost:5000/api/reports

## Body
```json
{
  "jobRef": "JOB-1001",
  "dateTime": "2026-06-28T10:30:00.000Z",
  "customerName": "Diesel Solutions LLC",
  "siteLocation": "Dubai Industrial Area",
  "contactPerson": "Ahmed Khan",
  "contactNumber": "+971501234567",
  "generatorMakeModel": "Cummins C150D5",
  "capacity": "125 kVA",
  "engineSerialNo": "ENG-001234",
  "alternatorSerialNo": "ALT-001234",
  "hourMeter": "8450",
  "hours": "8450",
  "batteryStatusVolt": "12.6 V",
  "serviceChecklist": [
    {
      "parameter": "Engine Oil Level & Quality",
      "status": "ok"
    },
    {
      "parameter": "Coolant Level & Protection",
      "status": "req"
    },
    {
      "parameter": "Battery Terminals & Charging",
      "status": "ok"
    }
  ],
  "partsUsed": [
    {
      "partDescription": "Battery 12V 90Ah",
      "qty": "1"
    },
    {
      "partDescription": "B Check Kit",
      "qty": "1"
    }
  ],
  "observations": "Replaced new battery and completed oil service. Generator running normally.",
  "nextServiceDueDate": "2026-12-28",
  "nextServiceDueHours": "500",
  "technicianName": "Siva",
  "customerRepresentativeName": "John Smith",
  "technicianDate": "2026-06-28",
  "customerDate": "2026-06-28"
}
```

## Important note
Because this endpoint accepts image uploads, you should send it as form-data in Postman with:
- technicianSignature: image file
- customerPhoto: image file

And the other fields as text values.
