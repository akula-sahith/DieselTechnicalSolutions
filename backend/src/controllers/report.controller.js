import Report from '../models/report.model.js';
import uploadToCloudinary from '../services/upload.service.js';
import { sendSuccess, sendError } from '../utils/response.js';

const buildChecklist = (items = []) => {
  return items.map((item) => ({
    parameter: item.parameter,
    status: item.status || 'ok',
  }));
};

const buildPartsUsed = (items = []) => {
  return items.map((item) => ({
    partDescription: item.partDescription,
    qty: item.qty || '1',
  }));
};

export const createReport = async (req, res) => {
  try {
    const rawReportPayload = req.body?.report ?? req.body;

    if (!rawReportPayload) {
      return sendError(res, "The report field is required.", {}, 400);
    }

    const reportData =
      typeof rawReportPayload === "string"
        ? JSON.parse(rawReportPayload)
        : rawReportPayload;

    const status = reportData.status || 'submitted';
    const customerPhotoFile = req.files?.customerPhoto?.[0];

    if (status === 'submitted' && !customerPhotoFile) {
      return sendError(
        res,
        "Customer photo is required.",
        {},
        400
      );
    }

    let customerPhotoUrl = '';
    if (customerPhotoFile) {
      customerPhotoUrl = await uploadToCloudinary(customerPhotoFile, "efsr/customers");
    } else if (reportData.authorization?.customerPhotoUrl) {
      customerPhotoUrl = reportData.authorization.customerPhotoUrl;
    }

    const technicianSignatureUrl = "https://res.cloudinary.com/dy5gs2egc/image/upload/v1782710059/efsr/signatures/i1ijhzyhgkmeig7v7cad.png";

    const reportDocument = {
      status,
      serviceAndCustomer: {
        jobRef:
          reportData.serviceAndCustomer?.jobRef ?? reportData.jobRef,
        dateTime:
          reportData.serviceAndCustomer?.dateTime ?? reportData.dateTime,
        customerName:
          reportData.serviceAndCustomer?.customerName ??
          reportData.customerName,
        siteLocation:
          reportData.serviceAndCustomer?.siteLocation ??
          reportData.siteLocation,
        contactPerson:
          reportData.serviceAndCustomer?.contactPerson ??
          reportData.contactPerson,
        contactNumber:
          reportData.serviceAndCustomer?.contactNumber ??
          reportData.contactNumber,
      },

      equipmentAndEngine: {
        generatorMakeModel:
          reportData.equipmentAndEngine?.generatorMakeModel ??
          reportData.generatorMakeModel,
        capacity:
          reportData.equipmentAndEngine?.capacity ??
          reportData.capacity,
        engineSerialNo:
          reportData.equipmentAndEngine?.engineSerialNo ??
          reportData.engineSerialNo,
        alternatorSerialNo:
          reportData.equipmentAndEngine?.alternatorSerialNo ??
          reportData.alternatorSerialNo,
        hourMeter:
          reportData.equipmentAndEngine?.hourMeter ??
          reportData.hourMeter,
        hours:
          reportData.equipmentAndEngine?.hours ??
          reportData.hours
            ? Number(
                reportData.equipmentAndEngine?.hours ??
                  reportData.hours
              )
            : undefined,
        batteryStatusVolt:
          reportData.equipmentAndEngine?.batteryStatusVolt ??
          reportData.batteryStatusVolt,
      },

      serviceChecklist: buildChecklist(
        reportData.serviceChecklist || []
      ),

      partsUsed: buildPartsUsed(
        reportData.partsUsed || []
      ),

      remarksAndActionPlan: {
        observations:
          reportData.remarksAndActionPlan?.observations ??
          reportData.observations,
        nextServiceDueDate:
          reportData.remarksAndActionPlan?.nextServiceDueDate ??
          reportData.nextServiceDueDate,
        nextServiceDueHours:
          reportData.remarksAndActionPlan?.nextServiceDueHours ??
          reportData.nextServiceDueHours
            ? Number(
                reportData.remarksAndActionPlan?.nextServiceDueHours ??
                  reportData.nextServiceDueHours
              )
            : undefined,
      },

      authorization: {
        technicianName:
          reportData.authorization?.technicianName ??
          reportData.technicianName,
        technicianSignatureUrl,
        customerRepresentativeName:
          reportData.authorization?.customerRepresentativeName ??
          reportData.customerRepresentativeName,
        customerPhotoUrl,
        technicianDate:
          reportData.authorization?.technicianDate ??
          reportData.technicianDate,
        customerDate:
          reportData.authorization?.customerDate ??
          reportData.customerDate,
      },
    };

    const report = await Report.create(reportDocument);

    return sendSuccess(
      res,
      "Service report created successfully.",
      report,
      201
    );
  } catch (error) {
    if (error instanceof SyntaxError) {
      return sendError(
        res,
        "Invalid JSON payload.",
        { details: error.message },
        400
      );
    }

    return sendError(
      res,
      "Failed to create service report.",
      { details: error.message },
      500
    );
  }
};

