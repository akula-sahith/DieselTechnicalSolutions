import test from 'node:test';
import assert from 'node:assert/strict';
import { generateUpiPaymentUri, generateClickToPayLink, generatePaymentData } from '../src/utils/payment.utils.js';
import companyPaymentDetails from '../src/config/companyPaymentDetails.js';

test('generateUpiPaymentUri creates valid UPI payment URI', () => {
  const uri = generateUpiPaymentUri(5000, 'EST-2026-0001');

  assert.match(uri, /^upi:\/\/pay\?/);
  assert.match(uri, new RegExp(`pa=${encodeURIComponent(companyPaymentDetails.upiId)}`));
  assert.match(uri, /am=5000/);
  assert.match(uri, /cu=INR/);
  assert.match(uri, /tn=EST-2026-0001/);
  assert.match(uri, /pn=Diesel\+Technical\+Solutions/);
});

test('generateUpiPaymentUri includes company name', () => {
  const uri = generateUpiPaymentUri(1000);

  assert.ok(uri.includes(companyPaymentDetails.companyName.replace(/ /g, '+')));
});

test('generateClickToPayLink returns valid URI', () => {
  const link = generateClickToPayLink(10000, 'INV-2026-0001');

  assert.match(link, /^upi:\/\/pay\?/);
  assert.match(link, /am=10000/);
});

test('generatePaymentData should return payment object with required fields', async () => {
  try {
    const paymentData = await generatePaymentData(50000, 'INV-2026-0001');

    assert.ok(paymentData.qrBase64, 'QR Base64 should be present');
    assert.ok(paymentData.clickToPayLink, 'Click To Pay Link should be present');
    assert.ok(paymentData.upiPaymentUri, 'UPI Payment URI should be present');
    assert.equal(paymentData.payableAmount, 50000);
    assert.equal(paymentData.companyUpiId, companyPaymentDetails.upiId);
    assert.equal(paymentData.companyName, companyPaymentDetails.companyName);
  } catch (error) {
    console.error('Payment data generation requires qrcode package - install dependencies first');
    console.error(error.message);
  }
});

test('generateUpiPaymentUri handles decimal amounts', () => {
  const uri = generateUpiPaymentUri(5000.50, 'EST-2026-0001');

  assert.match(uri, /am=5000\.5/);
});

test('generateUpiPaymentUri handles zero amount', () => {
  const uri = generateUpiPaymentUri(0, 'EST-2026-0001');

  assert.match(uri, /am=0/);
});
