import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateAgreementTotals, numberToWords } from '../src/utils/agreement.utils.js';

test('calculateAgreementTotals computes subtotal, gst and grand total', () => {
  const result = calculateAgreementTotals([
    { quantity: 2, rate: 100 },
    { quantity: 1, rate: 50 },
  ], { gstRequired: true, gstPercentage: 5 });

  assert.equal(result.totalBeforeGST, 250);
  assert.equal(result.gstAmount, 12.5);
  assert.equal(result.grandTotal, 262.5);
});

test('numberToWords converts a simple rupee amount', () => {
  assert.equal(numberToWords(8500), 'Eight Thousand Five Hundred Rupees Only');
});
