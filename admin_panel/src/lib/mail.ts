import nodemailer from 'nodemailer';
import prisma from '@/lib/prisma';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com',
    pass: process.env.SMTP_PASS || 'aatz ytec hnol ogie s123', 
  },
});

const getBaseTemplate = (title: string, bodyContent: string) => `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
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
      .detail-table {
        width: 100%;
        border-collapse: collapse;
        margin: 24px 0;
      }
      .detail-table th, .detail-table td {
        padding: 12px 16px;
        text-align: left;
        border-bottom: 1px solid #e2e8f0;
      }
      .detail-table th {
        background-color: #f8fafc;
        color: #475569;
        font-weight: 700;
        width: 35%;
        font-size: 14px;
      }
      .detail-table td {
        color: #0f172a;
        font-size: 14px;
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
        ${bodyContent}
      </div>
      <div class="footer">
        <p>© ${new Date().getFullYear()} BuildConnect. All rights reserved.</p>
        <p style="margin-top: 4px;">Bangalore, Karnataka, India</p>
      </div>
    </div>
  </body>
  </html>
`;

export async function sendWelcomeEmail(toEmail: string, userName: string, role: string) {
  const isProvider = role.toUpperCase() === 'PROVIDER' || role.toUpperCase() === 'SUPPLIER';
  const dashboardLink = isProvider ? 'http://localhost:3000/provider-home' : 'http://localhost:3000/';

  const subject = `Welcome to BuildConnect, ${userName}!`;
  const bodyContent = `
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
  `;

  try {
    const info = await transporter.sendMail({
      from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
      to: toEmail,
      subject,
      html: getBaseTemplate(subject, bodyContent),
    });
    console.log(`Welcome email sent to ${toEmail}: ${info.messageId}`);
    return { success: true };
  } catch (error) {
    console.error(`Failed to send welcome email to ${toEmail}:`, error);
    return { success: false, error };
  }
}

export async function sendProviderWelcomeEmail(provider: any) {
  const subject = `BuildConnect Registration Received: ${provider.businessName}`;
  const bodyContent = `
    <p>Hi ${provider.ownerName || 'Provider'},</p>
    <p>Thank you for registering your business with BuildConnect! Below are the registration details we received:</p>
    
    <table class="detail-table">
      <tr>
        <th>Business Name</th>
        <td>${provider.businessName}</td>
      </tr>
      <tr>
        <th>Owner Name</th>
        <td>${provider.ownerName || 'N/A'}</td>
      </tr>
      <tr>
        <th>Email Address</th>
        <td>${provider.email}</td>
      </tr>
      <tr>
        <th>Phone Number</th>
        <td>${provider.phone}</td>
      </tr>
      <tr>
        <th>Category</th>
        <td>${provider.category}</td>
      </tr>
      <tr>
        <th>Experience</th>
        <td>${provider.experience} Years</td>
      </tr>
      <tr>
        <th>Office Address</th>
        <td>${provider.address || 'N/A'}</td>
      </tr>
      <tr>
        <th>Business Bio</th>
        <td>${provider.bio || 'N/A'}</td>
      </tr>
    </table>

    <div class="highlight-box">
      <p><strong>Review Process:</strong> Our administrator review team is currently inspecting your license details and profile details. You will receive an approval email notification once your seller account is verified.</p>
    </div>

    <p>If any of the details above are incorrect, please contact us immediately.</p>
    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  try {
    await transporter.sendMail({
      from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
      to: provider.email,
      subject,
      html: getBaseTemplate(subject, bodyContent),
    });
    console.log(`Detailed Provider Welcome email sent to ${provider.email}`);
  } catch (error) {
    console.error(`Failed to send provider welcome email:`, error);
  }
}

export async function sendApprovalEmail(toEmail: string, name: string, role: string) {
  const isProvider = role.toUpperCase() === 'PROVIDER' || role.toUpperCase() === 'SUPPLIER';
  const dashboardLink = isProvider ? 'http://localhost:3000/provider-home' : 'http://localhost:3000/';

  const subject = `Your BuildConnect Account Has Been Approved! 🎉`;
  const bodyContent = `
    <p>Hi ${name},</p>
    <p>Great news! Your account has been reviewed and approved by the BuildConnect administrators.</p>
    
    <div class="highlight-box">
      <p>
        ${isProvider 
          ? 'Your profile is now verified and active in our Provider Directory. You will now receive project leads and inquiry bidding requests from clients.' 
          : 'Your account is active. You can now build, track, and manage your construction projects.'}
      </p>
    </div>

    <p>Click below to log in and access all verified features:</p>
    
    <div class="btn-container">
      <a href="${dashboardLink}" class="btn">Log In Now</a>
    </div>

    <p>Happy building!</p>
    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  try {
    await transporter.sendMail({
      from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
      to: toEmail,
      subject,
      html: getBaseTemplate(subject, bodyContent),
    });
    console.log(`Approval email sent to ${toEmail}`);
  } catch (error) {
    console.error(`Failed to send approval email to ${toEmail}:`, error);
  }
}

