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

    const windowsUrl = version.windowsDownloadUrl || process.env.WINDOWS_DOWNLOAD_URL || null;

    const responsePayload = {
      // Legacy top-level fields for backwards compatibility with released Android apps
      latestVersion: version.latestVersion,
      buildNumber: version.buildNumber,
      apkUrl: version.apkUrl,
      forceUpdate: version.forceUpdate ?? false,
      releaseNotes: version.releaseNotes || [],

      // Platform-specific version metadata
      android: {
        version: version.latestVersion,
        buildNumber: version.buildNumber,
        downloadUrl: version.apkUrl,
        forceUpdate: version.forceUpdate ?? false,
        releaseNotes: version.releaseNotes || [],
      },

      windows: {
        version: version.windowsVersion || version.latestVersion,
        buildNumber: version.windowsBuildNumber || version.buildNumber,
        downloadUrl: windowsUrl,
        forceUpdate: version.windowsForceUpdate ?? false,
        releaseNotes: (version.windowsReleaseNotes && version.windowsReleaseNotes.length > 0)
          ? version.windowsReleaseNotes
          : (version.releaseNotes || []),
      },
    };

    return sendSuccess(
      res,
      "Latest version fetched successfully.",
      responsePayload
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
      releaseNotes,
      windowsVersion,
      windowsBuildNumber,
      windowsDownloadUrl,
      windowsForceUpdate,
      windowsReleaseNotes,
    } = req.body;

    let version = await AppVersion.findOne();

    const updateFields = {
      latestVersion,
      buildNumber,
      apkUrl,
      forceUpdate,
      releaseNotes,
      ...(windowsVersion !== undefined && { windowsVersion }),
      ...(windowsBuildNumber !== undefined && { windowsBuildNumber }),
      ...(windowsDownloadUrl !== undefined && { windowsDownloadUrl }),
      ...(windowsForceUpdate !== undefined && { windowsForceUpdate }),
      ...(windowsReleaseNotes !== undefined && { windowsReleaseNotes }),
    };

    if (!version) {
      version = await AppVersion.create(updateFields);
    } else {
      Object.assign(version, updateFields);
      await version.save();
    }

    const windowsUrl = version.windowsDownloadUrl || process.env.WINDOWS_DOWNLOAD_URL || null;

    const responsePayload = {
      latestVersion: version.latestVersion,
      buildNumber: version.buildNumber,
      apkUrl: version.apkUrl,
      forceUpdate: version.forceUpdate ?? false,
      releaseNotes: version.releaseNotes || [],

      android: {
        version: version.latestVersion,
        buildNumber: version.buildNumber,
        downloadUrl: version.apkUrl,
        forceUpdate: version.forceUpdate ?? false,
        releaseNotes: version.releaseNotes || [],
      },

      windows: {
        version: version.windowsVersion || version.latestVersion,
        buildNumber: version.windowsBuildNumber || version.buildNumber,
        downloadUrl: windowsUrl,
        forceUpdate: version.windowsForceUpdate ?? false,
        releaseNotes: (version.windowsReleaseNotes && version.windowsReleaseNotes.length > 0)
          ? version.windowsReleaseNotes
          : (version.releaseNotes || []),
      },
    };

    return sendSuccess(
      res,
      "Version updated successfully.",
      responsePayload
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