import QRCode from 'qrcode';
import companyPaymentDetails from '../config/companyPaymentDetails.js';

/**
 * Generate UPI payment URI
 * Format: upi://pay?pa=<upiId>&pn=<payeeName>&am=<amount>&cu=INR&tn=<transactionNote>
 */
export const generateUpiPaymentUri = (amount, reference = '') => {
  const { upiId, companyName } = companyPaymentDetails;

  const params = new URLSearchParams({
    pa: upiId,
    pn: companyName,
    am: String(amount),
    cu: 'INR',
    tn: reference || 'Payment',
  });

  return `upi://pay?${params.toString()}`;
};

/**
 * Generate Click To Pay UPI Link
 * This creates a universal UPI link that works across all UPI apps
 */
export const generateClickToPayLink = (amount, reference = '') => {
  const upiUri = generateUpiPaymentUri(amount, reference);
  return upiUri;
};

/**
 * Generate QR Code as Base64 string
 * Generates a QR code for the UPI payment URI
 */
export const generateQrCodeBase64 = async (amount, reference = '') => {
  try {
    const upiUri = generateUpiPaymentUri(amount, reference);

    const qrCodeDataUrl = await QRCode.toDataURL(upiUri, {
      errorCorrectionLevel: 'H',
      type: 'image/png',
      quality: 0.95,
      margin: 1,
      width: 300,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    // Extract base64 part (remove data:image/png;base64, prefix)
    const base64 = qrCodeDataUrl.split(',')[1];
    return base64;
  } catch (error) {
    console.error('[QR Code] Generation failed:', error.message);
    throw new Error('Failed to generate QR code');
  }
};

/**
 * Generate complete payment data object
 * Returns all payment-related information for API response
 */
export const generatePaymentData = async (payableAmount, reference = '') => {
  try {
    const [qrBase64, clickToPayLink, upiPaymentUri] = await Promise.all([
      generateQrCodeBase64(payableAmount, reference),
      Promise.resolve(generateClickToPayLink(payableAmount, reference)),
      Promise.resolve(generateUpiPaymentUri(payableAmount, reference)),
    ]);

    return {
      qrBase64,
      clickToPayLink,
      upiPaymentUri,
      payableAmount: Number(payableAmount),
      companyUpiId: companyPaymentDetails.upiId,
      companyName: companyPaymentDetails.companyName,
    };
  } catch (error) {
    console.error('[Payment Data] Generation failed:', error.message);
    throw error;
  }
};

/**
 * Get company bank details for display
 * Used in estimate/invoice PDFs
 */
export const getCompanyBankDetails = () => {
  return {
    companyName: companyPaymentDetails.companyName,
    bankName: companyPaymentDetails.bankName,
    accountHolderName: companyPaymentDetails.accountHolderName,
    accountNumber: companyPaymentDetails.accountNumber,
    ifscCode: companyPaymentDetails.ifscCode,
    upiId: companyPaymentDetails.upiId,
    gstNumber: companyPaymentDetails.gstNumber,
    phoneNumber: companyPaymentDetails.phoneNumber,
    email: companyPaymentDetails.email,
  };
};
