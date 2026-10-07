import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, ShieldCheck, Mail, Lock, FileText, RefreshCw } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Privacy Policy | Connectzy Construction Platform',
  description: 'Official Privacy Policy for Connectzy Construction & Project Management Platform and Mobile App.',
};

export default function PrivacyPolicyPage() {
  const lastUpdated = 'October 7, 2026';

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 flex flex-col justify-between">
      {/* Top Header */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200 shadow-sm">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2 group">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/assets/logo.png"
              alt="Connectzy Logo"
              className="h-10 w-auto object-contain transition-transform group-hover:scale-105"
            />
          </Link>

          <div className="flex items-center gap-2 sm:gap-4 text-xs sm:text-sm font-medium">
            <Link
              href="/"
              className="inline-flex items-center gap-1.5 text-slate-600 hover:text-blue-600 transition-colors py-1.5 px-3 rounded-lg hover:bg-slate-100"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to Home</span>
            </Link>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full flex-1">
        {/* Policy Navigation Tabs */}
        <div className="flex flex-wrap items-center gap-2 mb-8 p-1.5 bg-slate-200/70 rounded-xl w-fit text-xs sm:text-sm font-semibold">
          <Link
            href="/privacy-policy"
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-white text-blue-600 shadow-sm"
          >
            <ShieldCheck className="w-4 h-4" />
            Privacy Policy
          </Link>
          <Link
            href="/terms-and-conditions"
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-slate-600 hover:text-slate-900 transition-colors"
          >
            <FileText className="w-4 h-4" />
            Terms & Conditions
          </Link>
          <Link
            href="/refund-policy"
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-slate-600 hover:text-slate-900 transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Refund Policy
          </Link>
        </div>

        {/* Document Card */}
        <article className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 sm:p-10">
          <div className="border-b border-slate-100 pb-6 mb-8">
            <span className="inline-flex items-center gap-1 text-xs font-bold uppercase tracking-wider text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full mb-3">
              Official Legal Document
            </span>
            <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
              Privacy Policy
            </h1>
            <p className="text-sm text-slate-500 mt-2">
              Last Updated: {lastUpdated} • Effective Date: {lastUpdated}
            </p>
          </div>

          <div className="space-y-8 text-slate-700 leading-relaxed text-sm sm:text-base">
            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                1. Introduction
              </h2>
              <p>
                Welcome to <strong>Connectzy</strong> (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;), operated by Connectzy Construction Technologies. We are committed to protecting the personal privacy of our users (&quot;you&quot; or &quot;your&quot;) across our mobile application available on the Google Play Store and our web platform at <code className="bg-slate-100 px-1.5 py-0.5 rounded text-blue-600">https://connectzy.com</code>.
              </p>
              <p className="mt-2">
                This Privacy Policy outlines how we collect, use, disclose, and safeguard your data when you use our construction cost estimation tools, contractor directory, milestone progress verification, B2B materials marketplace, and messaging systems.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                2. Information We Collect
              </h2>
              <p>We collect several categories of information to provide reliable construction and project coordination services:</p>
              <ul className="list-disc pl-5 mt-2 space-y-1.5">
                <li>
                  <strong>Account &amp; Identity Data:</strong> Name, email address, phone number, profile photo, and role (Property Owner, General Contractor, Specialized Trade Professional, or Material Supplier).
                </li>
                <li>
                  <strong>Project &amp; Construction Data:</strong> Project title, project location, plot/building size, estimated budget, architectural blueprints, bill of quantities (BOQ), and site progress photographs.
                </li>
                <li>
                  <strong>Business &amp; Trade Credentials:</strong> For contractors and trade providers, we collect professional licenses, registration numbers, years of experience, trade specialties, and insurance information for verification.
                </li>
                <li>
                  <strong>Communications:</strong> In-app chat messages, inquiry notes, quote proposals, and site inspection sign-offs exchanged between clients and providers.
                </li>
                <li>
                  <strong>Payment &amp; Transaction Details:</strong> Invoices, transaction reference IDs, and payment statuses processed securely via certified payment gateways (e.g., Razorpay). We do not store sensitive payment card numbers on our servers.
                </li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                3. Device Permissions &amp; Hardware Access
              </h2>
              <p>Our Android mobile application requests specific device permissions to enable core features:</p>
              <div className="mt-3 grid gap-3 sm:grid-cols-2">
                <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50">
                  <p className="font-bold text-slate-900 text-sm">📍 Location (Fine &amp; Coarse)</p>
                  <p className="text-xs text-slate-600 mt-1">
                    Used to identify local construction material suppliers and recommend nearby verified contractors within your geographic area. Location is never tracked continuously in the background.
                  </p>
                </div>
                <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50">
                  <p className="font-bold text-slate-900 text-sm">📸 Camera &amp; Storage</p>
                  <p className="text-xs text-slate-600 mt-1">
                    Allows users and site engineers to capture and upload real-time milestone verification photographs, architectural drawings, and company documents.
                  </p>
                </div>
                <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50">
                  <p className="font-bold text-slate-900 text-sm">🔔 Push Notifications</p>
                  <p className="text-xs text-slate-600 mt-1">
                    Sends real-time alerts for incoming customer project inquiries, quote acceptances, milestone approvals, and direct chat messages.
                  </p>
                </div>
                <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50">
                  <p className="font-bold text-slate-900 text-sm">🌐 Internet &amp; Network State</p>
                  <p className="text-xs text-slate-600 mt-1">
                    Required to synchronize live construction data, update daily commodity prices, and maintain real-time messaging with your team.
                  </p>
                </div>
              </div>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                4. Third-Party Service Providers
              </h2>
              <p>
                To provide seamless and secure platform operations, we integrate trusted third-party services that adhere strictly to industry standards:
              </p>
              <ul className="list-disc pl-5 mt-2 space-y-1.5">
                <li><strong>Google Play Services &amp; Google Sign-In:</strong> For secure authentication and store distribution.</li>
                <li><strong>Firebase (Google LLC):</strong> Firebase Cloud Messaging (FCM) for push notifications and backend analytics.</li>
                <li><strong>Razorpay:</strong> PCI-DSS compliant payment processing for memberships and transactions.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                5. Data Retention &amp; User Account Deletion Rights
              </h2>
              <p>
                You retain complete control over your personal data. We keep your information only as long as necessary to provide services and comply with legal requirements.
              </p>
              <div className="mt-3 p-4 bg-blue-50/70 border border-blue-200 rounded-xl">
                <p className="font-bold text-blue-900 text-sm">How to Request Account &amp; Data Deletion:</p>
                <p className="text-xs text-blue-800 mt-1">
                  In compliance with Google Play Store User Data policies, you can request permanent deletion of your account and associated personal data at any time by:
                </p>
                <ul className="list-disc pl-5 mt-2 text-xs text-blue-800 space-y-1">
                  <li>Navigating to <strong>Profile &rarr; Account Settings &rarr; Delete Account</strong> within the mobile app.</li>
                  <li>Or sending an email request to <strong className="underline">support@connectzy.com</strong> with the subject line <em>&quot;Account Deletion Request&quot;</em> from your registered email address.</li>
                </ul>
                <p className="text-xs text-blue-800 mt-2">
                  Upon verification, all personal identification records, credentials, and stored site media will be permanently purged within 30 days.
                </p>
              </div>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                6. Children&apos;s Privacy
              </h2>
              <p>
                Connectzy is an enterprise construction and contractor platform designed strictly for adults (aged 18 and older). We do not knowingly collect personal information from children under 13 years of age. If we learn that a minor has provided us with personal information, we immediately delete such data.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                7. Security Measures
              </h2>
              <p>
                We implement industry-standard encryption protocols (HTTPS/TLS) for data in transit and secure database storage for data at rest. Access to sensitive provider and client credentials is strictly restricted to authorized platform personnel.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
                8. Contact Information
              </h2>
              <p>
                If you have any questions, concerns, or privacy inquiries regarding this Privacy Policy, please contact our Data Protection Officer:
              </p>
              <div className="mt-3 p-4 bg-slate-50 border border-slate-200 rounded-xl text-sm">
                <p className="font-bold text-slate-900">Connectzy Construction Technologies</p>
                <p className="text-slate-600 mt-1">Email: <a href="mailto:support@connectzy.com" className="text-blue-600 font-semibold underline">support@connectzy.com</a></p>
                <p className="text-slate-600">Location: Kochi, Kerala, India</p>
              </div>
            </section>
          </div>
        </article>
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-400 py-8 border-t border-slate-800 text-center text-xs">
        <div className="max-w-4xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>© 2026 Connectzy Construction Technologies. All rights reserved.</p>
          <div className="flex gap-4">
            <Link href="/privacy-policy" className="text-slate-300 hover:text-white">Privacy Policy</Link>
            <Link href="/terms-and-conditions" className="text-slate-300 hover:text-white">Terms & Conditions</Link>
            <Link href="/refund-policy" className="text-slate-300 hover:text-white">Refund Policy</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
