import mongoose from 'mongoose';

const descriptionItemSchema = new mongoose.Schema(
  {
    description: {
      type: String,
      trim: true,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 0.0001,
    },
    rate: {
      type: Number,
      required: true,
      min: 0.0001,
    },
    subTotal: {
      type: Number,
      default: 0,
    },
  },
  { _id: false }
);

const agreementSchema = new mongoose.Schema(
  {
    documentType: {
      type: String,
      enum: ['Agreement', 'Quotation'],
      required: true,
      index: true,
    },
    offerNumber: {
      type: String,
      unique: true,
      trim: true,
      index: true,
    },
    date: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
    customerName: {
      type: String,
      trim: true,
      index: true,
    },
    completeAddress: {
      type: String,
      trim: true,
    },
    contactPerson: {
      type: String,
      trim: true,
    },
    mobileNumber: {
      type: String,
      trim: true,
      index: true,
    },
    descriptionItems: {
      type: [descriptionItemSchema],
      default: [],
    },
    gstRequired: {
      type: Boolean,
      default: false,
    },
    gstPercentage: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    totalBeforeGST: {
      type: Number,
      default: 0,
    },
    gstAmount: {
      type: Number,
      default: 0,
    },
    grandTotal: {
      type: Number,
      default: 0,
    },
    amountInWords: {
      type: String,
      trim: true,
    },
    technicianSignatureUrl: {
      type: String,
      trim: true,
      required: true,
      default: 'https://res.cloudinary.com/dy5gs2egc/image/upload/v1782710059/efsr/signatures/i1ijhzyhgkmeig7v7cad.png',
    },
    customerSignatureUrl: {
      type: String,
      trim: true,
    },
    termsAndConditions: {
      type: String,
      trim: true,
      default: 'All services are subject to the agreed AMC scope, scheduled maintenance, and site accessibility. Any additional work outside the agreed scope will be billed separately.',
    },
    paymentTerms: {
      type: String,
      trim: true,
      default: 'Payment is due within 15 days from the date of invoice.',
    },
    offerValidity: {
      type: String,
      trim: true,
      default: 'This offer is valid for 15 days from the date of issue.',
    },
    notes: {
      type: String,
      trim: true,
      default: 'Please confirm the scope and service commencement date at the earliest.',
    },
    footerText: {
      type: String,
      trim: true,
      default: 'Thank you for choosing GPS Technical Services.',
    },
    numberOfFreeVisits: {
      type: Number,
      default: 6,
    },
    status: {
      type: String,
      enum: ['draft', 'submitted'],
      default: 'submitted',
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

agreementSchema.index({ offerNumber: 'text', customerName: 'text', mobileNumber: 'text', documentType: 'text' });

const Agreement = mongoose.model('Agreement', agreementSchema);

export default Agreement;
