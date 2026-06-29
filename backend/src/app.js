import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import reportRoutes from './routes/report.routes.js';
import agreementRoutes from './routes/agreement.routes.js';
import cloudinaryRoutes from './routes/cloudinary.routes.js';
import { errorHandler } from './middleware/error.middleware.js';
import { notFoundHandler } from './middleware/notFound.middleware.js';

dotenv.config();

const app = express();

app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

app.get('/health', (req, res) => {
  res.status(200).json({ success: true, message: 'Server is healthy.', data: {} });
});

app.post("/api/ping", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Server is awake!",
    timestamp: new Date()
  });
});

app.use('/api/reports', reportRoutes);
app.use('/api/agreements', agreementRoutes);
app.use('/api/cloudinary', cloudinaryRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
