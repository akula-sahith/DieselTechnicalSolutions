import mongoose from 'mongoose';

const billingItemSchema = new mongoose.Schema(
  {
    itemName: {
      type: String,
      trim: true,
      required: true,
    },
    hsnSac: {
      type: String,
      trim: true,
      default: '',
    },
    quantity: {
      type: Number,
      required: true,
      min: 0.0001,
    },
    pricePerUnit: {
      type: Number,
      required: true,
      min: 0.0001,
    },
    amount: {
      type: Number,
      default: 0,
    },
  },
  { _id: false }
);

const transportationDetailsSchema = new mongoose.Schema(
  {
    vehicleNumber: {
      type: String,
      trim: true,
      default: '',
    },
    transportName: {
      type: String,
      trim: true,
      default: '',
    },
    lrNumber: {
      type: String,
      trim: true,
      default: '',
    },
    dispatchDetails: {
      type: String,
      trim: true,
      default: '',
    },
    deliveryDetails: {
      type: String,
      trim: true,
      default: '',
    },
  },
  { _id: false }
);

const billingInvoiceSchema = new mongoose.Schema(
  {
    invoiceNumber: {
      type: String,
      unique: true,
      trim: true,
      index: true,
      required: true,
    },
    invoiceDate: {
      type: Date,
      default: Date.now,
      index: true,
    },
    billTo: {
      customerName: {
        type: String,
        trim: true,
        required: true,
        index: true,
      },
      address: {
        type: String,
        trim: true,
        required: true,
      },
      contactPerson: {
        type: String,
        trim: true,
      },
      contactNumber: {
        type: String,
        trim: true,
        index: true,
      },
      gstinNumber: {
        type: String,
        trim: true,
        default: '',
      },
    },
    placeOfSupply: {
      type: String,
      trim: true,
      default: '',
    },
    transportationDetails: transportationDetailsSchema,
    items: {
      type: [billingItemSchema],
      validate: [
        (items) => Array.isArray(items) && items.length > 0,
        'At least one item is required.',
      ],
    },
    totalAmount: {
      type: Number,
      default: 0,
    },
    amountInWords: {
      type: String,
      trim: true,
    },
    termsAndConditions: {
      type: String,
      trim: true,
      default: 'Thank you for doing business with us.\n*100% advance is mandatory',
    },
    authorizedSignatureUrl: {
      type: String,
      trim: true,
      default: 'https://res.cloudinary.com/dy5gs2egc/image/upload/v1782710059/efsr/signatures/i1ijhzyhgkmeig7v7cad.png',
    },
    pdfUrl: {
      type: String,
      trim: true,
    },
    linkedEstimateId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Estimate',
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

billingInvoiceSchema.index({
  invoiceNumber: 'text',
  'billTo.customerName': 'text',
  'billTo.contactNumber': 'text',
});

const BillingInvoice = mongoose.model('BillingInvoice', billingInvoiceSchema);

export default BillingInvoice;
