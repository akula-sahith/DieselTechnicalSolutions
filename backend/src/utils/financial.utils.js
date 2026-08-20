export const calculateEstimateItems = (items = []) => {
  return items.map((item) => {
    const quantity = Number(item.quantity || 0);
    const pricePerUnit = Number(item.pricePerUnit || 0);
    const baseAmount = Number((quantity * pricePerUnit).toFixed(2));

    const isTaxApplicable = item.taxApplicable !== false && item.taxApplicable !== 'false' && item.taxApplicable !== 0;
    const gstPercentage = isTaxApplicable ? (item.gstPercentage !== undefined && item.gstPercentage !== null ? Number(item.gstPercentage) : 18) : 0;

    if (!isTaxApplicable || gstPercentage <= 0) {
      return {
        ...item,
        quantity,
        pricePerUnit,
        taxApplicable: false,
        gstPercentage: 0,
        sgst: 0,
        cgst: 0,
        amount: baseAmount,
      };
    }

    const gstAmount = Number((baseAmount * gstPercentage) / 100).toFixed(2);
    const sgst = Number((gstAmount / 2).toFixed(2));
    const cgst = Number((gstAmount / 2).toFixed(2));

    return {
      ...item,
      quantity,
      pricePerUnit,
      taxApplicable: true,
      gstPercentage,
      sgst: Number(sgst),
      cgst: Number(cgst),
      amount: Number((baseAmount + Number(sgst) + Number(cgst)).toFixed(2)),
    };
  });
};

export const calculateEstimateTotals = (items = [], discount = {}) => {
  const discountType = discount.discountType || 'none';
  const discountValue = Number(discount.discountValue || 0);
  const isNoTaxMode = discount.taxMode === 'no-tax';

  // 1. Calculate raw subtotals for each item
  const rawItems = items.map(item => {
    const qty = Number(item.quantity || 0);
    const price = Number(item.pricePerUnit || 0);
    const itemSubtotal = Number((qty * price).toFixed(2));
    return {
      ...item,
      quantity: qty,
      pricePerUnit: price,
      itemSubtotal,
    };
  });

  const subtotal = Number(rawItems.reduce((sum, item) => sum + item.itemSubtotal, 0).toFixed(2));

  // 2. Calculate global discount amount
  let discountAmount = 0;
  if (discountType === 'percentage') {
    discountAmount = Number((subtotal * discountValue / 100).toFixed(2));
  } else if (discountType === 'fixed') {
    discountAmount = Math.min(discountValue, subtotal);
  }

  const taxableAmount = Number((subtotal - discountAmount).toFixed(2));

  // 3. Pro-rate the discount to calculate item-wise tax
  const discountRatio = subtotal > 0 ? (discountAmount / subtotal) : 0;

  const calculatedItems = rawItems.map(item => {
    // Pro-rated discount for this item
    const itemDiscount = Number((item.itemSubtotal * discountRatio).toFixed(2));
    const itemTaxable = Number((item.itemSubtotal - itemDiscount).toFixed(2));

    const isTaxApplicable = !isNoTaxMode && item.taxApplicable !== false && item.taxApplicable !== 'false' && item.taxApplicable !== 0;
    const gstPercentage = isTaxApplicable ? (item.gstPercentage !== undefined && item.gstPercentage !== null ? Number(item.gstPercentage) : 18) : 0;

    if (!isTaxApplicable || gstPercentage <= 0) {
      return {
        ...item,
        taxApplicable: false,
        gstPercentage: 0,
        sgst: 0,
        cgst: 0,
        amount: itemTaxable,
      };
    }

    const gstAmount = Number((itemTaxable * gstPercentage) / 100).toFixed(2);
    const sgst = Number((gstAmount / 2).toFixed(2));
    const cgst = Number((gstAmount / 2).toFixed(2));

    return {
      ...item,
      taxApplicable: true,
      gstPercentage,
      sgst: Number(sgst),
      cgst: Number(cgst),
      amount: Number((itemTaxable + Number(sgst) + Number(cgst)).toFixed(2)),
    };
  });

  const totalTax = Number(
    calculatedItems.reduce((sum, item) => {
      return sum + (Number(item.sgst || 0) + Number(item.cgst || 0));
    }, 0).toFixed(2)
  );

  const totalAmount = Number((taxableAmount + totalTax).toFixed(2));

  return {
    items: calculatedItems,
    subtotal,
    discountType,
    discountValue,
    discountAmount,
    taxableAmount,
    totalTax,
    totalAmount,
  };
};

export const formatEstimateNumber = (sequence) => {
  const year = new Date().getFullYear();
  return `EST-${year}-${String(sequence).padStart(4, '0')}`;
};

export const formatInvoiceNumber = (sequence) => {
  return String(sequence).padStart(2, '0');
};

export const formatBillingInvoiceNumber = (sequence) => {
  return String(sequence).padStart(2, '0');
};

export const formatChallanNumber = (sequence) => {
  return String(sequence);
};

export const calculateBillingItems = (items = []) => {
  return items.map((item) => {
    const quantity = Number(item.quantity || 0);
    const pricePerUnit = Number(item.pricePerUnit || 0);
    const amount = Number((quantity * pricePerUnit).toFixed(2));

    return {
      itemName: item.itemName,
      hsnSac: item.hsnSac || '',
      quantity,
      pricePerUnit,
      amount,
    };
  });
};

export const calculateBillingTotals = (items = [], discount = {}) => {
  const calculatedItems = calculateBillingItems(items);

  const subtotal = Number(
    calculatedItems.reduce((sum, item) => sum + item.amount, 0).toFixed(2)
  );

  const discountType = discount.discountType || 'none';
  const discountValue = Number(discount.discountValue || 0);

  let discountAmount = 0;
  if (discountType === 'percentage') {
    discountAmount = Number((subtotal * discountValue / 100).toFixed(2));
  } else if (discountType === 'fixed') {
    discountAmount = Math.min(discountValue, subtotal);
  }

  const totalAmount = Number((subtotal - discountAmount).toFixed(2));

  return {
    items: calculatedItems,
    subtotal,
    discountType,
    discountValue,
    discountAmount,
    totalAmount,
  };
};

export const generateNextSequence = async (Model, fieldName = 'estimateNumber') => {
  const latest = await Model.findOne().sort({ createdAt: -1 }).select(fieldName).lean();

  if (!latest?.[fieldName]) {
    return 1;
  }

  const lastNumber = latest[fieldName];
  const sequence = Number(lastNumber.split('-').pop());
  return Number.isNaN(sequence) ? 1 : sequence + 1;
};

export const calculatePaymentDetails = (totalAmount, amountReceived = 0) => {
  const received = Number(amountReceived || 0);
  const total = Number(totalAmount || 0);

  if (received <= 0) {
    return {
      status: 'Unpaid',
      amountReceived: 0,
      pendingAmount: total,
    };
  }

  if (received >= total) {
    return {
      status: 'Paid',
      amountReceived: total,
      pendingAmount: 0,
    };
  }

  return {
    status: 'Partially Paid',
    amountReceived: received,
    pendingAmount: Number((total - received).toFixed(2)),
  };
};
