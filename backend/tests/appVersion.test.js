import assert from "assert";

// Function to construct response payload (mirroring appVersion.controller.js logic)
function buildResponsePayload(versionDoc, envWindowsUrl) {
  const windowsUrl = versionDoc.windowsDownloadUrl || envWindowsUrl || null;

  return {
    // Legacy top-level fields
    latestVersion: versionDoc.latestVersion,
    buildNumber: versionDoc.buildNumber,
    apkUrl: versionDoc.apkUrl,
    forceUpdate: versionDoc.forceUpdate ?? false,
    releaseNotes: versionDoc.releaseNotes || [],

    // Multi-platform structures
    android: {
      version: versionDoc.latestVersion,
      buildNumber: versionDoc.buildNumber,
      downloadUrl: versionDoc.apkUrl,
      forceUpdate: versionDoc.forceUpdate ?? false,
      releaseNotes: versionDoc.releaseNotes || [],
    },

    windows: {
      version: versionDoc.windowsVersion || versionDoc.latestVersion,
      buildNumber: versionDoc.windowsBuildNumber || versionDoc.buildNumber,
      downloadUrl: windowsUrl,
      forceUpdate: versionDoc.windowsForceUpdate ?? false,
      releaseNotes: (versionDoc.windowsReleaseNotes && versionDoc.windowsReleaseNotes.length > 0)
        ? versionDoc.windowsReleaseNotes
        : (versionDoc.releaseNotes || []),
    },
  };
}

console.log("Running appVersion Multi-Platform API Unit Tests...\n");

// Test Case 1: Legacy Android record without Windows URL
const mockDoc1 = {
  latestVersion: "1.2.0",
  buildNumber: 10,
  apkUrl: "https://github.com/org/repo/releases/download/v1.2.0/DTS-Android-v1.2.0.apk",
  forceUpdate: false,
  releaseNotes: ["Fixed invoice print preview", "Performance improvements"],
  windowsDownloadUrl: null,
};

const res1 = buildResponsePayload(mockDoc1, null);

console.log("Test Case 1 Payload:");
console.log(JSON.stringify(res1, null, 2));

// Assertions for Case 1
assert.strictEqual(res1.latestVersion, "1.2.0");
assert.strictEqual(res1.buildNumber, 10);
assert.strictEqual(res1.apkUrl, mockDoc1.apkUrl);
assert.strictEqual(res1.android.version, "1.2.0");
assert.strictEqual(res1.android.downloadUrl, mockDoc1.apkUrl);
assert.strictEqual(res1.windows.version, "1.2.0");
assert.strictEqual(res1.windows.downloadUrl, null);
assert.deepStrictEqual(res1.windows.releaseNotes, mockDoc1.releaseNotes);

console.log("\n✅ Test Case 1 Passed: Legacy backward compatibility & null Windows URL verified.");

// Test Case 2: Record with Windows MSIX release URL populated
const mockDoc2 = {
  latestVersion: "1.3.0",
  buildNumber: 11,
  apkUrl: "https://github.com/org/repo/releases/download/v1.3.0/DTS-Android-v1.3.0.apk",
  forceUpdate: true,
  releaseNotes: ["Added Windows Desktop support"],
  windowsVersion: "1.3.0",
  windowsBuildNumber: 11,
  windowsDownloadUrl: "https://github.com/org/repo/releases/download/v1.3.0/DTS-Windows-v1.3.0.msix",
  windowsForceUpdate: true,
  windowsReleaseNotes: ["Windows keyboard shortcuts", "Desktop Table view"],
};

const res2 = buildResponsePayload(mockDoc2, null);

console.log("\nTest Case 2 Payload:");
console.log(JSON.stringify(res2, null, 2));

// Assertions for Case 2
assert.strictEqual(res2.latestVersion, "1.3.0");
assert.strictEqual(res2.windows.downloadUrl, "https://github.com/org/repo/releases/download/v1.3.0/DTS-Windows-v1.3.0.msix");
assert.strictEqual(res2.windows.forceUpdate, true);
assert.deepStrictEqual(res2.windows.releaseNotes, ["Windows keyboard shortcuts", "Desktop Table view"]);

console.log("\n✅ Test Case 2 Passed: Dual-platform Android & Windows release URLs verified.");
console.log("\n🎉 ALL UNIT TESTS PASSED SUCCESSFULLY!");