// -------------------------------------------------------------
// Action Email: New Material Inquiry
// -------------------------------------------------------------
export async function sendInquiryNotification(inquiry: any, buyer: any, provider: any) {
  // 1. Send to Buyer (User)
  const buyerSubject = `Material Inquiry Sent: ${inquiry.title}`;
  const buyerBody = `
    <p>Hi ${buyer.name},</p>
    <p>Your inquiry for materials has been sent to <strong>${provider.businessName}</strong>.</p>
    
    <table class="detail-table">
      <tr>
        <th>Material Inquiry</th>
        <td>${inquiry.title}</td>
      </tr>
      <tr>
        <th>Quantity</th>
        <td>${inquiry.quantity} ${inquiry.unit}</td>
      </tr>
      <tr>
        <th>Delivery Site</th>
        <td>${inquiry.location}</td>
      </tr>
      <tr>
        <th>Details</th>
        <td>${inquiry.description}</td>
      </tr>
    </table>

    <p>The seller will review your request and send a quote shortly. You will be notified as soon as a quote is proposed.</p>
    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  // 2. Send to Seller (Provider)
  const sellerSubject = `🚨 New Inquiry Received: ${inquiry.title}`;
  const sellerBody = `
    <p>Hi ${provider.ownerName || 'Provider'},</p>
    <p>You have received a new material inquiry from client <strong>${buyer.name}</strong>.</p>
    
    <table class="detail-table">
      <tr>
        <th>Inquiry Title</th>
        <td>${inquiry.title}</td>
      </tr>
      <tr>
        <th>Quantity Needed</th>
        <td>${inquiry.quantity} ${inquiry.unit}</td>
      </tr>
      <tr>
        <th>Delivery Location</th>
        <td>${inquiry.location}</td>
      </tr>
      <tr>
        <th>Client Notes</th>
        <td>${inquiry.description}</td>
      </tr>
    </table>

    <div class="highlight-box">
      <p>Please log in to your provider dashboard to review the lead details and send your material quotation bid.</p>
    </div>

    <div class="btn-container">
      <a href="http://localhost:3000/provider-home" class="btn">View Lead Details</a>
    </div>

    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  try {
    await Promise.all([
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: buyer.email,
        subject: buyerSubject,
        html: getBaseTemplate(buyerSubject, buyerBody),
      }),
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: provider.email,
        subject: sellerSubject,
        html: getBaseTemplate(sellerSubject, sellerBody),
      })
    ]);
    console.log(`Inquiry notifications sent successfully to ${buyer.email} and ${provider.email}`);
  } catch (error) {
    console.error('Failed to send inquiry notification emails:', error);
  }
}

