import DeliveryChallan from '../models/deliverychallan.model.js';
import Estimate from '../models/estimate.model.js';
import { sendSuccess, sendError } from '../utils/response.js';
import {
  formatChallanNumber,
  generateNextSequence,
} from '../utils/financial.utils.js';
import { upsertCustomerFromInvoice } from '../utils/customer.utils.js';

const getChallanPayload = (req) => {
  const rawPayload = req.body?.deliveryChallan ?? req.body;
  if (!rawPayload) {
    return null;
  }

  return typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
};

export const createDeliveryChallan = async (req, res) => {
  try {
    const payload = getChallanPayload(req);

    if (!payload) {
      return sendError(res, 'Delivery Challan payload is required.', {}, 400);
    }

    const items = payload.items || [];
    if (!Array.isArray(items) || items.length === 0) {
      return sendError(res, 'At least one item is required.', {}, 400);
    }

    const requiredCustomerFields = ['customerName', 'address'];
    const missingField = requiredCustomerFields.find(
      (field) => !payload.deliveryChallanFor?.[field]
    );
    if (missingField) {
      return sendError(
        res,
        `Customer field "${missingField}" is required.`,
        {},
        400
      );
    }

    const invalidItem = items.find(
      (item) => !item.itemName || !item.quantity || Number(item.quantity) <= 0
    );
    if (invalidItem) {
      return sendError(
        res,
        'Each item must have a valid item name and quantity > 0.',
        {},
        400
      );
    }

    const cleanedItems = items.map((item) => ({
      itemName: String(item.itemName).trim(),
      hsnSac: item.hsnSac ? String(item.hsnSac).trim() : '',
      quantity: Number(item.quantity),
    }));

    const totalQuantity = cleanedItems.reduce(
      (sum, item) => sum + item.quantity,
      0
    );

    const sequence = await generateNextSequence(DeliveryChallan, 'challanNumber');

    const documentData = {
      challanNumber: payload.challanNumber || formatChallanNumber(sequence),
      challanDate: payload.challanDate ? new Date(payload.challanDate) : new Date(),
      deliveryChallanFor: {
        customerName: String(payload.deliveryChallanFor.customerName).trim(),
        address: String(payload.deliveryChallanFor.address).trim(),
        contactPerson: payload.deliveryChallanFor.contactPerson
          ? String(payload.deliveryChallanFor.contactPerson).trim()
          : '',
        contactNumber: payload.deliveryChallanFor.contactNumber
          ? String(payload.deliveryChallanFor.contactNumber).trim()
          : '',
        gstinNumber: payload.deliveryChallanFor.gstinNumber
          ? String(payload.deliveryChallanFor.gstinNumber).trim()
          : '',
        state: payload.deliveryChallanFor.state
          ? String(payload.deliveryChallanFor.state).trim()
          : '36-Telangana',
      },
      transportationDetails: {
        vehicleNumber: payload.transportationDetails?.vehicleNumber
          ? String(payload.transportationDetails.vehicleNumber).trim()
          : '',
        dispatchDate: payload.transportationDetails?.dispatchDate
          ? new Date(payload.transportationDetails.dispatchDate)
          : null,
        destinationLocation: payload.transportationDetails?.destinationLocation
          ? String(payload.transportationDetails.destinationLocation).trim()
          : '',
        transportName: payload.transportationDetails?.transportName
          ? String(payload.transportationDetails.transportName).trim()
          : '',
        lrNumber: payload.transportationDetails?.lrNumber
          ? String(payload.transportationDetails.lrNumber).trim()
          : '',
      },
      placeOfSupply: payload.placeOfSupply
        ? String(payload.placeOfSupply).trim()
        : '36-Telangana',
      items: cleanedItems,
      totalQuantity,
      termsAndConditions: payload.termsAndConditions,
      receivedBy: {
        name: payload.receivedBy?.name ? String(payload.receivedBy.name).trim() : '',
        comment: payload.receivedBy?.comment
          ? String(payload.receivedBy.comment).trim()
          : '',
        date: payload.receivedBy?.date ? new Date(payload.receivedBy.date) : null,
        signatureUrl: payload.receivedBy?.signatureUrl
          ? String(payload.receivedBy.signatureUrl).trim()
          : '',
      },
      deliveredBy: {
        name: payload.deliveredBy?.name
          ? String(payload.deliveredBy.name).trim()
          : '',
        comment: payload.deliveredBy?.comment
          ? String(payload.deliveredBy.comment).trim()
          : '',
        date: payload.deliveredBy?.date ? new Date(payload.deliveredBy.date) : null,
        signatureUrl: payload.deliveredBy?.signatureUrl
          ? String(payload.deliveredBy.signatureUrl).trim()
          : '',
      },
      authorizedSignatureUrl: payload.authorizedSignatureUrl,
      linkedEstimateId: payload.linkedEstimateId || null,
      status: payload.status || 'issued',
    };

    const deliveryChallan = await DeliveryChallan.create(documentData);

    // Upsert customer history safely
    try {
      await upsertCustomerFromInvoice(
        {
          customerName: deliveryChallan.deliveryChallanFor.customerName,
          address: deliveryChallan.deliveryChallanFor.address,
          contactPerson: deliveryChallan.deliveryChallanFor.contactPerson,
          contactNumber: deliveryChallan.deliveryChallanFor.contactNumber,
          gstinNumber: deliveryChallan.deliveryChallanFor.gstinNumber,
        },
        deliveryChallan
      );
    } catch (e) {
      console.error(
        'Failed to upsert customer from delivery challan:',
        e?.message || e
      );
    }

    return sendSuccess(
      res,
      'Delivery Challan created successfully.',
      deliveryChallan,
      201
    );
  } catch (error) {
    if (error.code === 11000) {
      return sendError(
        res,
        'Delivery Challan number already exists.',
        { details: error.message },
        400
      );
    }

    return sendError(
      res,
      'Failed to create Delivery Challan.',
      { details: error.message },
      500
    );
  }
};

