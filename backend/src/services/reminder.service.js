import cron from 'node-cron';
import Report from '../models/report.model.js';
import { sendOilServiceReminderEmail } from './email.service.js';

/**
 * Check active Oil Service reports and trigger 20-day / 10-day reminders.
 */
export const checkOilServiceReminders = async () => {
  try {
    const oilReports = await Report.find({ reportType: 'Oil Service' });
    const now = new Date();

    for (const report of oilReports) {
      const createdAt = report.createdAt || report.serviceAndCustomer?.dateTime;
      if (!createdAt) continue;

      const createdTime = new Date(createdAt).getTime();
      const oneYearMs = 365 * 24 * 60 * 60 * 1000;
      const targetYearTime = createdTime + oneYearMs;

      // 20 days before 1 year (345 days from creation)
      const twentyDayTriggerTime = createdTime + (345 * 24 * 60 * 60 * 1000);
      // 10 days before 1 year (355 days from creation)
      const tenDayTriggerTime = createdTime + (355 * 24 * 60 * 60 * 1000);

      const remindersSent = report.emailRemindersSent || { twentyDay: false, tenDay: false };

      // 1. Check 20-day reminder
      if (!remindersSent.twentyDay && now.getTime() >= twentyDayTriggerTime && now.getTime() < tenDayTriggerTime) {
        await sendOilServiceReminderEmail(report, 20);
        report.emailRemindersSent.twentyDay = true;
        await report.save();
      }

      // 2. Check 10-day reminder
      if (!remindersSent.tenDay && now.getTime() >= tenDayTriggerTime && now.getTime() <= (targetYearTime + (30 * 24 * 60 * 60 * 1000))) {
        await sendOilServiceReminderEmail(report, 10);
        report.emailRemindersSent.tenDay = true;
        await report.save();
      }
    }
  } catch (error) {
    console.error('[Reminder Cron Error] Error running Oil Service reminder check:', error.message);
  }
};

/**
 * Start scheduled cron task. Runs daily at 09:00 AM.
 * Also runs an initial check upon server startup.
 */
export const initReminderScheduler = () => {
  // Run on startup
  checkOilServiceReminders();

  // Schedule daily cron at 09:00 AM
  cron.schedule('0 9 * * *', () => {
    console.log('[Reminder Cron] Running daily Oil Service reminder scan...');
    checkOilServiceReminders();
  });
};
