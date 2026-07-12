import mongoose from 'mongoose';

const invoiceHistorySchema = new mongoose.Schema(
  {
    invoiceNumber: { type: String, trim: true, required: true },
    invoiceDate: { type: Date, default: Date.now },
    invoiceAmount: { type: Number, default: 0 },
  },
  { _id: false }
);

const customerSchema = new mongoose.Schema(
  {
    customerName: { type: String, trim: true, required: true },
    companyName: { type: String, trim: true, default: '' },
    gstNumber: { type: String, trim: true, index: true, default: '' },
    contactPerson: { type: String, trim: true, default: '' },
    mobileNumber: { type: String, trim: true, index: true, default: '' },
    email: { type: String, trim: true, default: '' },
    address: { type: String, trim: true, default: '' },
    invoiceHistory: { type: [invoiceHistorySchema], default: [] },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

customerSchema.index({ gstNumber: 'text', mobileNumber: 'text', customerName: 'text' });

const Customer = mongoose.model('Customer', customerSchema);

export default Customer;
