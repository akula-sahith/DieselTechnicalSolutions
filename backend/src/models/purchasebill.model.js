import mongoose from 'mongoose';

const purchaseBillSchema = new mongoose.Schema(
  {
    billNumber: {
      type: String,
      trim: true,
      default: '',
    },
    vendorName: {
      type: String,
      trim: true,
      required: true,
      index: true,
    },
    billDate: {
      type: Date,
      default: Date.now,
      index: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    taxAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    attachmentUrl: {
      type: String,
      required: true,
      trim: true,
    },
    remarks: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['pending', 'paid'],
      default: 'pending',
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

purchaseBillSchema.index({ vendorName: 'text', billNumber: 'text' });

const PurchaseBill = mongoose.model('PurchaseBill', purchaseBillSchema);

export default PurchaseBill;
