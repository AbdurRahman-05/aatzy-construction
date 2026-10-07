import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, RefreshCw, ShieldCheck, FileText } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Refund & Cancellation Policy | Connectzy Construction Platform',
  description: 'Official Refund & Cancellation Policy for Connectzy subscriptions, service inquiries, and transactions.',
};

export default function RefundPolicyPage() {
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
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-slate-600 hover:text-slate-900 transition-colors"
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
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-white text-blue-600 shadow-sm"
          >
            <RefreshCw className="w-4 h-4" />
            Refund Policy
          </Link>
        </div>

        {/* Document Card */}
        <article className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 sm:p-10">
          <div className="border-b border-slate-100 pb-6 mb-8">
            <span className="inline-flex items-center gap-1 text-xs font-bold uppercase tracking-wider text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full mb-3">
              Consumer Protection &amp; Guarantees
            </span>
            <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
              Refund &amp; Cancellation Policy
            </h1>
            <p className="text-sm text-slate-500 mt-2">
              Last Updated: {lastUpdated} • Effective Date: {lastUpdated}
            </p>
          </div>

          <div className="space-y-8 text-slate-700 leading-relaxed text-sm sm:text-base">
            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                1. Overview
              </h2>
              <p>
                At <strong>Connectzy</strong>, customer trust, contractor satisfaction, and fair commercial transactions are our top priorities. This Refund and Cancellation Policy outlines the conditions under which cancellations and refunds are granted for digital memberships, subscriptions, and transaction services.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                2. Provider Annual Membership Subscriptions
              </h2>
              <p>
                Trade providers and contractors who subscribe to the Connectzy Annual Provider Membership plan (365 days) are entitled to our refund consideration window:
              </p>
              <ul className="list-disc pl-5 mt-2 space-y-1.5">
                <li>
                  <strong>7-Day Window:</strong> If you purchased a provider subscription and have not received or bid on customer project leads, you may request a 100% full refund within <strong>7 calendar days</strong> of the activation date.
                </li>
                <li>
                  <strong>Post-7 Days or Active Lead Usage:</strong> Once leads have been unlocked or after 7 days from purchase, the annual membership becomes non-refundable, as digital platform allocation is already consumed.
                </li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                3. Milestone Payments &amp; Project Escrow
              </h2>
              <p>
                For project contracts facilitated through Connectzy milestone escrow:
              </p>
              <ul className="list-disc pl-5 mt-2 space-y-1.5">
                <li>
                  <strong>Pre-Commencement Cancellation:</strong> If a project milestone has not commenced on site and both homeowner and contractor mutually agree to cancel, the allocated milestone fund is refunded in full to the client.
                </li>
                <li>
                  <strong>Milestone Disputes:</strong> In the event of incomplete or disputed workmanship, funds are placed on temporary administrative hold until an on-site photo inspection review is completed by our resolution team.
                </li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                4. B2B Building Materials Orders
              </h2>
              <p>
                Material orders placed with wholesale verified suppliers are subject to supplier transit guarantees:
              </p>
              <ul className="list-disc pl-5 mt-2 space-y-1.5">
                <li>
                  <strong>Damaged or Substandard Goods:</strong> If delivered materials (cement bags, steel, bricks) are damaged or do not match grade specifications upon site delivery, report within 24 hours with photos for a free replacement or full refund.
                </li>
                <li>
                  <strong>Cancellation Prior to Dispatch:</strong> Orders canceled prior to dispatch from the supplier warehouse will be refunded in full minus nominal payment processing fees.
                </li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                5. Refund Processing Timeline
              </h2>
              <p>
                Once an approved refund request is initiated, funds are credited back to the original method of payment (bank account, UPI, debit/credit card via Razorpay) within <strong>5 to 7 business days</strong>, depending on your banking institution.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                6. How to Request a Refund
              </h2>
              <p>
                To file a cancellation or refund request, please contact our payments desk:
              </p>
              <div className="mt-3 p-4 bg-slate-50 border border-slate-200 rounded-xl text-sm">
                <p className="font-bold text-slate-900">Connectzy Billing &amp; Resolution Desk</p>
                <p className="text-slate-600 mt-1">Email: <a href="mailto:support@connectzy.com" className="text-blue-600 font-semibold underline">support@connectzy.com</a></p>
                <p className="text-slate-600">Subject Line: <em>&quot;Refund Request - [Order / Transaction ID]&quot;</em></p>
                <p className="text-slate-600">Response Time: Within 24–48 business hours</p>
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
