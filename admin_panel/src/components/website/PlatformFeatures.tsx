'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Camera,
  Store,
  Calculator,
  HardHat,
  MessageSquare,
  TrendingUp,
  ShieldCheck,
  FileText,
  X,
  ArrowRight,
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';

const features = [
  {
    icon: Camera,
    title: 'Daily Milestone Photo Auditing',
    tag: 'SITE VERIFICATION',
    desc: 'Contractors upload on-site photographic evidence for each phase before milestone payments are released.',
    detail: 'Eliminate disputes and blind advances. As each construction milestone completes (Foundation, Brickwork, MEP, Plastering, Finishing), the contractor uploads photo proof directly into the app for homeowner review and formal sign-off.',
    accent: 'from-blue-600 to-indigo-600',
    color: 'text-blue-600',
    bg: 'bg-blue-50',
  },
  {
    icon: Store,
    title: 'B2B Wholesale Materials Store',
    tag: 'FACTORY DIRECT',
    desc: 'Purchase certified raw materials (Cement, TMT Steel, AAC blocks, aggregates) at wholesale manufacturer prices.',
    detail: 'Cut out middlemen retail markups. Homeowners and contractors can source directly from authorized factory distributors (Ultratech, Tata Tiscon, JSW, Finolex) with transparent bulk pricing, automated RFQs, and live transit dispatch tracking.',
    accent: 'from-purple-600 to-pink-600',
    color: 'text-purple-600',
    bg: 'bg-purple-50',
  },
  {
    icon: Calculator,
    title: 'Instant Cost & Quantity Estimator',
    tag: 'AI BENCHMARKS',
    desc: 'Calculates realistic budgets and material quantities (Cement bags, Steel MT, Bricks, Tiles) for residential & commercial builds.',
    detail: 'Plan your finances with total precision. Select building type (House, Villa, Apartment, Office, Warehouse), quality grade, and built-up area to get instant structural budgets, labor shares, and itemized material consumption sheets.',
    accent: 'from-emerald-600 to-teal-700',
    color: 'text-emerald-600',
    bg: 'bg-emerald-50',
  },
  {
    icon: HardHat,
    title: '45+ Verified Construction Specialties',
    tag: 'VERIFIED PROS',
    desc: 'Complete directory of GST-verified architects, civil engineers, general contractors, interior designers, and MEP specialists.',
    detail: 'Every contractor and consultant undergoes multi-step verification including GST identification, business registration, and past client project reviews before receiving the Connectzy Verified badge.',
    accent: 'from-amber-500 to-orange-600',
    color: 'text-amber-600',
    bg: 'bg-amber-50',
  },
  {
    icon: MessageSquare,
    title: 'Direct In-App Chat & Negotiations',
    tag: 'COMMUNICATION',
    desc: 'Encrypted client-to-contractor messaging with instant blueprint attachments, quote sharing, and query resolution.',
    detail: 'Coordinate smoothly with contractors and suppliers. Discuss scope alterations, share blueprint PDFs, negotiate rates, and keep a clean chronological trail of all discussions linked to each project phase.',
    accent: 'from-sky-500 to-blue-700',
    color: 'text-sky-600',
    bg: 'bg-sky-50',
  },
  {
    icon: TrendingUp,
    title: 'Daily Market Commodity Rates',
    tag: 'PRICE INDEX',
    desc: 'Live regional rates for cement bags, primary steel re-bars, M-sand, wire-cut bricks, and copper to optimize procurement.',
    detail: 'Never overpay for building supplies. The app updates daily wholesale prices across major manufacturing clusters, alerting you to sudden price surges or favorable buying windows.',
    accent: 'from-rose-500 to-red-600',
    color: 'text-rose-600',
    bg: 'bg-rose-50',
  },
  {
    icon: ShieldCheck,
    title: 'Escrow Safe Milestone Payments',
    tag: 'FINANCIAL SAFETY',
    desc: 'Staged payouts protect both parties — funds are safeguarded and released only as certified milestones pass inspection.',
    detail: 'No more abandoned projects. Homeowners fund only approved stages into an escrow safeguard, ensuring contractors receive timely progress draws while clients retain absolute leverage over quality.',
    accent: 'from-teal-600 to-emerald-600',
    color: 'text-teal-600',
    bg: 'bg-teal-50',
  },
  {
    icon: FileText,
    title: 'Itemized Quotations & GST Invoicing',
    tag: 'DOCUMENTATION',
    desc: 'One-click generation of professional PDF quotations, bills of quantities, and digital tax invoices.',
    detail: 'Contractors can submit detailed itemized bids with labor/material breakdowns in minutes. Homeowners can download formal documentation ready for bank home loan approvals and municipal compliance.',
    accent: 'from-blue-600 to-sky-500',
    color: 'text-blue-700',
    bg: 'bg-blue-50',
  },
];

