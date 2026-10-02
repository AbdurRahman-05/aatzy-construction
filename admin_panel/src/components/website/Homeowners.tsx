'use client';

import { motion } from 'framer-motion';
import { Calculator, GitCompare, Camera, Package, ShieldCheck } from 'lucide-react';
import { useInView } from '../../hooks/useInView';

const features = [
  {
    icon: Calculator,
    title: '30-Second Accurate Cost Estimation',
    desc: 'Stop relying on rough verbal estimates. Calculate complete project budgets based on live material rates, local labor costs, and quality requirements.',
    accent: 'from-blue-600 to-sky-400',
  },
  {
    icon: GitCompare,
    title: 'Multi-Vendor Quote Comparison',
    desc: 'Receive formal proposals from local certified contractors. Compare breakdown costs, execution timelines, and vendor credentials side by side.',
    accent: 'from-sky-400 to-blue-600',
  },
  {
    icon: Camera,
    title: 'Milestone Progress Tracking with Photo Proof',
    desc: 'Follow your project stage by stage — Foundation, Structure, Interior, Finishing. Contractors upload real-time completion photos directly to your dashboard.',
    accent: 'from-emerald-500 to-blue-600',
  },
  {
    icon: Package,
    title: 'Direct B2B Raw Material Purchasing',
    desc: 'Source cement, TMT steel bars, bricks, sand, tiles, and electrical supplies directly from authorized suppliers with transparent per-unit pricing.',
    accent: 'from-amber-500 to-sky-400',
  },
];

interface HomeownersProps {
  onNavigate: (target: string) => void;
}

export function Homeowners({ onNavigate }: HomeownersProps) {
  const { ref, inView } = useInView({ threshold: 0.1 });

  return (
    <section ref={ref} id="homeowners" className="relative overflow-hidden py-20 sm:py-28">
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-20" />
      <div className="pointer-events-none absolute -left-40 top-20 h-96 w-96 rounded-full bg-blue-500/10 blur-[120px]" />
      <div className="pointer-events-none absolute -right-40 bottom-20 h-96 w-96 rounded-full bg-sky-400/10 blur-[120px]" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-center gap-12 lg:grid-cols-2">
          {/* Left — Image */}
          <motion.div
            initial={{ opacity: 0, x: -60 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8 }}
            className="relative"
          >
            <div className="relative overflow-hidden rounded-3xl shadow-2xl">
              <img
                src="https://images.pexels.com/photos/17707574/pexels-photo-17707574.jpeg"
                alt="Luxury modern villa under construction"
                loading="lazy"
                className="h-[520px] w-full object-cover transition-transform duration-700 hover:scale-105"
              />

              {/* Floating stat card */}
              <motion.div
                animate={{ y: [0, -10, 0] }}
                transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
                className="glass-card absolute bottom-6 right-6 w-52 rounded-2xl p-4 shadow-xl border border-white/80 bg-white/90 backdrop-blur-md"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-500 to-blue-600">
                    <ShieldCheck className="h-5 w-5 text-white" />
                  </div>
                  <div>
                    <p className="font-display text-2xl font-extrabold text-slate-900">₹3.5L</p>
                    <p className="text-[10px] text-slate-500">Average savings per project</p>
                  </div>
                </div>
              </motion.div>

              {/* Floating progress card */}
              <motion.div
                animate={{ y: [0, 12, 0] }}
                transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut', delay: 0.5 }}
                className="glass-card absolute left-6 top-6 w-44 rounded-2xl p-3 shadow-xl border border-white/80 bg-white/90 backdrop-blur-md"
              >
                <p className="text-[10px] font-semibold text-slate-400">Project Progress</p>
                <div className="mt-2 space-y-1.5">
                  {['Foundation', 'Structure', 'Interior'].map((s, i) => (
                    <div key={s} className="flex items-center gap-2">
                      <span className={`h-2 w-2 rounded-full ${i < 2 ? 'bg-emerald-500' : 'bg-slate-200'}`} />
                      <span className="text-[10px] text-slate-600">{s}</span>
                      <span className="ml-auto text-[10px] font-semibold text-slate-900">{i < 2 ? 'Done' : 'Ongoing'}</span>
                    </div>
                  ))}
                </div>
              </motion.div>
            </div>
          </motion.div>

          {/* Right — Content */}
          <div>
            <motion.div
              initial={{ opacity: 0, x: 60 }}
              animate={inView ? { opacity: 1, x: 0 } : {}}
              transition={{ duration: 0.8 }}
            >
              <span className="mb-4 inline-flex items-center gap-2 rounded-full bg-blue-500/10 px-4 py-1.5 text-xs font-semibold text-blue-600">
                FOR HOMEOWNERS &amp; PROPERTY BUILDERS
              </span>
              <h2 className="mt-3 font-display text-3xl font-extrabold leading-tight tracking-tight text-slate-900 sm:text-4xl lg:text-5xl">
                Total Control Over Your Construction Project From Day One
              </h2>
              <p className="mt-4 text-base text-slate-600">
                No hidden costs. No unexplained delays. Full transparency at every stage.
              </p>
            </motion.div>

            <div className="mt-8 grid gap-4 sm:grid-cols-2">
              {features.map((feature, i) => (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 30 }}
                  animate={inView ? { opacity: 1, y: 0 } : {}}
                  transition={{ duration: 0.5, delay: 0.3 + i * 0.1 }}
                  whileHover={{ y: -4 }}
                  className="group flex flex-col gap-3 rounded-2xl border border-slate-100 bg-white p-4 shadow-sm transition-all hover:shadow-lg hover:border-blue-200"
                >
                  <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ${feature.accent} shadow-lg transition-transform group-hover:scale-110 group-hover:rotate-6`}>
                    <feature.icon className="h-5 w-5 text-white" strokeWidth={2} />
                  </div>
                  <div>
                    <h3 className="font-display text-sm font-bold text-slate-900">{feature.title}</h3>
                    <p className="mt-1 text-xs leading-relaxed text-slate-500">{feature.desc}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