export const getReports = async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
    const skip = (page - 1) * limit;
    const search = req.query.search || '';
    const status = req.query.status || '';

    const query = status ? { status } : {};

    if (search) {
      query.$or = [
        { 'serviceAndCustomer.jobRef': { $regex: search, $options: 'i' } },
        { 'serviceAndCustomer.customerName': { $regex: search, $options: 'i' } },
        { 'serviceAndCustomer.contactNumber': { $regex: search, $options: 'i' } },
      ];
    }

    const [reports, total] = await Promise.all([
      Report.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Report.countDocuments(query),
    ]);

    return sendSuccess(res, 'Reports retrieved successfully.', {
      reports,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(res, 'Failed to fetch reports.', { details: error.message }, 500);
  }
};

export const getReportById = async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      return sendError(res, 'Service report not found.', {}, 404);
    }

    return sendSuccess(res, 'Service report retrieved successfully.', report);
  } catch (error) {
    return sendError(res, 'Failed to fetch service report.', { details: error.message }, 500);
  }
};

export const updateReport = async (req, res) => {
  try {
    const rawReportPayload = req.body?.report ?? req.body;

    if (!rawReportPayload) {
      return sendError(res, "The report field is required.", {}, 400);
    }

    const reportData =
      typeof rawReportPayload === "string"
        ? JSON.parse(rawReportPayload)
        : rawReportPayload;

    const report = await Report.findById(req.params.id);
    if (!report) {
      return sendError(res, 'Service report not found.', {}, 404);
    }

    const status = reportData.status || report.status || 'submitted';
    const customerPhotoFile = req.files?.customerPhoto?.[0];

    const currentPhotoUrl = reportData.authorization?.customerPhotoUrl ?? report.authorization?.customerPhotoUrl;

    if (status === 'submitted' && !customerPhotoFile && (!currentPhotoUrl || currentPhotoUrl === '')) {
      return sendError(
        res,
        "Customer photo is required.",
        {},
        400
      );
    }

    let customerPhotoUrl = currentPhotoUrl || '';
    if (customerPhotoFile) {
      customerPhotoUrl = await uploadToCloudinary(customerPhotoFile, "efsr/customers");
    }

    const technicianSignatureUrl = "https://res.cloudinary.com/dy5gs2egc/image/upload/v1782710059/efsr/signatures/i1ijhzyhgkmeig7v7cad.png";

    const reportDocument = {
      status,
      serviceAndCustomer: {
        jobRef:
          reportData.serviceAndCustomer?.jobRef ?? reportData.jobRef ?? report.serviceAndCustomer.jobRef,
        dateTime:
          reportData.serviceAndCustomer?.dateTime ?? reportData.dateTime ?? report.serviceAndCustomer.dateTime,
        customerName:
          reportData.serviceAndCustomer?.customerName ??
          reportData.customerName ?? report.serviceAndCustomer.customerName,
        siteLocation:
          reportData.serviceAndCustomer?.siteLocation ??
          reportData.siteLocation ?? report.serviceAndCustomer.siteLocation,
        contactPerson:
          reportData.serviceAndCustomer?.contactPerson ??
          reportData.contactPerson ?? report.serviceAndCustomer.contactPerson,
        contactNumber:
          reportData.serviceAndCustomer?.contactNumber ??
          reportData.contactNumber ?? report.serviceAndCustomer.contactNumber,
      },

      equipmentAndEngine: {
        generatorMakeModel:
          reportData.equipmentAndEngine?.generatorMakeModel ??
          reportData.generatorMakeModel ?? report.equipmentAndEngine.generatorMakeModel,
        capacity:
          reportData.equipmentAndEngine?.capacity ??
          reportData.capacity ?? report.equipmentAndEngine.capacity,
        engineSerialNo:
          reportData.equipmentAndEngine?.engineSerialNo ??
          reportData.engineSerialNo ?? report.equipmentAndEngine.engineSerialNo,
        alternatorSerialNo:
          reportData.equipmentAndEngine?.alternatorSerialNo ??
          reportData.alternatorSerialNo ?? report.equipmentAndEngine.alternatorSerialNo,
        hourMeter:
          reportData.equipmentAndEngine?.hourMeter ??
          reportData.hourMeter ?? report.equipmentAndEngine.hourMeter,
        hours:
          reportData.equipmentAndEngine?.hours ??
          reportData.hours
            ? Number(
                reportData.equipmentAndEngine?.hours ??
                  reportData.hours
              )
            : report.equipmentAndEngine.hours,
        batteryStatusVolt:
          reportData.equipmentAndEngine?.batteryStatusVolt ??
          reportData.batteryStatusVolt ?? report.equipmentAndEngine.batteryStatusVolt,
      },

      serviceChecklist: buildChecklist(
        reportData.serviceChecklist || report.serviceChecklist || []
      ),

      partsUsed: buildPartsUsed(
        reportData.partsUsed || report.partsUsed || []
      ),

      remarksAndActionPlan: {
        observations:
          reportData.remarksAndActionPlan?.observations ??
          reportData.observations ?? report.remarksAndActionPlan.observations,
        nextServiceDueDate:
          reportData.remarksAndActionPlan?.nextServiceDueDate ??
          reportData.nextServiceDueDate ?? report.remarksAndActionPlan.nextServiceDueDate,
        nextServiceDueHours:
          reportData.remarksAndActionPlan?.nextServiceDueHours ??
          reportData.nextServiceDueHours
            ? Number(
                reportData.remarksAndActionPlan?.nextServiceDueHours ??
                  reportData.nextServiceDueHours
              )
            : report.remarksAndActionPlan.nextServiceDueHours,
      },

      authorization: {
        technicianName:
          reportData.authorization?.technicianName ??
          reportData.technicianName ?? report.authorization.technicianName,
        technicianSignatureUrl,
        customerRepresentativeName:
          reportData.authorization?.customerRepresentativeName ??
          reportData.customerRepresentativeName ?? report.authorization.customerRepresentativeName,
        customerPhotoUrl,
        technicianDate:
          reportData.authorization?.technicianDate ??
          reportData.technicianDate ?? report.authorization.technicianDate,
        customerDate:
          reportData.authorization?.customerDate ??
          reportData.customerDate ?? report.authorization.customerDate,
      },
    };

    const updatedReport = await Report.findByIdAndUpdate(req.params.id, reportDocument, { new: true });

    return sendSuccess(
      res,
      "Service report updated successfully.",
      updatedReport
    );
  } catch (error) {
    if (error instanceof SyntaxError) {
      return sendError(
        res,
        "Invalid JSON payload.",
        { details: error.message },
        400
      );
    }

    return sendError(
      res,
      "Failed to update service report.",
      { details: error.message },
      500
    );
  }
};

export const deleteReport = async (req, res) => {
  try {
    const report = await Report.findByIdAndDelete(req.params.id);

    if (!report) {
      return sendError(res, 'Service report not found.', {}, 404);
    }

    return sendSuccess(res, 'Service report deleted successfully.', {});
  } catch (error) {
    return sendError(res, 'Failed to delete service report.', { details: error.message }, 500);
  }
};