interface PlatformFeaturesProps {
  onNavigate: (target: string) => void;
}

export function PlatformFeatures({ onNavigate }: PlatformFeaturesProps) {
  const { ref, inView } = useInView({ threshold: 0.1 });
  const [modal, setModal] = useState<number | null>(null);

  return (
    <section ref={ref} id="features" className="relative overflow-hidden py-20 sm:py-28 bg-white">
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-25" />
      <div className="pointer-events-none absolute left-1/2 top-1/3 h-96 w-96 -translate-x-1/2 rounded-full bg-blue-500/10 blur-[130px]" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-14 text-center max-w-3xl mx-auto"
        >
          <span className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-blue-50 text-blue-700 text-xs font-black tracking-wider uppercase border border-blue-200 mb-3">
            BUILT FOR INDIAN CONSTRUCTION
          </span>
          <h2 className="font-display text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight text-slate-900">
            Engineered to Solve Every Construction Pain Point
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-600 leading-relaxed">
            From initial budgeting to vendor hiring, material procurement, and stage-by-stage photo verification —
            experience end-to-end transparency.
          </p>
        </motion.div>

        {/* Features Grid */}
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {features.map((feature, i) => {
            const Icon = feature.icon;
            return (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 30 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.4, delay: i * 0.05 }}
                className="group relative rounded-3xl border border-slate-200/90 bg-white p-6 shadow-sm hover:shadow-xl hover:border-blue-400 transition-all duration-300 flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <div className={`p-3 rounded-2xl ${feature.bg} ${feature.color} shadow-sm group-hover:scale-110 transition-transform duration-200`}>
                      <Icon className="h-6 w-6" />
                    </div>
                    <span className="text-[9px] font-black tracking-wider uppercase text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md">
                      {feature.tag}
                    </span>
                  </div>

                  <h3 className="text-base font-extrabold text-slate-900 group-hover:text-blue-600 transition-colors leading-snug">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-xs text-slate-600 leading-relaxed line-clamp-3">
                    {feature.desc}
                  </p>
                </div>

                <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between">
                  <button
                    onClick={() => setModal(i)}
                    className="text-xs font-bold text-blue-600 hover:text-blue-800 transition flex items-center gap-1 cursor-pointer"
                  >
                    <span>Learn More</span>
                    <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
                  </button>
                  <span className="text-[10px] font-bold text-slate-400">0{i + 1}</span>
                </div>
              </motion.div>
            );
          })}
        </div>

        {/* Modal detail dialog */}
        <AnimatePresence>
          {modal !== null && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm"
              onClick={() => setModal(null)}
            >
              <motion.div
                initial={{ scale: 0.95, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.95, opacity: 0 }}
                className="relative max-w-lg w-full rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-100"
                onClick={(e) => e.stopPropagation()}
              >
                <button
                  onClick={() => setModal(null)}
                  className="absolute right-4 top-4 p-2 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition cursor-pointer"
                >
                  <X className="h-5 w-5" />
                </button>

                <div className="flex items-center gap-3 mb-4">
                  <div className={`p-3 rounded-2xl ${features[modal].bg} ${features[modal].color}`}>
                    {(() => {
                      const Icon = features[modal].icon;
                      return <Icon className="h-6 w-6" />;
                    })()}
                  </div>
                  <div>
                    <span className="text-[10px] font-black uppercase text-blue-600 tracking-wider">
                      {features[modal].tag}
                    </span>
                    <h3 className="font-extrabold text-xl text-slate-900 leading-tight">
                      {features[modal].title}
                    </h3>
                  </div>
                </div>

                <p className="text-sm text-slate-600 leading-relaxed mt-4">
                  {features[modal].detail}
                </p>

                <div className="mt-6 pt-4 border-t border-slate-100 flex justify-end gap-3">
                  <button
                    onClick={() => setModal(null)}
                    className="px-5 py-2.5 text-xs font-bold text-slate-600 hover:bg-slate-100 rounded-xl transition cursor-pointer"
                  >
                    Close
                  </button>
                  <button
                    onClick={() => {
                      setModal(null);
                      onNavigate('download');
                    }}
                    className="px-6 py-2.5 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-md shadow-blue-500/30 transition cursor-pointer"
                  >
                    Try in App
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </section>
  );
}
