'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  MessageSquare,
  FileText,
  Newspaper,
  ClipboardCheck,
  ShieldCheck,
  Landmark,
  Bell,
  X,
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';

const features = [
  {
    icon: MessageSquare,
    title: 'Real-Time B2B Chat System',
    desc: 'Direct client-to-contractor messaging with instant file attachments, blueprint sharing, and query management.',
    detail: 'Our chat system allows you to create specific threads for each project phase. Share files, annotate blueprints, and automatically save all communications to the project audit log for clear record-keeping.',
    accent: 'from-blue-600 to-sky-400',
  },
  {
    icon: FileText,
    title: 'Customizable PDF Invoicing',
    desc: 'All generated estimates and quotes automatically format into professional PDF documents with company banking details.',
    detail: 'Convert estimates into GST-compliant invoices with one click. Send branded PDFs directly to clients and track payment status in real-time from your financial dashboard.',
    accent: 'from-sky-400 to-blue-600',
  },
  {
    icon: Newspaper,
    title: 'Live Material News & Trends',
    desc: 'Access daily updated market prices for cement, steel, sand, and aggregate materials, empowering smart procurement timing.',
    detail: 'We aggregate pricing data from hundreds of regional suppliers to give you accurate daily market rates. Set price alerts for specific materials to buy when rates drop.',
    accent: 'from-amber-500 to-sky-400',
  },
  {
    icon: ClipboardCheck,
    title: 'Comprehensive Audit Logs',
    desc: 'Track exact material quantities used during each construction phase to eliminate waste and prevent overbilling.',
    detail: 'Site managers can log daily material consumption with photo proof. The system reconciles this against the original bill of quantities to instantly flag any discrepancies or wastage.',
    accent: 'from-emerald-500 to-blue-600',
  },
  {
    icon: ShieldCheck,
    title: 'Vendor Verification System',
    desc: 'Administrative verification ensures only registered, compliant, and trustworthy businesses operate within the ecosystem.',
    detail: 'Every vendor undergoes a strict verification process including GST validation, identity checks, and reference calls before they receive the Connectzy Verified badge.',
    accent: 'from-blue-600 to-emerald-500',
  },
  {
    icon: Landmark,
    title: 'Bank Integration & Security',
    desc: 'Direct bank account linking with encrypted payment gateways for secure, transparent transactions between all parties.',
    detail: 'Our escrow-like milestone payment system ensures funds are securely held and only released when specific construction phases are verified as complete by both parties.',
    accent: 'from-sky-400 to-amber-500',
  },
  {
    icon: Bell,
    title: 'Smart Notifications & Alerts',
    desc: 'Real-time alerts for new inquiries, order updates, milestone completions, and price changes.',
    detail: 'Customize your notification preferences across email, SMS, and push. Never miss a critical RFQ, payment confirmation, or urgent site update again.',
    accent: 'from-amber-500 to-blue-600',
  },
];

interface PlatformFeaturesProps {
  onNavigate: (target: string) => void;
}

export function PlatformFeatures({ onNavigate }: PlatformFeaturesProps) {
  const { ref, inView } = useInView({ threshold: 0.1 });
  const [modal, setModal] = useState<number | null>(null);

  return (
    <section ref={ref} id="features" className="relative overflow-hidden py-20 sm:py-28">
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-20" />
      <div className="pointer-events-none absolute left-1/2 top-1/3 h-96 w-96 -translate-x-1/2 rounded-full bg-blue-500/10 blur-[120px]" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-14 text-center"
        >
          <span className="glass mb-4 inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-xs font-semibold text-blue-600 border border-blue-200 bg-blue-50/50">
            PLATFORM MODULES
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl">
            Key Platform Features & Modules
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-base text-slate-600">
            A complete construction management ecosystem with every tool you need to build smarter.
          </p>
        </motion.div>

        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {features.map((feature, i) => (
            <motion.button
              key={feature.title}
              initial={{ opacity: 0, y: 40, scale: 0.95 }}
              animate={inView ? { opacity: 1, y: 0, scale: 1 } : {}}
              transition={{ duration: 0.5, delay: i * 0.08 }}
              whileHover={{ y: -8, scale: 1.02 }}
              onClick={() => setModal(i)}
              className="group relative overflow-hidden rounded-3xl border border-slate-100 bg-white p-6 text-left shadow-sm transition-all duration-300 hover:shadow-2xl hover:border-blue-200"
            >
              {/* Gradient border glow on hover */}
              <div className={`absolute inset-0 bg-gradient-to-br ${feature.accent} opacity-0 transition-opacity duration-500 group-hover:opacity-[0.04]`} />

              <div className={`relative mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br ${feature.accent} shadow-lg transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-6`}>
                <feature.icon className="h-7 w-7 text-white" strokeWidth={2} />
              </div>
              <h3 className="relative font-display text-base font-bold leading-tight text-slate-900">
                {feature.title}
              </h3>
              <p className="relative mt-2 text-sm leading-relaxed text-slate-500">
                {feature.desc}
              </p>
              <span className="relative mt-4 flex items-center gap-1 text-xs font-semibold text-blue-600 opacity-0 transition-opacity duration-300 group-hover:opacity-100">
                Learn more →
              </span>
            </motion.button>
          ))}
        </div>
      </div>

      {/* Detail modal */}
      <AnimatePresence>
        {modal !== null && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setModal(null)}
            className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm"
          >
            <motion.div
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.9, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="glass-card relative max-w-lg rounded-3xl p-8 bg-white border border-slate-200 shadow-2xl"
            >
              <button
                onClick={() => setModal(null)}
                className="absolute right-4 top-4 flex h-9 w-9 items-center justify-center rounded-full bg-slate-100 text-slate-500 transition-colors hover:bg-slate-200"
                aria-label="Close"
              >
                <X className="h-5 w-5" />
              </button>
              <div className={`mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br ${features[modal].accent} shadow-lg`}>
                {(() => {
                  const Icon = features[modal].icon;
                  return <Icon className="h-7 w-7 text-white" />;
                })()}
              </div>
              <h3 className="mt-1 font-display text-2xl font-bold text-slate-900">{features[modal].title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-slate-600">{features[modal].detail}</p>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  );
}
