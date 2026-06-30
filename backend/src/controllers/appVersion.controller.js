import AppVersion from "../models/appVersion.model.js";
import { sendSuccess, sendError } from "../utils/response.js";

export const getLatestVersion = async (req, res) => {
  try {
    const version = await AppVersion.findOne()
      .sort({ updatedAt: -1 });

    if (!version) {
      return sendError(
        res,
        "Version information not found.",
        {},
        404
      );
    }

    return sendSuccess(
      res,
      "Latest version fetched successfully.",
      version
    );
  } catch (error) {
    return sendError(
      res,
      "Failed to fetch version.",
      {
        details: error.message,
      },
      500
    );
  }
};

export const updateVersion = async (req, res) => {
  try {

    const {
      latestVersion,
      buildNumber,
      apkUrl,
      forceUpdate,
      releaseNotes
    } = req.body;

    let version = await AppVersion.findOne();

    if (!version) {

      version = await AppVersion.create({
        latestVersion,
        buildNumber,
        apkUrl,
        forceUpdate,
        releaseNotes,
      });

    } else {

      version.latestVersion = latestVersion;
      version.buildNumber = buildNumber;
      version.apkUrl = apkUrl;
      version.forceUpdate = forceUpdate;
      version.releaseNotes = releaseNotes;

      await version.save();

    }

    return sendSuccess(
      res,
      "Version updated successfully.",
      version
    );

  } catch (error) {

    return sendError(
      res,
      "Failed to update version.",
      {
        details: error.message,
      },
      500
    );

  }
};