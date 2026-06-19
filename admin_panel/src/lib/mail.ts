import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com',
    // Fallback to a placeholder or direct App Password configuration
    pass: process.env.SMTP_PASS || 'aatz ytec hnol ogie s123', 
  },
});

export async function sendWelcomeEmail(toEmail: string, userName: string, role: string) {
  const isProvider = role.toUpperCase() === 'PROVIDER' || role.toUpperCase() === 'SUPPLIER';
  const dashboardLink = isProvider ? 'http://localhost:3000/provider-home' : 'http://localhost:3000/';

  const subject = `Welcome to BuildConnect, ${userName}!`;
  
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Welcome to BuildConnect</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          background-color: #f8fafc;
          margin: 0;
          padding: 0;
          -webkit-font-smoothing: antialiased;
        }
        .container {
          max-width: 600px;
          margin: 20px auto;
          background-color: #ffffff;
          border-radius: 16px;
          overflow: hidden;
          box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
          border: 1px solid #e2e8f0;
        }
        .header {
          background-color: #064354;
          padding: 32px;
          text-align: center;
        }
        .header h1 {
          color: #ffffff;
          margin: 0;
          font-size: 24px;
          font-weight: 800;
          letter-spacing: -0.5px;
        }
        .content {
          padding: 40px 32px;
        }
        .content p {
          color: #334155;
          font-size: 16px;
          line-height: 1.6;
          margin: 0 0 20px 0;
        }
        .highlight-box {
          background-color: #f1f5f9;
          border-left: 4px solid #f59e0b;
          padding: 16px 20px;
          border-radius: 0 8px 8px 0;
          margin-bottom: 24px;
        }
        .highlight-box p {
          margin: 0;
          font-size: 14px;
          color: #475569;
          font-weight: 500;
        }
        .btn-container {
          text-align: center;
          margin: 32px 0;
        }
        .btn {
          background-color: #f59e0b;
          color: #000000 !important;
          text-decoration: none;
          padding: 14px 32px;
          border-radius: 10px;
          font-weight: 700;
          font-size: 14px;
          display: inline-block;
          box-shadow: 0 4px 6px -1px rgba(245, 158, 11, 0.2);
          transition: all 0.2s ease;
        }
        .footer {
          background-color: #f8fafc;
          padding: 24px 32px;
          text-align: center;
          border-top: 1px solid #e2e8f0;
        }
        .footer p {
          color: #94a3b8;
          font-size: 12px;
          margin: 0;
          line-height: 1.5;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>BuildConnect</h1>
        </div>
        <div class="content">
          <p>Hi ${userName},</p>
          <p>Thank you for joining BuildConnect! Your account has been registered successfully as a <strong>${role}</strong>.</p>
          
          <div class="highlight-box">
            <p>
              ${isProvider 
                ? 'Your registration is currently under review by our admin team. We will verify your credentials and approve your dashboard shortly.' 
                : 'You can now start managing your construction projects, requesting material quotes, and tracking work logs with real-time updates.'}
            </p>
          </div>

          <p>To get started, click the button below to log in and access your workspace:</p>
          
          <div class="btn-container">
            <a href="${dashboardLink}" class="btn">Access Dashboard</a>
          </div>

          <p>If you have any questions or require support, reply directly to this email. We're here to help you build your dream project.</p>
          
          <p>Best regards,<br>The BuildConnect Team</p>
        </div>
        <div class="footer">
          <p>© ${new Date().getFullYear()} BuildConnect. All rights reserved.</p>
          <p style="margin-top: 4px;">Bangalore, Karnataka, India</p>
        </div>
      </div>
    </body>
    </html>
  `;

  try {
    const info = await transporter.sendMail({
      from: `"BuildConnect Notification" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
      to: toEmail,
      subject,
      html: htmlContent,
    });
    console.log(`Welcome email sent to ${toEmail}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error(`Failed to send welcome email to ${toEmail}:`, error);
    return { success: false, error };
  }
}
