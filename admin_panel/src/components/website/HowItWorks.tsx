'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ClipboardList,
  GitCompare,
  Camera,
  CheckCircle2,
  Store,
  BadgeCheck,
  Inbox,
  Package,
  X,
  ArrowRight,
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';

const homeownerSteps = [
  {
    icon: ClipboardList,
    title: 'Calculate Estimate & Post Project',
    tag: 'STEP 01',
    desc: 'Specify your plot size, building type, desired quality grade, and location to calculate budgets and publish your project.',
    detail: 'Our intelligent calculator computes realistic building budgets based on live engineering rates. Post your custom project specs, timeline, and material preferences to invite verified proposals without exposing your personal phone number.',
  },
  {
    icon: GitCompare,
    title: 'Review & Compare Contractor Bids',
    tag: 'STEP 02',
    desc: 'Receive competitive proposals from top-rated regional builders, architects, and trade specialists.',
    detail: 'Contractors submit itemized quotations detailing labor shares, material brands, and milestone dates. Compare bids side-by-side, inspect their past site photos and GST credentials, and select your preferred partner.',
  },
  {
    icon: Camera,
    title: 'Monitor Daily On-Site Photo Proofs',
    tag: 'STEP 03',
    desc: 'Track stage-wise execution with geo-tagged photos, task checklists, and material consumption logs.',
    detail: 'Every construction milestone (Excavation, Foundation, RCC Slab, Brickwork, MEP, Plastering, Painting) is verified with timestamped photo uploads directly in the app. You inspect real progress before approving any milestone.',
  },
  {
    icon: CheckCircle2,
    title: 'Release Stage Draws & Handover',
    tag: 'STEP 04',
    desc: 'Safe milestone escrow payouts guarantee work quality right through to final keys handover.',
    detail: 'Funds are protected and released incrementally as certified phases pass client inspection. At project completion, download the complete audit trail: itemized payment ledger, material warranties, and structural certificates.',
  },
];

const businessSteps = [
  {
    icon: Store,
    title: 'Register & Showcase Portfolio',
    tag: 'STEP 01',
    desc: 'Create your digital business profile, select your trade specialties, service radius, and past projects.',
    detail: 'Set up your professional construction storefront in minutes. Select from 45+ trade categories (General Contractor, Civil Engineer, Tile Worker, Steel Supplier, etc.), upload your past job photos, and list your business certifications.',
  },
  {
    icon: BadgeCheck,
    title: 'Verify GST & Identity Credentials',
    tag: 'STEP 02',
    desc: 'Upload GSTIN, PAN, and contractor licenses to earn the official Connectzy Verified Trust Badge.',
    detail: 'Our compliance team checks your documents to verify your business legitimacy. Once approved, you gain priority placement in regional homeowner searches and unlock full bidding privileges on incoming projects.',
  },
  {
    icon: Inbox,
    title: 'Receive Matched Client Leads & Quote',
    tag: 'STEP 03',
    desc: 'Get instant notifications for fresh project inquiries in your area and submit professional PDF proposals.',
    detail: 'Qualified client leads land directly in your dashboard. Chat with homeowners, clarify site drawings, and submit itemized quotations with competitive pricing and milestone schedules.',
  },
  {
    icon: Package,
    title: 'Upload Daily Tasks & Receive Payouts',
    tag: 'STEP 04',
    desc: 'Update milestone progress photos, log material usage, and receive secure milestone payments on completion.',
    detail: 'Keep clients delighted by snapping quick photos on site as tasks complete. Milestone payouts are triggered swiftly upon client sign-off, ensuring steady cash flow for your crew and suppliers.',
  },
];

export function HowItWorks() {
  const { ref, inView } = useInView({ threshold: 0.1 });
  const [tab, setTab] = useState<'homeowner' | 'business'>('homeowner');
  const [modal, setModal] = useState<number | null>(null);

  const steps = tab === 'homeowner' ? homeownerSteps : businessSteps;

  return (
    <section id="how-it-works" ref={ref} className="relative overflow-hidden bg-gradient-to-b from-white to-slate-50 py-20 sm:py-28 border-t border-slate-200">
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-20" />

      <div className="relative mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-12 text-center max-w-2xl mx-auto"
        >
          <span className="glass mb-4 inline-flex items-center gap-1.5 rounded-full px-4 py-1.5 text-xs font-black text-blue-600 border border-blue-200 bg-blue-50/50 uppercase tracking-wider">
            TRANSPARENT WORKFLOW
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl">
            How Connectzy Works
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-600 leading-relaxed">
            A structured, 4-step framework engineered for complete trust and on-time execution.
          </p>
        </motion.div>

        {/* Audience Selector Tabs */}
        <div className="mb-12 flex justify-center">
          <div className="glass inline-flex rounded-2xl p-1.5 shadow-sm border border-slate-200 bg-slate-100/70">
            <button
              onClick={() => setTab('homeowner')}
              className={`rounded-xl px-5 sm:px-8 py-2.5 text-xs sm:text-sm font-extrabold transition-all cursor-pointer ${
                tab === 'homeowner'
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-500/30'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              For Homeowners & Clients
            </button>
            <button
              onClick={() => setTab('business')}
              className={`rounded-xl px-5 sm:px-8 py-2.5 text-xs sm:text-sm font-extrabold transition-all cursor-pointer ${
                tab === 'business'
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-500/30'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              For Contractors & Suppliers
            </button>
          </div>
        </div>

        {/* Steps Grid */}
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((step, i) => {
            const Icon = step.icon;
            return (
              <motion.div
                key={step.title}
                initial={{ opacity: 0, y: 30 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                className="group relative rounded-3xl border border-slate-200 bg-white p-6 shadow-sm hover:shadow-xl hover:border-blue-400 transition-all duration-300 flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between mb-5">
                    <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-50 text-blue-600 shadow-inner group-hover:scale-110 transition-transform">
                      <Icon className="h-6 w-6" />
                    </div>
                    <span className="text-[10px] font-black uppercase text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-100">
                      {step.tag}
                    </span>
                  </div>

                  <h3 className="text-base font-extrabold text-slate-900 group-hover:text-blue-600 transition-colors leading-snug">
                    {step.title}
                  </h3>
                  <p className="mt-2.5 text-xs text-slate-600 leading-relaxed">
                    {step.desc}
                  </p>
                </div>

                <div className="mt-6 pt-3 border-t border-slate-100 flex items-center justify-between">
                  <button
                    onClick={() => setModal(i)}
                    className="text-xs font-bold text-blue-600 hover:text-blue-800 transition flex items-center gap-1 cursor-pointer"
                  >
                    <span>Read Details</span>
                    <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
                  </button>
                  <span className="text-xs font-black text-slate-300">0{i + 1}</span>
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

                <span className="text-[10px] font-black uppercase text-blue-600 tracking-wider">
                  {steps[modal].tag}
                </span>
                <h3 className="font-extrabold text-xl text-slate-900 leading-tight mt-1 mb-3">
                  {steps[modal].title}
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed">
                  {steps[modal].detail}
                </p>

                <div className="mt-6 pt-4 border-t border-slate-100 flex justify-end">
                  <button
                    onClick={() => setModal(null)}
                    className="px-6 py-2.5 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-md transition cursor-pointer"
                  >
                    Got It
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