// -------------------------------------------------------------
// Action Email: Quote Proposed by Seller
// -------------------------------------------------------------
export async function sendQuoteNotification(quote: any, project: any, buyer: any, provider: any) {
  // 1. Send to Buyer (User)
  const buyerSubject = `New Project Quote Proposed by ${provider.businessName}`;
  const buyerBody = `
    <p>Hi ${buyer.name},</p>
    <p>You have received a new price quotation estimate from <strong>${provider.businessName}</strong> for your project <strong>${project.title}</strong>.</p>
    
    <table class="detail-table">
      <tr>
        <th>Project Name</th>
        <td>${project.title}</td>
      </tr>
      <tr>
        <th>Proposed Quote</th>
        <td style="color: #059669; font-weight: 700;">₹${quote.estimatedCost.toLocaleString()}</td>
      </tr>
      <tr>
        <th>Timeline</th>
        <td>${quote.timeline}</td>
      </tr>
      <tr>
        <th>Seller Notes</th>
        <td>${quote.notes || 'No extra notes provided.'}</td>
      </tr>
    </table>

    <div class="highlight-box">
      <p>Open the app to compare this quote side-by-side with other bids and accept or negotiate the offer.</p>
    </div>

    <div class="btn-container">
      <a href="http://localhost:3000/" class="btn">Compare & Accept Quote</a>
    </div>

    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  // 2. Send to Seller (Provider)
  const sellerSubject = `Quote Proposed Successfully: ${project.title}`;
  const sellerBody = `
    <p>Hi ${provider.ownerName || 'Provider'},</p>
    <p>Your quotation for project <strong>${project.title}</strong> has been submitted successfully to <strong>${buyer.name}</strong>.</p>
    
    <table class="detail-table">
      <tr>
        <th>Project Name</th>
        <td>${project.title}</td>
      </tr>
      <tr>
        <th>Your Bid Cost</th>
        <td>₹${quote.estimatedCost.toLocaleString()}</td>
      </tr>
      <tr>
        <th>Est. Duration</th>
        <td>${quote.timeline}</td>
      </tr>
    </table>

    <p>We will notify you immediately once the client reviews and accepts your proposal.</p>
    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  try {
    await Promise.all([
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: buyer.email,
        subject: buyerSubject,
        html: getBaseTemplate(buyerSubject, buyerBody),
      }),
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: provider.email,
        subject: sellerSubject,
        html: getBaseTemplate(sellerSubject, sellerBody),
      })
    ]);
    console.log(`Quote proposal notifications sent to ${buyer.email} and ${provider.email}`);
  } catch (error) {
    console.error('Failed to send quote notification emails:', error);
  }
}

