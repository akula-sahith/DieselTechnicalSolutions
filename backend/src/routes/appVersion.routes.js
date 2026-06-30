import express from "express";

import {
  getLatestVersion,
  updateVersion,
} from "../controllers/appVersion.controller.js";

const router = express.Router();

router.get("/", getLatestVersion);

router.put("/", updateVersion);

export default router;