export const getDeliveryChallans = async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
    const skip = (page - 1) * limit;
    const search = req.query.search || '';
    const status = req.query.status || '';
    const customerName = req.query.customerName || '';
    const challanNumber = req.query.challanNumber || '';
    const dateFrom = req.query.dateFrom || '';
    const dateTo = req.query.dateTo || '';

    const query = {};

    if (search) {
      query.$or = [
        { challanNumber: { $regex: search, $options: 'i' } },
        { 'deliveryChallanFor.customerName': { $regex: search, $options: 'i' } },
        { 'transportationDetails.vehicleNumber': { $regex: search, $options: 'i' } },
      ];
    }

    if (status) {
      query.status = status;
    }

    if (customerName) {
      query['deliveryChallanFor.customerName'] = {
        $regex: customerName,
        $options: 'i',
      };
    }

    if (challanNumber) {
      query.challanNumber = { $regex: challanNumber, $options: 'i' };
    }

    if (dateFrom || dateTo) {
      query.challanDate = {};
      if (dateFrom) {
        query.challanDate.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        const endDate = new Date(dateTo);
        endDate.setDate(endDate.getDate() + 1);
        query.challanDate.$lt = endDate;
      }
    }

    const [deliveryChallans, total] = await Promise.all([
      DeliveryChallan.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit),
      DeliveryChallan.countDocuments(query),
    ]);

    return sendSuccess(res, 'Delivery Challans retrieved successfully.', {
      deliveryChallans,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return sendError(
      res,
      'Failed to fetch Delivery Challans.',
      { details: error.message },
      500
    );
  }
};

export const getDeliveryChallanById = async (req, res) => {
  try {
    const deliveryChallan = await DeliveryChallan.findById(req.params.id);

    if (!deliveryChallan) {
      return sendError(res, 'Delivery Challan not found.', {}, 404);
    }

    return sendSuccess(
      res,
      'Delivery Challan retrieved successfully.',
      deliveryChallan
    );
  } catch (error) {
    return sendError(
      res,
      'Failed to fetch Delivery Challan.',
      { details: error.message },
      500
    );
  }
};

