'use client';

import { motion } from 'framer-motion';
import { Download, Calculator, CheckCircle2, ShieldCheck, ArrowRight, Sparkles } from 'lucide-react';
import { RippleButton } from './RippleButton';
import { MobileAppMockup } from './MobileAppMockup';

interface HeroProps {
  onNavigate: (target: string) => void;
}

export function Hero({ onNavigate }: HeroProps) {
  const scrollToEstimator = () => {
    onNavigate('estimator');
    setTimeout(() => {
      const firstInput = document.querySelector('[data-estimator-focus]') as HTMLElement;
      firstInput?.focus();
    }, 600);
  };

  return (
    <section
      id="hero"
      className="relative min-h-[calc(100vh-70px)] flex items-center overflow-hidden bg-gradient-to-b from-slate-50 via-white to-slate-50 pt-24 lg:pt-28 pb-12"
    >
      {/* Ambient background glows */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute inset-0 bg-grid opacity-30" />
        <div className="absolute -left-40 top-20 h-96 w-96 rounded-full bg-blue-600/10 blur-[130px]" />
        <div className="absolute -right-40 top-32 h-96 w-96 rounded-full bg-indigo-500/10 blur-[130px]" />
        <div className="absolute left-1/2 top-1/2 h-[500px] w-[500px] -translate-x-1/2 rounded-full bg-gradient-to-br from-blue-600/10 to-sky-400/10 blur-[120px]" />
      </div>

      <div className="relative mx-auto grid w-full max-w-7xl items-center gap-10 lg:gap-14 px-4 sm:px-6 lg:grid-cols-12 lg:px-8">
        {/* Left Content (7 cols on lg) */}
        <div className="flex flex-col items-start z-10 lg:col-span-7">
          {/* Top Pill Announcement */}
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4 }}
            className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-blue-50 border border-blue-200 text-blue-800 text-xs font-bold mb-5 shadow-sm"
          >
            <span className="flex h-2 w-2 rounded-full bg-blue-600 animate-pulse" />
            <span>Connectzy Construction Mobile App v2.4</span>
            <span className="text-slate-300">|</span>
            <span className="text-blue-600 font-extrabold flex items-center gap-1">
              Google Play Ready <Sparkles className="w-3 h-3 text-amber-500" />
            </span>
          </motion.div>

          {/* Headline */}
          <h1 className="font-display text-4xl sm:text-5xl lg:text-[3.6rem] font-extrabold leading-[1.12] tracking-tight text-slate-900 max-w-2xl text-balance">
            <motion.span
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="block"
            >
              Build Smarter.
            </motion.span>
            <motion.span
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="block mt-1 sm:mt-1.5"
            >
              Source Direct.
            </motion.span>
            <motion.span
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              className="block mt-1 sm:mt-1.5 bg-gradient-to-r from-blue-600 via-indigo-600 to-sky-600 bg-clip-text text-transparent pb-1"
            >
              Track Every Milestone Live.
            </motion.span>
          </h1>

          {/* Subheadline matching app value proposition */}
          <motion.p
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.4 }}
            className="mt-5 max-w-xl text-base sm:text-lg leading-relaxed text-slate-600 font-medium text-balance"
          >
            India’s unified construction platform connecting homeowners with 500+ verified
            contractors & engineers, direct factory raw materials (Cement, TMT Steel, AAC blocks),
            instant AI cost estimation, and daily photographic milestone verification.
          </motion.p>

          {/* Key Trust Pillars */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.45 }}
            className="mt-6 grid grid-cols-2 sm:grid-cols-2 gap-2.5 w-full max-w-lg text-xs font-bold text-slate-700"
          >
            <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-100/70 border border-slate-200">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" />
              <span>45+ Construction Trade Categories</span>
            </div>
            <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-100/70 border border-slate-200">
              <ShieldCheck className="w-4 h-4 text-blue-600 flex-shrink-0" />
              <span>Daily On-Site Photo Verification</span>
            </div>
            <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-100/70 border border-slate-200">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" />
              <span>Wholesale Factory Raw Materials</span>
            </div>
            <div className="flex items-center gap-2 p-2.5 rounded-xl bg-slate-100/70 border border-slate-200">
              <ShieldCheck className="w-4 h-4 text-blue-600 flex-shrink-0" />
              <span>Escrow Safe Stage Payments</span>
            </div>
          </motion.div>

          {/* CTA Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.5 }}
            className="mt-8 flex flex-col sm:flex-row gap-3.5 w-full sm:w-auto"
          >
            <RippleButton
              variant="primary"
              onClick={() => onNavigate('download')}
              className="group px-8 py-4 w-full sm:w-auto justify-center text-sm sm:text-base font-extrabold shadow-xl shadow-blue-600/30"
            >
              <Download className="h-5 w-5 transition-transform group-hover:translate-y-0.5" />
              Download Android App
            </RippleButton>

            <RippleButton
              variant="secondary"
              onClick={scrollToEstimator}
              className="group px-7 py-4 w-full sm:w-auto justify-center text-sm sm:text-base font-bold border border-slate-300 shadow-sm bg-white hover:bg-slate-50"
            >
              <Calculator className="h-5 w-5 text-blue-600" />
              Instant Cost Calculator
            </RippleButton>

            <button
              type="button"
              onClick={() => onNavigate('services-directory')}
              className="inline-flex items-center justify-center gap-1.5 px-5 py-4 text-sm font-bold text-slate-700 hover:text-blue-600 transition cursor-pointer"
            >
              <span>Explore 45+ Trades</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </motion.div>
        </div>

        {/* Right Mobile Phone Showcase (5 cols on lg) */}
        <motion.div
          initial={{ opacity: 0, scale: 0.92 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.7, delay: 0.3 }}
          className="relative lg:col-span-5 flex items-center justify-center"
        >
          <MobileAppMockup />
        </motion.div>
      </div>
    </section>
  );
}
