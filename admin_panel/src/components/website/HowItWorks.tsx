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
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';

const homeownerSteps = [
  {
    icon: ClipboardList,
    title: 'Input Project Details',
    desc: 'Specify your plot size, building type, desired quality grade, and location to get started.',
    detail: 'Our intelligent intake form captures every critical parameter — plot dimensions, soil type, local labor rates, material preferences, and quality grade. This data feeds directly into our estimation engine to produce a project-specific budget baseline before you speak to any contractor.',
  },
  {
    icon: GitCompare,
    title: 'Review & Compare Bids',
    desc: 'Receive competitive bids from top-rated local contractors and material suppliers.',
    detail: 'Your project requirements are broadcast to verified contractors in your region. Each proposal arrives in a standardized format — cost breakdown, timeline, team credentials, and past project portfolio — so you can compare apples to apples and select with confidence.',
  },
  {
    icon: Camera,
    title: 'Monitor Daily Execution',
    desc: 'Track stage-wise progress with photo updates, task completion logs, and material tracking.',
    detail: 'Every construction phase is documented with timestamped photo uploads, material consumption logs, and task checklists. Whether you are on-site or across the country, you see exactly what happened each day — no surprises, no guesswork.',
  },
  {
    icon: CheckCircle2,
    title: 'Hassle-Free Handover',
    desc: 'Receive completed project deliverables supported by itemized payment histories and warranties.',
    detail: 'At project completion you receive a complete handover package: itemized payment ledger, material warranties, structural certificates, and a final audit report reconciling quoted vs. actual quantities — all downloadable as a single PDF dossier.',
  },
];

const businessSteps = [
  {
    icon: Store,
    title: 'Create Business Profile',
    desc: 'Register your company details, business category, service coverage, and portfolio.',
    detail: 'Set up a professional storefront in minutes. Add your company logo, service categories, geographic coverage area, portfolio photos, and team credentials — all displayed to potential clients in a clean, conversion-optimized layout.',
  },
  {
    icon: BadgeCheck,
    title: 'Verify Credentials',
    desc: 'Upload GST, PAN, and identity documents to unlock verified status.',
    detail: 'Our verification team reviews your GST registration, PAN, business license, and identity documents. Once approved, you receive the Connectzy Verified Provider Badge — a trust signal that significantly increases your win rate on incoming inquiries.',
  },
  {
    icon: Inbox,
    title: 'Receive & Quote Leads',
    desc: 'View incoming client inquiries and submit professional proposals.',
    detail: 'Qualified RFQs land directly in your dashboard. Review project specs, ask clarifying questions via in-app chat, and submit branded PDF quotations with your pricing, timeline, and terms — all without leaving the platform.',
  },
  {
    icon: Package,
    title: 'Manage Orders & Invoices',
    desc: 'Generate GST-compliant invoices and manage delivery status from creation to handover.',
    detail: 'Convert accepted quotes into GST-compliant invoices with one click. Track order fulfillment, update delivery status, and reconcile payments — your entire sales lifecycle managed in a single, audit-ready workflow.',
  },
];

export function HowItWorks() {
  const { ref, inView } = useInView({ threshold: 0.1 });
  const [tab, setTab] = useState<'homeowner' | 'business'>('homeowner');
  const [modal, setModal] = useState<number | null>(null);

  const steps = tab === 'homeowner' ? homeownerSteps : businessSteps;

  return (
    <section ref={ref} className="relative overflow-hidden bg-gradient-to-b from-white to-slate-50 py-20 sm:py-28">
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-20" />

      <div className="relative mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-12 text-center"
        >
          <span className="glass mb-4 inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-xs font-semibold text-blue-600 border border-blue-200 bg-blue-50/50">
            HOW IT WORKS
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl">
            A Simple 4-Step Workflow
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-base text-slate-600">
            Whether you are building a home or running a construction business, getting started takes minutes.
          </p>
        </motion.div>

        {/* Tab toggle */}
        <div className="mb-12 flex justify-center">
          <div className="inline-flex rounded-full bg-slate-100 p-1">
            <button
              onClick={() => setTab('homeowner')}
              className={`rounded-full px-5 py-2 text-sm font-semibold transition-all ${
                tab === 'homeowner' ? 'bg-white text-blue-600 shadow-md' : 'text-slate-500'
              }`}
            >
              For Homeowners
            </button>
            <button
              onClick={() => setTab('business')}
              className={`rounded-full px-5 py-2 text-sm font-semibold transition-all ${
                tab === 'business' ? 'bg-white text-blue-600 shadow-md' : 'text-slate-500'
              }`}
            >
              For Businesses
            </button>
          </div>
        </div>

        {/* Timeline */}
        <div className="relative">
          {/* Animated connecting line */}
          <div className="absolute left-8 top-0 h-full w-0.5 bg-slate-200 lg:left-1/2 lg:-translate-x-1/2">
            <motion.div
              initial={{ height: 0 }}
              animate={inView ? { height: '100%' } : {}}
              transition={{ duration: 1.5, delay: 0.3 }}
              className="w-full bg-gradient-to-b from-blue-600 to-sky-400"
            />
          </div>

          <div className="space-y-8">
            {steps.map((step, i) => (
              <motion.div
                key={step.title}
                initial={{ opacity: 0, x: tab === 'homeowner' ? (i % 2 === 0 ? -40 : 40) : (i % 2 === 0 ? 40 : -40) }}
                animate={inView ? { opacity: 1, x: 0 } : {}}
                transition={{ duration: 0.5, delay: i * 0.15 }}
                className="relative pl-20 lg:pl-0"
              >
                {/* Step circle */}
                <div className="absolute left-0 top-0 z-10 lg:left-1/2 lg:-translate-x-1/2">
                  <div className="relative flex h-16 w-16 items-center justify-center rounded-full bg-white shadow-lg ring-4 ring-slate-100">
                    <div className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-blue-600 to-sky-400">
                      <step.icon className="h-6 w-6 text-white" strokeWidth={2} />
                    </div>
                    <span className="absolute -right-1 -top-1 flex h-6 w-6 items-center justify-center rounded-full bg-slate-900 text-xs font-bold text-white">
                      {i + 1}
                    </span>
                  </div>
                </div>

                {/* Step card */}
                <div className={`lg:w-1/2 ${i % 2 === 0 ? 'lg:pr-12' : 'lg:ml-auto lg:pl-12'}`}>
                  <button
                    onClick={() => setModal(i)}
                    className="group flex w-full flex-col items-start rounded-2xl border border-slate-100 bg-white p-5 text-left shadow-sm transition-all hover:shadow-lg hover:border-blue-200"
                  >
                    <h3 className="font-display text-lg font-bold text-slate-900">{step.title}</h3>
                    <p className="mt-1.5 text-sm leading-relaxed text-slate-500">{step.desc}</p>
                    <span className="mt-3 flex items-center gap-1 text-xs font-semibold text-blue-600 opacity-0 transition-opacity group-hover:opacity-100">
                      View details →
                    </span>
                  </button>
                </div>
              </motion.div>
            ))}
          </div>
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
              <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-sky-400 shadow-lg">
                {(() => {
                  const Icon = steps[modal].icon;
                  return <Icon className="h-7 w-7 text-white" />;
                })()}
              </div>
              <span className="text-xs font-semibold text-blue-600">STEP {modal + 1}</span>
              <h3 className="mt-1 font-display text-2xl font-bold text-slate-900">{steps[modal].title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-slate-600">{steps[modal].detail}</p>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  );
}
