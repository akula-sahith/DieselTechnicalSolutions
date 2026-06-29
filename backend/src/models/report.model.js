import mongoose from 'mongoose';

const serviceChecklistItemSchema = new mongoose.Schema(
  {
    parameter: {
      type: String,
      trim: true,
      required: true,
    },
    status: {
      type: String,
      enum: ['ok', 'req', 'n/a'],
      default: 'ok',
    },
  },
  { _id: false }
);

const partsUsedItemSchema = new mongoose.Schema(
  {
    partDescription: {
      type: String,
      trim: true,
      required: true,
    },
    qty: {
      type: String,
      trim: true,
      default: '1',
    },
  },
  { _id: false }
);

const reportSchema = new mongoose.Schema(
  {
    serviceAndCustomer: {
      jobRef: {
        type: String,
        trim: true,
        required: true,
        index: true,
      },
      dateTime: {
        type: Date,
        required: true,
      },
      customerName: {
        type: String,
        trim: true,
        required: true,
        index: true,
      },
      siteLocation: {
        type: String,
        trim: true,
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
    },
    equipmentAndEngine: {
      generatorMakeModel: {
        type: String,
        trim: true,
      },
      capacity: {
        type: String,
        trim: true,
      },
      engineSerialNo: {
        type: String,
        trim: true,
      },
      alternatorSerialNo: {
        type: String,
        trim: true,
      },
      hourMeter: {
        type: String,
        trim: true,
      },
      hours: {
        type: Number,
        min: 0,
      },
      batteryStatusVolt: {
        type: String,
        trim: true,
      },
    },
    serviceChecklist: {
      type: [serviceChecklistItemSchema],
      default: [],
    },
    partsUsed: {
      type: [partsUsedItemSchema],
      default: [],
    },
    remarksAndActionPlan: {
      observations: {
        type: String,
        trim: true,
      },
      nextServiceDueDate: {
        type: Date,
      },
      nextServiceDueHours: {
        type: Number,
        min: 0,
      },
    },
    authorization: {
      technicianName: {
        type: String,
        trim: true,
      },
      technicianSignatureUrl: {
        type: String,
        trim: true,
        required: true,
      },
      customerRepresentativeName: {
        type: String,
        trim: true,
      },
      customerPhotoUrl: {
        type: String,
        trim: true,
        required: true,
      },
      technicianDate: {
        type: Date,
      },
      customerDate: {
        type: Date,
      },
    },
  },
  {
    timestamps: true,
  }
);

reportSchema.index({ 'serviceAndCustomer.jobRef': 'text', 'serviceAndCustomer.customerName': 'text', 'serviceAndCustomer.contactNumber': 'text' });

const Report = mongoose.model('Report', reportSchema);

export default Report;
