'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Calculator,
  Briefcase,
  Store,
  Users,
  CheckCircle2,
  Sparkles,
} from 'lucide-react';

export const screens = [
  {
    icon: Briefcase,
    title: 'Post Projects & Bids',
    subtitle: 'Competitive Contractor Bids',
    color: 'from-blue-600 to-indigo-600',
    tag: 'PROJECT HUB',
    img: '/assets/tutorial_1.png',
    badge: '12 Active Bids',
  },
  {
    icon: Calculator,
    title: 'Instant Cost Calculator',
    subtitle: 'Accurate Material Quantities',
    color: 'from-emerald-600 to-teal-700',
    tag: 'ESTIMATOR',
    img: '/assets/tutorial_2.png',
    badge: '₹24.3L Budget',
  },
  {
    icon: Users,
    title: '45+ Verified Trades',
    subtitle: 'Architects, Contractors & MEP',
    color: 'from-amber-500 to-orange-600',
    tag: 'TOP EXPERTS',
    img: '/assets/tutorial_3.png',
    badge: 'GST Verified',
  },
  {
    icon: Store,
    title: 'B2B Wholesale Store',
    subtitle: 'Factory Direct Cement & Steel',
    color: 'from-purple-600 to-pink-600',
    tag: 'RAW MATERIALS',
    img: '/assets/tutorial_4.png',
    badge: 'Wholesale Rates',
  },
  {
    icon: CheckCircle2,
    title: 'Milestone Tracking & Chat',
    subtitle: 'Photo Verification & Escrow',
    color: 'from-sky-500 to-blue-700',
    tag: 'SITE AUDITING',
    img: '/assets/tutorial_5.png',
    badge: 'Stage 3 Approved',
  },
];

