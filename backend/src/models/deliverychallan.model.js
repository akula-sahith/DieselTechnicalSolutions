import mongoose from 'mongoose';

const deliveryChallanItemSchema = new mongoose.Schema(
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
  },
  { _id: false }
);

const deliveryChallanSchema = new mongoose.Schema(
  {
    challanNumber: {
      type: String,
      unique: true,
      trim: true,
      index: true,
      required: true,
    },
    challanDate: {
      type: Date,
      default: Date.now,
      index: true,
    },
    deliveryChallanFor: {
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
        default: '',
      },
      contactNumber: {
        type: String,
        trim: true,
        index: true,
        default: '',
      },
      gstinNumber: {
        type: String,
        trim: true,
        default: '',
      },
      state: {
        type: String,
        trim: true,
        default: '36-Telangana',
      },
    },
    transportationDetails: {
      vehicleNumber: {
        type: String,
        trim: true,
        default: '',
      },
      dispatchDate: {
        type: Date,
        default: null,
      },
      destinationLocation: {
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
    },
    placeOfSupply: {
      type: String,
      trim: true,
      default: '36-Telangana',
    },
    items: {
      type: [deliveryChallanItemSchema],
      validate: [
        (items) => Array.isArray(items) && items.length > 0,
        'At least one item is required.',
      ],
    },
    totalQuantity: {
      type: Number,
      default: 0,
    },
    termsAndConditions: {
      type: String,
      trim: true,
      default:
        'Thank you for doing business with us.\n1. All disputes subject to Secunderabad Jurisdiction only\n2. Does not include erection & commissioning at site\n3. Transit insurance from factory to site will be buyer\'s responsibility\n4. Interest @ 24% p.a. will be charged on balance payments, if material not collected against confirmed order within one week of our intimation of material being ready for dispatch',
    },
    receivedBy: {
      name: { type: String, trim: true, default: '' },
      comment: { type: String, trim: true, default: '' },
      date: { type: Date, default: null },
      signatureUrl: { type: String, trim: true, default: '' },
    },
    deliveredBy: {
      name: { type: String, trim: true, default: '' },
      comment: { type: String, trim: true, default: '' },
      date: { type: Date, default: null },
      signatureUrl: { type: String, trim: true, default: '' },
    },
    authorizedSignatureUrl: {
      type: String,
      trim: true,
      default:
        'https://res.cloudinary.com/dy5gs2egc/image/upload/v1782710059/efsr/signatures/i1ijhzyhgkmeig7v7cad.png',
    },
    pdfUrl: {
      type: String,
      trim: true,
    },
    linkedEstimateId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Estimate',
      index: true,
      default: null,
    },
    status: {
      type: String,
      enum: ['draft', 'issued', 'delivered', 'cancelled'],
      default: 'issued',
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

deliveryChallanSchema.index({
  challanNumber: 'text',
  'deliveryChallanFor.customerName': 'text',
  'transportationDetails.vehicleNumber': 'text',
});

const DeliveryChallan = mongoose.model('DeliveryChallan', deliveryChallanSchema);

export default DeliveryChallan;
