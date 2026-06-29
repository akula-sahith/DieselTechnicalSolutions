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
    const technicianSignatureFile = req.files?.technicianSignature?.[0];
    const customerPhotoFile = req.files?.customerPhoto?.[0];

    if (!technicianSignatureFile || !customerPhotoFile) {
      return sendError(
        res,
        "Both technician signature and customer photo are required.",
        {},
        400
      );
    }

    const rawReportPayload = req.body?.report ?? req.body;

    if (!rawReportPayload) {
      return sendError(res, "The report field is required.", {}, 400);
    }

    const reportData =
      typeof rawReportPayload === "string"
        ? JSON.parse(rawReportPayload)
        : rawReportPayload;

    const [technicianSignatureUrl, customerPhotoUrl] = await Promise.all([
      uploadToCloudinary(technicianSignatureFile, "efsr/signatures"),
      uploadToCloudinary(customerPhotoFile, "efsr/customers"),
    ]);

    const reportDocument = {
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

    const query = search
      ? {
          $or: [
            { 'serviceAndCustomer.jobRef': { $regex: search, $options: 'i' } },
            { 'serviceAndCustomer.customerName': { $regex: search, $options: 'i' } },
            { 'serviceAndCustomer.contactNumber': { $regex: search, $options: 'i' } },
          ],
        }
      : {};

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
