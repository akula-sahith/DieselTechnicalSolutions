import dotenv from 'dotenv';
import app from './src/app.js';
import connectDB from './src/config/db.js';
import { initReminderScheduler } from './src/services/reminder.service.js';

dotenv.config();

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    await connectDB();
    initReminderScheduler();
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