export function MobileAppMockup({
  active: externalActive,
  onChange,
}: {
  active?: number;
  onChange?: (i: number) => void;
}) {
  const [internalActive, setInternalActive] = useState(0);

  const active = externalActive !== undefined ? externalActive : internalActive;

  useEffect(() => {
    if (externalActive !== undefined) return;
    const interval = setInterval(() => {
      setInternalActive((prev) => (prev + 1) % screens.length);
    }, 3800);
    return () => clearInterval(interval);
  }, [externalActive]);

  const handleSetActive = (i: number) => {
    if (onChange) onChange(i);
    else setInternalActive(i);
  };

  const currentScreen = screens[active];

  return (
    <div className="relative flex h-full w-full items-center justify-center py-6 select-none">
      {/* Background glow & animated rings */}
      <motion.div
        animate={{ rotate: 360 }}
        transition={{ duration: 35, repeat: Infinity, ease: 'linear' }}
        className="absolute h-[380px] w-[380px] lg:h-[440px] lg:w-[440px] rounded-full border border-dashed border-blue-500/25 pointer-events-none"
      />
      <motion.div
        animate={{ rotate: -360 }}
        transition={{ duration: 45, repeat: Infinity, ease: 'linear' }}
        className="absolute h-[300px] w-[300px] lg:h-[340px] lg:w-[340px] rounded-full border border-dashed border-indigo-400/20 pointer-events-none"
      />

      {/* Floating status badges */}
      <motion.div
        animate={{ y: [0, -8, 0] }}
        transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
        className="absolute -top-3 -left-4 sm:left-4 z-30 flex items-center gap-2 rounded-2xl bg-white/95 px-3.5 py-2 shadow-xl border border-slate-200/80 backdrop-blur-md"
      >
        <span className="flex h-2.5 w-2.5 rounded-full bg-emerald-500 animate-pulse" />
        <div>
          <p className="text-[10px] font-extrabold text-slate-900 leading-tight">Live Milestone Photo</p>
          <p className="text-[8px] text-slate-500 font-semibold">Stage verified by client</p>
        </div>
      </motion.div>

      <motion.div
        animate={{ y: [0, 8, 0] }}
        transition={{ duration: 4.5, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
        className="absolute -bottom-2 -right-2 sm:right-6 z-30 flex items-center gap-2.5 rounded-2xl bg-white/95 px-4 py-2.5 shadow-xl border border-slate-200/80 backdrop-blur-md"
      >
        <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-amber-500 text-white font-black text-xs shadow-md shadow-amber-500/30">
          ₹
        </div>
        <div>
          <p className="text-[10px] font-extrabold text-slate-900 leading-tight">Factory Direct Rates</p>
          <p className="text-[8px] text-emerald-600 font-bold">Ultratech Cement ₹380/bag</p>
        </div>
      </motion.div>

      {/* Smartphone frame */}
      <motion.div
        animate={{ y: [0, -12, 0] }}
        transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
        className="relative h-[530px] w-[270px] sm:h-[560px] sm:w-[285px] rounded-[3rem] border-[9px] border-slate-900 bg-slate-950 shadow-[0_25px_60px_-15px_rgba(15,23,42,0.4)] overflow-hidden"
      >
        {/* Dynamic Island / Speaker Notch */}
        <div className="absolute left-1/2 top-2 z-30 h-4 w-28 -translate-x-1/2 rounded-full bg-slate-900 flex items-center justify-center">
          <div className="h-1.5 w-1.5 rounded-full bg-slate-800 mr-2" />
          <div className="h-2 w-8 rounded-full bg-slate-800" />
        </div>

        {/* Screen container */}
        <div className="relative h-full w-full overflow-hidden bg-slate-900 flex flex-col justify-between pt-7 pb-2 px-2.5">
          {/* App Status bar */}
          <div className="flex items-center justify-between text-[9px] font-bold text-slate-400 px-2 pt-1 mb-2">
            <span>9:41</span>
            <div className="flex items-center gap-1.5">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/assets/logo.png" alt="logo" className="h-3 w-auto object-contain brightness-125" />
              <span className="text-[8px] tracking-wider text-slate-300">CONNECTZY</span>
            </div>
            <div className="flex items-center gap-1 text-[8px]">
              <span>5G</span>
              <span>100%</span>
            </div>
          </div>

          {/* Current Feature Tag & Title */}
          <div className="bg-slate-800/80 rounded-2xl p-2.5 border border-slate-700/60 backdrop-blur-sm mb-2 shadow-sm">
            <div className="flex items-center justify-between mb-1">
              <span className="text-[8px] font-black uppercase tracking-wider text-blue-400 bg-blue-950/80 px-2 py-0.5 rounded-md border border-blue-800/60">
                {currentScreen.tag}
              </span>
              <span className="text-[8px] font-bold text-emerald-400 flex items-center gap-0.5">
                <Sparkles className="w-2.5 h-2.5" />
                {currentScreen.badge}
              </span>
            </div>
            <p className="text-[11px] font-black text-white leading-tight truncate">{currentScreen.title}</p>
            <p className="text-[9px] text-slate-400 truncate">{currentScreen.subtitle}</p>
          </div>

          {/* Real App Screenshot Showcase */}
          <div className="relative flex-1 rounded-2xl overflow-hidden bg-slate-950 border border-slate-800 flex items-center justify-center shadow-inner">
            <AnimatePresence mode="wait">
              <motion.div
                key={active}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 1.05 }}
                transition={{ duration: 0.35 }}
                className="h-full w-full flex items-center justify-center p-1 bg-gradient-to-b from-slate-900 to-slate-950"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={currentScreen.img}
                  alt={currentScreen.title}
                  className="h-full w-full object-contain rounded-xl"
                />
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Interactive Bottom Screen Switcher */}
          <div className="mt-2.5 bg-slate-900/90 rounded-2xl p-1.5 border border-slate-800 flex justify-between items-center">
            {screens.map((s, i) => {
              const Icon = s.icon;
              const isSelected = active === i;
              return (
                <button
                  key={s.title}
                  onClick={() => handleSetActive(i)}
                  className={`flex flex-col items-center justify-center py-1 px-1.5 rounded-xl transition-all cursor-pointer ${
                    isSelected ? 'bg-blue-600 text-white shadow-md shadow-blue-600/40' : 'text-slate-400 hover:text-slate-200'
                  }`}
                  title={s.title}
                >
                  <Icon className="h-3.5 w-3.5" />
                  <span className="text-[7px] font-extrabold mt-0.5">{i + 1}</span>
                </button>
              );
            })}
          </div>
        </div>
      </motion.div>
    </div>
  );
}
