import mongoose from 'mongoose';

const appVersionSchema = new mongoose.Schema(
  {
    latestVersion: {
      type: String,
      required: true,
      trim: true,
    },

    buildNumber: {
      type: Number,
      required: true,
      default: 1,
    },

    apkUrl: {
      type: String,
      required: true,
      trim: true,
    },

    forceUpdate: {
      type: Boolean,
      default: false,
    },

    releaseNotes: {
      type: [String],
      default: [],
    },

    // Windows Desktop platform metadata
    windowsVersion: {
      type: String,
      trim: true,
      default: null,
    },

    windowsBuildNumber: {
      type: Number,
      default: null,
    },

    windowsDownloadUrl: {
      type: String,
      trim: true,
      default: null,
    },

    windowsForceUpdate: {
      type: Boolean,
      default: false,
    },

    windowsReleaseNotes: {
      type: [String],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

const AppVersion = mongoose.model("AppVersion", appVersionSchema);

export default AppVersion;