'use client';

import { motion } from 'framer-motion';
import {
  BadgeCheck,
  Inbox,
  Store,
  FileText,
  BarChart3,
  TrendingUp,
  Users,
  Package,
  IndianRupee,
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';
import { AnimatedCounter } from './AnimatedCounter';

const features = [
  {
    icon: BadgeCheck,
    title: 'Get Verified & Build Client Trust',
    desc: 'Complete our verification check (GST, PAN, Aadhar, and business registration) to display the official Connectzy Verified Provider Badge.',
  },
  {
    icon: Inbox,
    title: 'Receive Direct RFQs & Project Inquiries',
    desc: 'Get instant leads from homeowners actively looking to hire contractors or purchase construction materials in your region.',
  },
  {
    icon: Store,
    title: 'Digital Storefront & Material Catalog',
    desc: 'Showcase raw materials and equipment with unit pricing (Per Bag, Per Ton, Per Unit), technical specifications, and stock updates.',
  },
  {
    icon: FileText,
    title: 'Instant Professional PDF Quotations & Invoicing',
    desc: 'Generate itemized PDF quotes branded with your logo, tax rates (GST), and direct bank payment details for fast client acceptance.',
  },
];

interface ContractorsProps {
  onNavigate: (target: string) => void;
}

export function Contractors({ onNavigate }: ContractorsProps) {
  const { ref, inView } = useInView({ threshold: 0.15 });

  return (
    <section
      ref={ref}
      id="contractors"
      className="relative overflow-hidden bg-gradient-to-br from-slate-900 via-slate-800 to-slate-950 py-20 text-white sm:py-28"
    >
      {/* Animated grid background */}
      <div className="pointer-events-none absolute inset-0 bg-grid-dark opacity-40" />
      <div className="pointer-events-none absolute left-1/4 top-0 h-96 w-96 rounded-full bg-blue-600/15 blur-[120px]" />
      <div className="pointer-events-none absolute right-1/4 bottom-0 h-96 w-96 rounded-full bg-sky-400/15 blur-[120px]" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-center gap-12 lg:grid-cols-2">
          {/* Left — Content */}
          <div>
            <motion.div
              initial={{ opacity: 0, x: -60 }}
              animate={inView ? { opacity: 1, x: 0 } : {}}
              transition={{ duration: 0.8 }}
            >
              <span className="mb-4 inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-1.5 text-xs font-semibold text-sky-400 backdrop-blur-sm">
                FOR CONTRACTORS, ARCHITECTS & SUPPLIERS
              </span>
              <h2 className="font-display text-3xl font-extrabold leading-tight tracking-tight sm:text-4xl lg:text-5xl">
                Supercharge Your Construction Business & Win High-Value Projects
              </h2>
              <p className="mt-4 text-base text-slate-300">
                Join an exclusive network of verified builders, service providers, and material dealers.
              </p>
            </motion.div>

            <div className="mt-8 grid gap-4 sm:grid-cols-2">
              {features.map((feature, i) => (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 30 }}
                  animate={inView ? { opacity: 1, y: 0 } : {}}
                  transition={{ duration: 0.5, delay: 0.2 + i * 0.1 }}
                  whileHover={{ y: -6, rotateY: 4 }}
                  className="group relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur-sm transition-all hover:border-sky-400/40 hover:bg-white/[0.07] preserve-3d"
                >
                  <div className="relative">
                    <div className="mb-3 flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-blue-600 to-sky-400 shadow-lg transition-transform group-hover:scale-110 group-hover:rotate-6">
                      <feature.icon className="h-5 w-5 text-white" strokeWidth={2} />
                    </div>
                    <h3 className="font-display text-sm font-bold leading-tight">{feature.title}</h3>
                    <p className="mt-1.5 text-xs leading-relaxed text-slate-300">{feature.desc}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>

          {/* Right — Dashboard mockup */}
          <motion.div
            initial={{ opacity: 0, x: 60 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="relative"
          >
            <div className="glass-dark relative rounded-3xl p-6 shadow-2xl border border-white/10 bg-slate-900/80 backdrop-blur-xl">
              {/* Dashboard header */}
              <div className="mb-5 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-blue-600 to-sky-400">
                    <BarChart3 className="h-4 w-4 text-white" />
                  </div>
                  <div>
                    <p className="text-sm font-bold">Provider Dashboard</p>
                    <p className="text-[10px] text-slate-300">Vikram Construction Supplies</p>
                  </div>
                </div>
                <span className="flex items-center gap-1 rounded-full bg-emerald-500/20 px-2.5 py-1 text-[10px] font-semibold text-emerald-400">
                  <BadgeCheck className="h-3 w-3" /> Verified
                </span>
              </div>

              {/* Stats grid */}
              <div className="mb-4 grid grid-cols-3 gap-3">
                {[
                  { icon: Inbox, label: 'New Leads', value: 12, color: 'text-sky-400' },
                  { icon: IndianRupee, label: 'Revenue', value: '₹4.2L', color: 'text-emerald-400', isText: true },
                  { icon: Package, label: 'Orders', value: 28, color: 'text-amber-400' },
                ].map((stat) => (
                  <div key={stat.label} className="rounded-xl bg-white/5 p-3 backdrop-blur-sm">
                    <stat.icon className={`mb-1.5 h-4 w-4 ${stat.color}`} />
                    <p className="text-lg font-extrabold">
                      {stat.isText ? stat.value : <AnimatedCounter end={stat.value as number} start={inView} duration={1500} />}
                    </p>
                    <p className="text-[9px] text-slate-400">{stat.label}</p>
                  </div>
                ))}
              </div>

              {/* Chart */}
              <div className="mb-4 rounded-xl bg-white/5 p-4 backdrop-blur-sm">
                <div className="mb-3 flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-slate-200">Inquiry Growth</span>
                  <span className="flex items-center gap-1 text-[10px] font-semibold text-emerald-400">
                    <TrendingUp className="h-3 w-3" /> +42%
                  </span>
                </div>
                <div className="flex h-24 items-end gap-2">
                  {[30, 45, 38, 60, 52, 78, 65, 90].map((h, i) => (
                    <motion.div
                      key={i}
                      initial={{ height: 0 }}
                      animate={inView ? { height: `${h}%` } : {}}
                      transition={{ duration: 0.6, delay: 0.4 + i * 0.08 }}
                      className="flex-1 rounded-t bg-gradient-to-t from-blue-600 to-sky-400"
                    />
                  ))}
                </div>
              </div>

              {/* Recent inquiry */}
              <div className="rounded-xl bg-white/5 p-3 backdrop-blur-sm">
                <div className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-500/20">
                    <Users className="h-4 w-4 text-sky-400" />
                  </div>
                  <div className="flex-1">
                    <p className="text-xs font-semibold">Ramesh K. requested a quote</p>
                    <p className="text-[10px] text-slate-400">3 BHK House · 1,800 sq ft · Bengaluru</p>
                  </div>
                  <button className="rounded-full bg-gradient-to-r from-blue-600 to-sky-400 px-3 py-1 text-[10px] font-semibold text-white">
                    Quote
                  </button>
                </div>
              </div>
            </div>

            {/* Floating verified badge */}
            <motion.div
              animate={{ y: [0, -14, 0], rotate: [0, 3, 0] }}
              transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
              className="absolute -right-3 -top-3 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-br from-emerald-500 to-blue-600 shadow-xl"
            >
              <BadgeCheck className="h-8 w-8 text-white" strokeWidth={2.5} />
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
