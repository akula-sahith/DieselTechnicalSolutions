import { Resend } from 'resend';

const recipientEmails = [
  'akulasahith268@gmail.com',
  '238w1a1215@vrsec.ac.in',
  'dieseltechnicalsolutions@zohomail.in',
];
const apiKey = process.env.RESEND_API_KEY || '';

let resendClient = null;
if (apiKey) {
  resendClient = new Resend(apiKey);
}

/**
 * Send an email notification when a new Service Report is created.
 */
export const sendServiceReportCreatedEmail = async (report) => {
  const { jobRef, customerName, siteLocation, contactPerson, contactNumber, dateTime } = report.serviceAndCustomer || {};
  const reportType = report.reportType || 'General Visit';
  const technicianName = report.authorization?.technicianName || report.createdBy?.name || 'Technician';
  const formattedDate = dateTime ? new Date(dateTime).toLocaleString() : new Date().toLocaleString();

  const htmlContent = `
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333; line-height: 1.6;">
      <h2 style="color: #0B2545; border-bottom: 2px solid #0B2545; padding-bottom: 8px;">
        New Service Report Created (${reportType})
      </h2>
      <p>A new electronic Field Service Report (eFSR) has been successfully recorded in the database.</p>
      
      <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
        <tr style="background-color: #F1F5F9;">
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Job / Ticket Ref</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;"><strong>${jobRef || 'N/A'}</strong></td>
        </tr>
        <tr>
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Report Type</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1; color: #2563EB;"><strong>${reportType}</strong></td>
        </tr>
        <tr style="background-color: #F1F5F9;">
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Customer Name</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${customerName || 'N/A'}</td>
        </tr>
        <tr>
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Site Location</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${siteLocation || 'N/A'}</td>
        </tr>
        <tr style="background-color: #F1F5F9;">
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Contact Person & Phone</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${contactPerson || 'N/A'} (${contactNumber || 'N/A'})</td>
        </tr>
        <tr>
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Technician Name</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${technicianName}</td>
        </tr>
        <tr style="background-color: #F1F5F9;">
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Date & Time</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${formattedDate}</td>
        </tr>
      </table>

      <br/>
      <p style="font-size: 12px; color: #64748B;">This is an automated notification from Diesel Technical Solutions ERP.</p>
    </div>
  `;

  try {
    if (resendClient) {
      await resendClient.emails.send({
        from: 'Diesel Technical Solutions <onboarding@resend.dev>',
        to: recipientEmails,
        subject: `[eFSR Created] ${jobRef || 'Report'} - ${reportType} (${customerName || 'Customer'})`,
        html: htmlContent,
      });
      console.log(`[Resend Email] Service report creation email sent to ${recipientEmails.join(', ')} for ${jobRef}`);
    } else {
      console.log(`[Resend Email Simulation] (No RESEND_API_KEY set) Email would be sent to ${recipientEmails.join(', ')} for jobRef ${jobRef}`);
    }
  } catch (error) {
    console.error(`[Resend Email Error] Failed to send creation email for ${jobRef}:`, error.message);
  }
};

/**
 * Send scheduled reminder email for Oil Service due date.
 */
export const sendOilServiceReminderEmail = async (report, daysRemaining) => {
  const { jobRef, customerName, siteLocation, contactPerson, contactNumber } = report.serviceAndCustomer || {};
  const creationDate = report.createdAt ? new Date(report.createdAt).toLocaleDateString() : 'N/A';

  const subject = `[OIL SERVICE REMINDER] ${daysRemaining} Days Remaining for ${customerName || jobRef}`;

  const htmlContent = `
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333; line-height: 1.6;">
      <h2 style="color: #D97706; border-bottom: 2px solid #D97706; padding-bottom: 8px;">
        Oil Service Renewal Reminder (${daysRemaining} Days Remaining)
      </h2>
      <p>This is an automated maintenance alert for an existing <strong>Oil Service</strong> report created on ${creationDate}.</p>
      
      <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
        <tr style="background-color: #FEF3C7;">
          <th style="padding: 10px; border: 1px solid #FCD34D; text-align: left;">Customer Name</th>
          <td style="padding: 10px; border: 1px solid #FCD34D;"><strong>${customerName || 'N/A'}</strong></td>
        </tr>
        <tr>
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Job / Ticket Ref</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${jobRef || 'N/A'}</td>
        </tr>
        <tr style="background-color: #F1F5F9;">
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Site Location</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${siteLocation || 'N/A'}</td>
        </tr>
        <tr>
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Contact Details</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1;">${contactPerson || 'N/A'} (${contactNumber || 'N/A'})</td>
        </tr>
        <tr style="background-color: #F1F5F9;">
          <th style="padding: 10px; border: 1px solid #CBD5E1; text-align: left;">Status</th>
          <td style="padding: 10px; border: 1px solid #CBD5E1; color: #D97706;"><strong>Annual Oil Service Due in ${daysRemaining} Days</strong></td>
        </tr>
      </table>

      <br/>
      <p style="font-size: 12px; color: #64748B;">Please contact the customer to schedule the upcoming annual oil service.</p>
    </div>
  `;

  try {
    if (resendClient) {
      await resendClient.emails.send({
        from: 'Diesel Technical Solutions <onboarding@resend.dev>',
        to: recipientEmails,
        subject,
        html: htmlContent,
      });
      console.log(`[Resend Reminder] ${daysRemaining}-day Oil Service reminder sent to ${recipientEmails.join(', ')} for ${jobRef}`);
    } else {
      console.log(`[Resend Reminder Simulation] (No RESEND_API_KEY set) ${daysRemaining}-day reminder sent to ${recipientEmails.join(', ')} for ${jobRef}`);
    }
  } catch (error) {
    console.error(`[Resend Reminder Error] Failed to send ${daysRemaining}-day reminder for ${jobRef}:`, error.message);
  }
};
