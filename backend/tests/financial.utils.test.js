import test from 'node:test';
import assert from 'node:assert/strict';
import {
  calculateEstimateItems,
  calculateEstimateTotals,
  formatEstimateNumber,
  formatInvoiceNumber,
  calculatePaymentDetails,
} from '../src/utils/financial.utils.js';

test('calculateEstimateItems splits GST into SGST and CGST', () => {
  const items = [
    {
      itemName: 'Engine oil',
      quantity: 1,
      pricePerUnit: 1000,
      taxApplicable: true,
      gstPercentage: 18,
    },
  ];

  const result = calculateEstimateItems(items);
  const item = result[0];

  assert.equal(item.taxApplicable, true);
  assert.equal(item.gstPercentage, 18);
  assert.equal(item.sgst, 90); // 18/2
  assert.equal(item.cgst, 90); // 18/2
  assert.equal(item.amount, 1180); // 1000 + 90 + 90
});

test('calculateEstimateItems handles no tax items', () => {
  const items = [
    {
      itemName: 'Service',
      quantity: 1,
      pricePerUnit: 500,
      taxApplicable: false,
    },
  ];

  const result = calculateEstimateItems(items);
  const item = result[0];

  assert.equal(item.taxApplicable, false);
  assert.equal(item.gstPercentage, 0);
  assert.equal(item.sgst, 0);
  assert.equal(item.cgst, 0);
  assert.equal(item.amount, 500);
});

test('calculateEstimateTotals computes subtotal, tax, and total', () => {
  const items = [
    {
      itemName: 'Engine oil',
      quantity: 2,
      pricePerUnit: 1000,
      taxApplicable: true,
      gstPercentage: 18,
    },
    {
      itemName: 'Labor',
      quantity: 1,
      pricePerUnit: 500,
      taxApplicable: false,
    },
  ];

  const result = calculateEstimateTotals(items);

  assert.equal(result.subtotal, 2500); // (2*1000) + 500
  assert.equal(result.totalTax, 360); // 18% of 2000
  assert.equal(result.totalAmount, 2860);
});

test('formatEstimateNumber generates correct format', () => {
  const estimateNo = formatEstimateNumber(1);
  assert.match(estimateNo, /^EST-\d{4}-0001$/);
});

test('formatInvoiceNumber generates correct format', () => {
  const invoiceNo = formatInvoiceNumber(5);
  assert.match(invoiceNo, /^INV-\d{4}-0005$/);
});

test('calculatePaymentDetails tracks payment status correctly', () => {
  // Unpaid
  const unpaid = calculatePaymentDetails(1000, 0);
  assert.equal(unpaid.status, 'Unpaid');
  assert.equal(unpaid.amountReceived, 0);
  assert.equal(unpaid.pendingAmount, 1000);

  // Partially Paid
  const partial = calculatePaymentDetails(1000, 500);
  assert.equal(partial.status, 'Partially Paid');
  assert.equal(partial.amountReceived, 500);
  assert.equal(partial.pendingAmount, 500);

  // Paid
  const paid = calculatePaymentDetails(1000, 1000);
  assert.equal(paid.status, 'Paid');
  assert.equal(paid.amountReceived, 1000);
  assert.equal(paid.pendingAmount, 0);
});
