export const calculateEstimateItems = (items = []) => {
  return items.map((item) => {
    const quantity = Number(item.quantity || 0);
    const pricePerUnit = Number(item.pricePerUnit || 0);
    const baseAmount = Number((quantity * pricePerUnit).toFixed(2));

    if (!item.taxApplicable) {
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

    const gstPercentage = Number(item.gstPercentage || 18);
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

export const calculateEstimateTotals = (items = []) => {
  const calculatedItems = calculateEstimateItems(items);

  const subtotal = Number(
    calculatedItems.reduce((sum, item) => {
      const quantity = Number(item.quantity || 0);
      const pricePerUnit = Number(item.pricePerUnit || 0);
      return sum + quantity * pricePerUnit;
    }, 0).toFixed(2)
  );

  const totalTax = Number(
    calculatedItems.reduce((sum, item) => {
      return sum + (Number(item.sgst || 0) + Number(item.cgst || 0));
    }, 0).toFixed(2)
  );

  const totalAmount = Number((subtotal + totalTax).toFixed(2));

  return {
    items: calculatedItems,
    subtotal,
    totalTax,
    totalAmount,
  };
};

export const formatEstimateNumber = (sequence) => {
  const year = new Date().getFullYear();
  return `EST-${year}-${String(sequence).padStart(4, '0')}`;
};

export const formatInvoiceNumber = (sequence) => {
  const year = new Date().getFullYear();
  return `INV-${year}-${String(sequence).padStart(4, '0')}`;
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
