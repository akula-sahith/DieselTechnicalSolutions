const UNDER_TWENTY = {
  0: 'Zero',
  1: 'One',
  2: 'Two',
  3: 'Three',
  4: 'Four',
  5: 'Five',
  6: 'Six',
  7: 'Seven',
  8: 'Eight',
  9: 'Nine',
  10: 'Ten',
  11: 'Eleven',
  12: 'Twelve',
  13: 'Thirteen',
  14: 'Fourteen',
  15: 'Fifteen',
  16: 'Sixteen',
  17: 'Seventeen',
  18: 'Eighteen',
  19: 'Nineteen',
};

const UNDER_HUNDRED = {
  20: 'Twenty',
  30: 'Thirty',
  40: 'Forty',
  50: 'Fifty',
  60: 'Sixty',
  70: 'Seventy',
  80: 'Eighty',
  90: 'Ninety',
};

const convertLessThanThousand = (value) => {
  if (value < 20) return UNDER_TWENTY[value] || '';
  if (value < 100) {
    const tens = Math.floor(value / 10) * 10;
    const remainder = value % 10;
    return remainder ? `${UNDER_HUNDRED[tens]} ${UNDER_TWENTY[remainder]}` : UNDER_HUNDRED[tens];
  }

  const hundreds = Math.floor(value / 100);
  const remainder = value % 100;
  return remainder
    ? `${UNDER_TWENTY[hundreds]} Hundred ${convertLessThanThousand(remainder)}`
    : `${UNDER_TWENTY[hundreds]} Hundred`;
};

export const numberToWords = (amount) => {
  const numericAmount = Math.round(Number(amount || 0));

  if (numericAmount === 0) {
    return 'Zero Rupees Only';
  }

  const crore = Math.floor(numericAmount / 10000000);
  const lakh = Math.floor((numericAmount % 10000000) / 100000);
  const thousand = Math.floor((numericAmount % 100000) / 1000);
  const rest = numericAmount % 1000;

  const parts = [];

  if (crore) parts.push(`${convertLessThanThousand(crore)} Crore`);
  if (lakh) parts.push(`${convertLessThanThousand(lakh)} Lakh`);
  if (thousand) parts.push(`${convertLessThanThousand(thousand)} Thousand`);
  if (rest) parts.push(convertLessThanThousand(rest));

  return `${parts.join(' ')} Rupees Only`;
};

export const calculateAgreementTotals = (descriptionItems = [], financials = {}) => {
  const totalBeforeGST = descriptionItems.reduce((sum, item) => {
    const quantity = Number(item.quantity || 0);
    const rate = Number(item.rate || 0);
    return sum + quantity * rate;
  }, 0);

  const gstRequired = financials.gstRequired === true || financials.gstRequired === 'true';
  const gstPercentage = Number(financials.gstPercentage || 0);
  const gstAmount = gstRequired ? (totalBeforeGST * gstPercentage) / 100 : 0;
  const grandTotal = totalBeforeGST + gstAmount;

  return {
    totalBeforeGST: Number(totalBeforeGST.toFixed(2)),
    gstAmount: Number(gstAmount.toFixed(2)),
    grandTotal: Number(grandTotal.toFixed(2)),
  };
};

export const formatOfferNumber = (sequence) => {
  return `GPS/AMC/${String(sequence).padStart(2, '0')}`;
};