export const updateDeliveryChallan = async (req, res) => {
  try {
    const payload = getChallanPayload(req);

    if (!payload) {
      return sendError(res, 'Delivery Challan payload is required.', {}, 400);
    }

    const deliveryChallan = await DeliveryChallan.findById(req.params.id);
    if (!deliveryChallan) {
      return sendError(res, 'Delivery Challan not found.', {}, 404);
    }

    const items = payload.items || deliveryChallan.items || [];
    if (!Array.isArray(items) || items.length === 0) {
      return sendError(res, 'At least one item is required.', {}, 400);
    }

    const cleanedItems = items.map((item) => ({
      itemName: String(item.itemName).trim(),
      hsnSac: item.hsnSac ? String(item.hsnSac).trim() : '',
      quantity: Number(item.quantity),
    }));

    const totalQuantity = cleanedItems.reduce(
      (sum, item) => sum + item.quantity,
      0
    );

    const updatePayload = {
      challanDate: payload.challanDate
        ? new Date(payload.challanDate)
        : deliveryChallan.challanDate,
      deliveryChallanFor: {
        customerName:
          payload.deliveryChallanFor?.customerName ||
          deliveryChallan.deliveryChallanFor.customerName,
        address:
          payload.deliveryChallanFor?.address ||
          deliveryChallan.deliveryChallanFor.address,
        contactPerson:
          payload.deliveryChallanFor?.contactPerson !== undefined
            ? payload.deliveryChallanFor.contactPerson
            : deliveryChallan.deliveryChallanFor.contactPerson,
        contactNumber:
          payload.deliveryChallanFor?.contactNumber !== undefined
            ? payload.deliveryChallanFor.contactNumber
            : deliveryChallan.deliveryChallanFor.contactNumber,
        gstinNumber:
          payload.deliveryChallanFor?.gstinNumber !== undefined
            ? payload.deliveryChallanFor.gstinNumber
            : deliveryChallan.deliveryChallanFor.gstinNumber,
        state:
          payload.deliveryChallanFor?.state ||
          deliveryChallan.deliveryChallanFor.state,
      },
      transportationDetails: {
        vehicleNumber:
          payload.transportationDetails?.vehicleNumber !== undefined
            ? payload.transportationDetails.vehicleNumber
            : deliveryChallan.transportationDetails.vehicleNumber,
        dispatchDate: payload.transportationDetails?.dispatchDate
          ? new Date(payload.transportationDetails.dispatchDate)
          : deliveryChallan.transportationDetails.dispatchDate,
        destinationLocation:
          payload.transportationDetails?.destinationLocation !== undefined
            ? payload.transportationDetails.destinationLocation
            : deliveryChallan.transportationDetails.destinationLocation,
        transportName:
          payload.transportationDetails?.transportName !== undefined
            ? payload.transportationDetails.transportName
            : deliveryChallan.transportationDetails.transportName,
        lrNumber:
          payload.transportationDetails?.lrNumber !== undefined
            ? payload.transportationDetails.lrNumber
            : deliveryChallan.transportationDetails.lrNumber,
      },
      placeOfSupply: payload.placeOfSupply || deliveryChallan.placeOfSupply,
      items: cleanedItems,
      totalQuantity,
      termsAndConditions:
        payload.termsAndConditions || deliveryChallan.termsAndConditions,
      receivedBy: payload.receivedBy
        ? {
            name: payload.receivedBy.name ?? deliveryChallan.receivedBy?.name,
            comment: payload.receivedBy.comment ?? deliveryChallan.receivedBy?.comment,
            date: payload.receivedBy.date
              ? new Date(payload.receivedBy.date)
              : deliveryChallan.receivedBy?.date,
            signatureUrl:
              payload.receivedBy.signatureUrl ?? deliveryChallan.receivedBy?.signatureUrl,
          }
        : deliveryChallan.receivedBy,
      deliveredBy: payload.deliveredBy
        ? {
            name: payload.deliveredBy.name ?? deliveryChallan.deliveredBy?.name,
            comment: payload.deliveredBy.comment ?? deliveryChallan.deliveredBy?.comment,
            date: payload.deliveredBy.date
              ? new Date(payload.deliveredBy.date)
              : deliveryChallan.deliveredBy?.date,
            signatureUrl:
              payload.deliveredBy.signatureUrl ?? deliveryChallan.deliveredBy?.signatureUrl,
          }
        : deliveryChallan.deliveredBy,
      authorizedSignatureUrl:
        payload.authorizedSignatureUrl || deliveryChallan.authorizedSignatureUrl,
      status: payload.status || deliveryChallan.status,
    };

    const updatedChallan = await DeliveryChallan.findByIdAndUpdate(
      req.params.id,
      updatePayload,
      { new: true, runValidators: true }
    );

    return sendSuccess(
      res,
      'Delivery Challan updated successfully.',
      updatedChallan
    );
  } catch (error) {
    return sendError(
      res,
      'Failed to update Delivery Challan.',
      { details: error.message },
      500
    );
  }
};

export const deleteDeliveryChallan = async (req, res) => {
  try {
    const deliveryChallan = await DeliveryChallan.findById(req.params.id);
    if (!deliveryChallan) {
      return sendError(res, 'Delivery Challan not found.', {}, 404);
    }

    await DeliveryChallan.findByIdAndDelete(req.params.id);

    return sendSuccess(res, 'Delivery Challan deleted successfully.', {});
  } catch (error) {
    return sendError(
      res,
      'Failed to delete Delivery Challan.',
      { details: error.message },
      500
    );
  }
};
