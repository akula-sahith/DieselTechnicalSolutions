import mongoose from "mongoose";
import readline from "readline";
import dotenv from "dotenv";

import AppVersion from "../models/appVersion.model.js";

dotenv.config();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

console.log(process.env.MONGO_URI);
console.log(process.env.MONGODB_URI);

const ask = (question) =>
  new Promise((resolve) => rl.question(question, resolve));

const run = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);

    console.log("\n===============================");
    console.log("   DTS RELEASE MANAGER");
    console.log("===============================\n");

    const latestVersion = await ask("Version (e.g. 1.1.0): ");

    const buildNumber = Number(
      await ask("Build Number (e.g. 2): ")
    );

    const apkUrl = await ask("APK URL: ");

    const forceUpdate =
      (
        await ask("Force Update? (y/n): ")
      ).toLowerCase() === "y";

    console.log(
      "\nEnter Release Notes (One per line).\nPress ENTER on an empty line to finish.\n"
    );

    const releaseNotes = [];

    while (true) {
      const note = await ask("> ");

      if (!note.trim()) break;

      releaseNotes.push(note);
    }

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

    console.log("\n===============================");
    console.log("Release Published Successfully");
    console.log("===============================\n");

    console.log(version);

    rl.close();
    process.exit(0);

  } catch (error) {

    console.error("\nRelease Failed\n");

    console.error(error);

    rl.close();

    process.exit(1);

  }
};

run();