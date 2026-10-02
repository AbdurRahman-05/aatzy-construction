'use client';

import { motion } from 'framer-motion';
import { Download, Sparkles, ShieldCheck, ArrowRight } from 'lucide-react';
import { useInView } from '../../hooks/useInView';
import { RippleButton } from './RippleButton';

interface CTAProps {
  onNavigate: (target: string) => void;
}

export function CTA({ onNavigate }: CTAProps) {
  const { ref, inView } = useInView({ threshold: 0.2 });

  return (
    <section ref={ref} className="relative overflow-hidden py-20 sm:py-28 bg-white">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={inView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 0.7 }}
          className="relative overflow-hidden rounded-[2.5rem] bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 px-6 py-16 text-center shadow-2xl sm:px-12 sm:py-20 border border-slate-800"
        >
          {/* Animated background */}
          <div className="pointer-events-none absolute inset-0 bg-grid-dark opacity-30" />
          <div className="pointer-events-none absolute left-1/4 top-0 h-72 w-72 rounded-full bg-blue-600/20 blur-[100px]" />
          <div className="pointer-events-none absolute right-1/4 bottom-0 h-72 w-72 rounded-full bg-sky-500/20 blur-[100px]" />

          {/* Floating particles */}
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="pointer-events-none absolute h-2 w-2 rounded-full bg-sky-400/40"
              style={{ left: `${15 + i * 15}%`, top: `${20 + (i % 3) * 25}%` }}
              animate={{ y: [0, -25, 0], opacity: [0.3, 0.7, 0.3] }}
              transition={{ duration: 4 + i, repeat: Infinity, delay: i * 0.3 }}
            />
          ))}

          <div className="relative max-w-3xl mx-auto">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-900/60 text-sky-400 text-xs font-black tracking-wider uppercase border border-blue-700/60 mb-4">
              <Sparkles className="w-3.5 h-3.5 text-amber-400" /> Start Building with Confidence
            </span>

            <h2 className="font-display text-3xl font-extrabold leading-tight tracking-tight text-white sm:text-4xl lg:text-5xl">
              Ready to Transform Your
              <br />
              <span className="bg-gradient-to-r from-blue-400 via-sky-300 to-indigo-200 bg-clip-text text-transparent">
                Construction Experience?
              </span>
            </h2>
            <p className="mx-auto mt-5 max-w-2xl text-base text-slate-300 leading-relaxed">
              Join thousands of homeowners, verified contractors, and building material suppliers already building smarter with Connectzy Construction.
            </p>

            <div className="mt-8 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <RippleButton
                variant="primary"
                onClick={() => onNavigate('download')}
                className="group px-8 py-4 text-base font-extrabold shadow-xl shadow-blue-500/30 w-full sm:w-auto justify-center"
              >
                <Download className="h-5 w-5 transition-transform group-hover:translate-y-0.5" />
                Download Android Mobile App
              </RippleButton>

              <button
                type="button"
                onClick={() => onNavigate('estimator')}
                className="px-7 py-4 rounded-full border border-slate-700 bg-slate-800/80 hover:bg-slate-800 text-white font-bold text-sm sm:text-base transition w-full sm:w-auto cursor-pointer"
              >
                Instant Cost Calculator
              </button>
            </div>

            <div className="mt-8 flex flex-wrap items-center justify-center gap-6 text-xs text-slate-400 font-semibold">
              <span className="flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-emerald-400" /> 100% Free to Download
              </span>
              <span>·</span>
              <span>Available for Android (v2.4)</span>
              <span>·</span>
              <span>Google Play Compatible</span>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
