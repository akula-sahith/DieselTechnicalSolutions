import cron from 'node-cron';
import Report from '../models/report.model.js';
import Agreement from '../models/agreement.model.js';
import { sendOilServiceReminderEmail, sendAgreementReminderEmail } from './email.service.js';

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
 * Check active Agreements and trigger 30-day / 20-day / 10-day anniversary reminders.
 */
export const checkAgreementReminders = async () => {
  try {
    const agreements = await Agreement.find({ documentType: 'Agreement' });
    const now = new Date();

    for (const agreement of agreements) {
      const agreementDate = agreement.date || agreement.createdAt;
      if (!agreementDate) continue;

      const startTime = new Date(agreementDate).getTime();
      const oneYearMs = 365 * 24 * 60 * 60 * 1000;
      const targetYearTime = startTime + oneYearMs;

      // 30 days before 1 year (335 days from agreement date)
      const thirtyDayTriggerTime = startTime + (335 * 24 * 60 * 60 * 1000);
      // 20 days before 1 year (345 days from agreement date)
      const twentyDayTriggerTime = startTime + (345 * 24 * 60 * 60 * 1000);
      // 10 days before 1 year (355 days from agreement date)
      const tenDayTriggerTime = startTime + (355 * 24 * 60 * 60 * 1000);

      const remindersSent = agreement.emailRemindersSent || { thirtyDay: false, twentyDay: false, tenDay: false };

      // 1. Check 30-day reminder
      if (!remindersSent.thirtyDay && now.getTime() >= thirtyDayTriggerTime && now.getTime() < twentyDayTriggerTime) {
        await sendAgreementReminderEmail(agreement, 30);
        agreement.emailRemindersSent = agreement.emailRemindersSent || {};
        agreement.emailRemindersSent.thirtyDay = true;
        await agreement.save();
      }

      // 2. Check 20-day reminder
      if (!remindersSent.twentyDay && now.getTime() >= twentyDayTriggerTime && now.getTime() < tenDayTriggerTime) {
        await sendAgreementReminderEmail(agreement, 20);
        agreement.emailRemindersSent = agreement.emailRemindersSent || {};
        agreement.emailRemindersSent.twentyDay = true;
        await agreement.save();
      }

      // 3. Check 10-day reminder
      if (!remindersSent.tenDay && now.getTime() >= tenDayTriggerTime && now.getTime() <= (targetYearTime + (30 * 24 * 60 * 60 * 1000))) {
        await sendAgreementReminderEmail(agreement, 10);
        agreement.emailRemindersSent = agreement.emailRemindersSent || {};
        agreement.emailRemindersSent.tenDay = true;
        await agreement.save();
      }
    }
  } catch (error) {
    console.error('[Reminder Cron Error] Error running Agreement reminder check:', error.message);
  }
};

/**
 * Start scheduled cron task. Runs daily at 09:00 AM.
 * Also runs an initial check upon server startup.
 */
export const initReminderScheduler = () => {
  // Run on startup
  checkOilServiceReminders();
  checkAgreementReminders();

  // Schedule daily cron at 09:00 AM
  cron.schedule('0 9 * * *', () => {
    console.log('[Reminder Cron] Running daily Oil Service & Agreement reminder scans...');
    checkOilServiceReminders();
    checkAgreementReminders();
  });
};
