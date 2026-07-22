import mongoose from 'mongoose';

const estimateItemSchema = new mongoose.Schema(
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
    taxApplicable: {
      type: Boolean,
      default: true,
    },
    gstPercentage: {
      type: Number,
      enum: [0, 0.25, 3, 5, 12, 18, 28, 40],
      default: 18,
    },
    sgst: {
      type: Number,
      default: 0,
    },
    cgst: {
      type: Number,
      default: 0,
    },
    amount: {
      type: Number,
      default: 0,
    },
  },
  { _id: false }
);

const estimateSchema = new mongoose.Schema(
  {
    estimateNumber: {
      type: String,
      unique: true,
      trim: true,
      index: true,
      required: true,
    },
    estimateDate: {
      type: Date,
      default: Date.now,
      index: true,
    },
    estimateFor: {
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
    items: {
      type: [estimateItemSchema],
      validate: [
        (items) => Array.isArray(items) && items.length > 0,
        'At least one item is required.',
      ],
    },
    subtotal: {
      type: Number,
      default: 0,
    },
    totalTax: {
      type: Number,
      default: 0,
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
    status: {
      type: String,
      enum: ['draft', 'sent', 'accepted', 'rejected', 'converted'],
      default: 'draft',
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

estimateSchema.index({
  estimateNumber: 'text',
  'estimateFor.customerName': 'text',
  'estimateFor.contactNumber': 'text',
});

const Estimate = mongoose.model('Estimate', estimateSchema);

export default Estimate;