// -------------------------------------------------------------
// Action Email: Quote Accepted by Buyer
// -------------------------------------------------------------
export async function sendQuoteAcceptedNotification(quote: any, project: any, buyer: any, provider: any) {
  // 1. Send to Buyer (User)
  const buyerSubject = `Quote Accepted: Project ${project.title}`;
  const buyerBody = `
    <p>Hi ${buyer.name},</p>
    <p>You have accepted the quotation from <strong>${provider.businessName}</strong> for <strong>${project.title}</strong>.</p>
    
    <table class="detail-table">
      <tr>
        <th>Project Name</th>
        <td>${project.title}</td>
      </tr>
      <tr>
        <th>Accepted Budget</th>
        <td style="color: #059669; font-weight: 700;">₹${quote.estimatedCost.toLocaleString()}</td>
      </tr>
      <tr>
        <th>Timeline</th>
        <td>${quote.timeline}</td>
      </tr>
    </table>

    <div class="highlight-box">
      <p>The builder has been notified. The project stage-wise Gantt tasks will now unlock. You can track progress and releases live from the home dashboard.</p>
    </div>

    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  // 2. Send to Seller (Provider)
  const sellerSubject = `🎉 Quote Accepted! Project: ${project.title}`;
  const sellerBody = `
    <p>Hi ${provider.ownerName || 'Provider'},</p>
    <p>Excellent news! The client <strong>${buyer.name}</strong> has accepted your quote for project <strong>${project.title}</strong>.</p>
    
    <table class="detail-table">
      <tr>
        <th>Project Name</th>
        <td>${project.title}</td>
      </tr>
      <tr>
        <th>Final Budget</th>
        <td style="color: #059669; font-weight: 700;">₹${quote.estimatedCost.toLocaleString()}</td>
      </tr>
      <tr>
        <th>Target Timeline</th>
        <td>${quote.timeline}</td>
      </tr>
    </table>

    <div class="highlight-box">
      <p>This project is now active. Please log in to your provider dashboard to update work logs, input manpower logs, and submit visual completion proofs.</p>
    </div>

    <div class="btn-container">
      <a href="http://localhost:3000/provider-home" class="btn">Go to Active Project</a>
    </div>

    <p>Best regards,<br>The BuildConnect Team</p>
  `;

  try {
    await Promise.all([
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: buyer.email,
        subject: buyerSubject,
        html: getBaseTemplate(buyerSubject, buyerBody),
      }),
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: provider.email,
        subject: sellerSubject,
        html: getBaseTemplate(sellerSubject, sellerBody),
      })
    ]);
    console.log(`Quote acceptance notifications sent to ${buyer.email} and ${provider.email}`);
  } catch (error) {
    console.error('Failed to send quote acceptance emails:', error);
  }
}

// -------------------------------------------------------------
// Action Email: Generic Inquiry Status Change Notification
// -------------------------------------------------------------
export async function notifyInquiryStatusChange(inquiryId: string) {
  try {
    const inquiry = await prisma.inquiry.findUnique({
      where: { id: inquiryId },
      include: {
        buyer: true,
        provider: true,
      },
    });

    if (!inquiry) return;

    const { buyer, provider, status, title, quantity, unit, location, quotedPrice } = inquiry;

    let buyerSubject = `BuildConnect: Status Update on your Inquiry "${title}"`;
    let buyerBody = `
      <p>Hi ${buyer.name},</p>
      <p>The status of your material inquiry <strong>${title}</strong> has been updated to <strong>${status}</strong> by the seller.</p>
    `;

    let sellerSubject = `BuildConnect: Inquiry Status Synced for "${title}"`;
    let sellerBody = `
      <p>Hi ${provider.ownerName || 'Provider'},</p>
      <p>Your inquiry status change to <strong>${status}</strong> for <strong>${title}</strong> has been recorded.</p>
    `;

    // Customize template based on specific status values
    if (status === 'Quote Sent' || (status === 'Viewed' && quotedPrice)) {
      buyerSubject = `New Material Quote Received from ${provider.businessName}!`;
      buyerBody = `
        <p>Hi ${buyer.name},</p>
        <p>Great news! <strong>${provider.businessName}</strong> has proposed a quotation for your inquiry <strong>${title}</strong>.</p>
        <table class="detail-table">
          <tr>
            <th>Material</th>
            <td>${title}</td>
          </tr>
          <tr>
            <th>Quantity</th>
            <td>${quantity} ${unit}</td>
          </tr>
          <tr>
            <th>Quoted Price</th>
            <td style="color: #059669; font-weight: 700;">₹${quotedPrice?.toLocaleString() || 'N/A'}</td>
          </tr>
          <tr>
            <th>Location</th>
            <td>${location}</td>
          </tr>
        </table>
        <p>Log in to your account on the mobile app or web app to review and accept the quotation.</p>
      `;
    } else if (status === 'Accepted') {
      buyerSubject = `Inquiry Accepted: ${title}`;
      buyerBody = `
        <p>Hi ${buyer.name},</p>
        <p>You have accepted the quotation from <strong>${provider.businessName}</strong> for <strong>${title}</strong>.</p>
      `;

      sellerSubject = `🎉 Lead Accepted! Material: ${title}`;
      sellerBody = `
        <p>Hi ${provider.ownerName || 'Provider'},</p>
        <p>Excellent news! The client <strong>${buyer.name}</strong> has accepted your quotation for <strong>${title}</strong>.</p>
        <table class="detail-table">
          <tr>
            <th>Material</th>
            <td>${title}</td>
          </tr>
          <tr>
            <th>Agreed Price</th>
            <td style="color: #059669; font-weight: 700;">₹${quotedPrice?.toLocaleString() || 'N/A'}</td>
          </tr>
          <tr>
            <th>Client Location</th>
            <td>${location}</td>
          </tr>
        </table>
      `;
    }

    // Send both emails in parallel
    await Promise.all([
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: buyer.email,
        subject: buyerSubject,
        html: getBaseTemplate(buyerSubject, buyerBody),
      }),
      transporter.sendMail({
        from: `"BuildConnect" <${process.env.SMTP_USER || 'notification.aatzytechnologies@gmail.com'}>`,
        to: provider.email,
        subject: sellerSubject,
        html: getBaseTemplate(sellerSubject, sellerBody),
      })
    ]);
    console.log(`Status change emails sent for inquiry ${inquiryId} with status ${status}`);
  } catch (error) {
    console.error('Failed to notify inquiry status change:', error);
  }
}
