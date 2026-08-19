# Project Quotation & Cost Breakdown
## Aatzy Construction App

---

### **Executive Summary**
This document outlines the commercial quotation and operational costs for launching and maintaining the **Aatzy Construction App**. 

The solution consists of:
1. **Flutter Mobile Application** (for Clients and Service Providers/B2B Vendors)
2. **Next.js Web Admin Panel** (for administrators to manage users, projects, and inquiries)
3. **Node.js/Next.js API & Prisma Backend Engine**
4. **PostgreSQL Database**

---

### **1. Core Software Development (One-Time)**
This is the fixed cost for the design, development, and integration of the application modules.

| Component / Feature Module | Description | Cost (INR) |
| :--- | :--- | :--- |
| **Mobile Client App (Flutter)** | Multi-platform client app with modules: User Auth, Home/Dashboard, Project Creation, Detailed Cost Estimation Screen, B2B Service Listings, Compare Quotes, and Real-time Chat. | Included |
| **Admin Panel & Web Portal** | Next.js portal for viewing statistics, managing consumer/vendor databases, approving users, reviewing projects, and auditing system logs. | Included |
| **Backend API & Database Setup** | Secure Next.js API Routes, JWT Auth, Database schema definition via Prisma, and ORM configurations. | Included |
| **Development Cost (Fixed)** | **Fixed package cost for implementation and delivery** | **₹40,000** |

---

### **2. Go-Live & Initial Setup (First-Time Pay)**
These are the initial, one-time fees required to publish your applications on the respective stores and set up the cloud production environment.

| Expense Item | Provider | Billing Frequency | Estimated Cost (INR) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Google Play Console License** | Google | One-time | ~₹2,100 ($25 USD) | Required to publish the Android App on the Google Play Store. |
| **Apple Developer Account** *(Optional)* | Apple | Annual | ~₹8,200 ($99 USD) | Required if you wish to publish the iOS version to the Apple App Store. |
| **Domain Registration** | Namecheap / GoDaddy | Annual | ~₹800 - ₹1,200 | Custom domain for your admin panel and API backend (e.g., `admin.aatzy.com`). |
| **Server & Database Initial Setup** | Cloud DevOps | One-time | **₹3,000** | Initial server configuration, SSL certificate generation, and database provisioning. |
| **Total Go-Live Setup (Android Only)** | | **One-time** | **~₹6,000** | Includes Google Play Console, Domain, and Server Setup. |
| **Total Go-Live Setup (Android + iOS)** | | **One-time** | **~₹14,200** | Includes Google, Apple developer, Domain, and Server Setup. |

---

### **3. Estimated App Running Expenses (Monthly Infrastructure Costs)**
These fees go directly to cloud providers to keep the servers, database, and APIs running. *Note: Hosting providers bill on actual usage. Estimates below are based on initial user load (up to 5,000 active users).*

| Expense Item | Recommended Service | Monthly Cost (USD) | Estimated Cost (INR) | Details |
| :--- | :--- | :--- | :--- | :--- |
| **Next.js Web & API Server** | Vercel (Pro) or Render VPS | $20.00 / month | ~₹1,650 / month | Hosts the backend API routes and the Web Admin Panel. |
| **Managed PostgreSQL Database** | Neon DB / Supabase | $15.00 / month | ~₹1,250 / month | Production-grade database hosting with regular backups. |
| **Asset & Image Cloud Storage** | Cloudinary / AWS S3 | $5.00 / month | ~₹400 / month | Stores uploaded project photos, profile pictures, and PDF quotes. |
| **SMS Gateway (OTP Login)** | Twilio / Fast2SMS | Pay-as-you-go | ~₹500 / month | For login OTP verification (charged per SMS sent). |
| **SSL Security Certificate** | Cloudflare | **FREE** | ₹0 / month | Secure HTTPS connection for app and admin panel. |
| **Push Notifications (FCM)** | Firebase | **FREE** | ₹0 / month | Real-time push notifications for chat alerts and updates. |
| **Total Monthly Infrastructure Expense**| | **~$40.00 - $50.00** | **~₹3,800 / month** | **Billed directly to cloud providers.** |

---

### **4. Developer Maintenance & Support (Monthly)**
To ensure the app runs smoothly, stays online, and receives necessary updates, a developer maintenance package is established.

| Service | Included Details | Cost (INR) |
| :--- | :--- | :--- |
| **Backend & Frontend Maintenance** | • 24/7 server uptime monitoring and response.<br>• Automated daily database backups and restoration tests.<br>• Troubleshooting & resolving system crashes/bugs.<br>• Minor UI adjustments & content updates (up to 5 hours/month).<br>• Optimization of database queries and server efficiency. | **₹10,000 / month** |

---

### **Summary of Commercials**

* **Initial Development & Build Cost**: **₹40,000** (One-time payment)
* **Initial Go-Live Setup Cost**: **~₹6,000 to ₹14,200** (One-time payment to Stores & DevOps)
* **Monthly Operational Expense (Infrastructure)**: **~₹3,800 / month** (Paid to Vercel/Supabase/Google directly)
* **Monthly Professional Maintenance (Developer)**: **₹10,000 / month** (Paid to Developer)

---

### **Payment Milestone Terms**
To ensure structured progress, the initial development cost is proposed with the following standard milestones:

1. **Advance/Kickoff**: **30%** (₹12,000) - Upon signing & project commencement.
2. **Beta Release**: **40%** (₹16,000) - Upon completion of core app & backend API testing.
3. **Deployment / Go-Live**: **30%** (₹12,000) - Upon publication to Play Store & Handover of credentials.