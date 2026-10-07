import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, FileText, ShieldCheck, RefreshCw } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Terms & Conditions | Connectzy Construction Platform',
  description: 'Official Terms & Conditions and user agreement for Connectzy Construction & Project Management Platform.',
};

export default function TermsPage() {
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
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-white text-blue-600 shadow-sm"
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
              User Agreement & Terms
            </span>
            <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
              Terms & Conditions
            </h1>
            <p className="text-sm font-medium text-slate-600 mt-1">
              Terms of Service &amp; Platform Operating Agreement
            </p>
            <p className="text-xs text-slate-500 mt-1">
              Last Updated: {lastUpdated} • Effective Date: {lastUpdated}
            </p>
          </div>

          <div className="space-y-8 text-slate-700 leading-relaxed text-sm sm:text-base">
            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                1. Acceptance of Terms
              </h2>
              <p>
                By downloading, accessing, or using the <strong>Connectzy</strong> mobile application or website, you agree to be legally bound by these Terms of Service. If you do not agree to these terms, please refrain from using our services.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                2. Scope of Connectzy Services
              </h2>
              <p>
                Connectzy operates as a digital technology platform facilitating:
              </p>
              <ul className="list-disc pl-5 mt-2 space-y-1.5">
                <li>Construction project estimation, budgeting, and material calculation.</li>
                <li>Discovery and engagement of vetted contractors, civil engineers, architects, and trade specialists across 45+ categories.</li>
                <li>Live milestone tracking with photo evidence and digital sign-offs.</li>
                <li>B2B wholesale building material catalog inquiries and supplier connections.</li>
              </ul>
              <p className="mt-2 text-xs text-slate-500">
                Notice: While Connectzy performs verification checks on trade credentials, Connectzy does not directly manufacture construction materials or act as an employer of independent contractors.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                3. User Account Responsibilities
              </h2>
              <p>
                Users must provide accurate, current, and complete registration information. You are solely responsible for maintaining the confidentiality of your login credentials and for all activities occurring under your account.
              </p>
              <p className="mt-2">
                Contractors and suppliers warrant that all uploaded licenses, tax registrations, insurance documents, and past project photos are genuine, unadulterated, and owned by them.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                4. Quotes, Contracts &amp; Payments
              </h2>
              <p>
                All cost estimations provided by the automated calculator are indicative estimates based on current standard market rates. Binding quotes are issued solely through mutual agreement between clients and contractors.
              </p>
              <p className="mt-2">
                Digital transactions and provider membership subscriptions are processed securely via authorized third-party gateways (Razorpay). Users agree to fulfill payment obligations for completed and verified milestones.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                5. Prohibited Conduct
              </h2>
              <p>Users agree not to:</p>
              <ul className="list-disc pl-5 mt-2 space-y-1.5">
                <li>Post fraudulent, deceptive, or defamatory project reviews or contractor profiles.</li>
                <li>Upload copyrighted architectural drawings or photos without authorization.</li>
                <li>Harass, spam, or engage in abusive conduct toward any user or contractor on the platform.</li>
                <li>Attempt to bypass security controls, reverse-engineer, or scrape platform data.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                6. Intellectual Property
              </h2>
              <p>
                All logos, trademarks, design systems, algorithms, cost estimation formulas, and platform code are the exclusive intellectual property of Connectzy Construction Technologies.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                7. Limitation of Liability &amp; Dispute Resolution
              </h2>
              <p>
                Connectzy shall not be liable for indirect, incidental, or consequential damages resulting from on-site construction delays, force majeure weather events, or contractor workmanship disputes. Disputes should first be resolved via good-faith negotiation through our resolution support team.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-slate-900 mb-3">
                8. Contact &amp; Legal Notices
              </h2>
              <p>
                For legal inquiries or notices regarding these terms, contact us at:
              </p>
              <div className="mt-3 p-4 bg-slate-50 border border-slate-200 rounded-xl text-sm">
                <p className="font-bold text-slate-900">Connectzy Legal Department</p>
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
