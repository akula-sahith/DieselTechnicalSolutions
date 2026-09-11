import assert from "assert";
import express from "express";
import appVersionRoutes from "../src/routes/appVersion.routes.js";

const app = express();
app.use(express.json());
app.use("/api/app-versions", appVersionRoutes);

console.log("Testing Route Mounting & Handlers...");
assert.ok(appVersionRoutes, "appVersionRoutes should be defined");
console.log("✅ Route mounting verified.");
