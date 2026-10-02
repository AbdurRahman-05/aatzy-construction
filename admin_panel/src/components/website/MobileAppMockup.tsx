'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Calculator,
  Camera,
  Package,
  MessageSquare,
  FileText,
  Building2,
  TrendingUp,
} from 'lucide-react';

export const screens = [
  {
    icon: Calculator,
    title: 'Cost Estimator',
    subtitle: 'Instant budget calculation',
    color: 'from-blue-600 to-sky-400',
  },
  {
    icon: Camera,
    title: 'Construction Progress',
    subtitle: 'Daily photo verification',
    color: 'from-sky-400 to-emerald-500',
  },
  {
    icon: Package,
    title: 'Material Orders',
    subtitle: 'Direct B2B purchasing',
    color: 'from-amber-500 to-sky-400',
  },
  {
    icon: MessageSquare,
    title: 'Vendor Chat',
    subtitle: 'Real-time messaging',
    color: 'from-emerald-500 to-blue-600',
  },
  {
    icon: FileText,
    title: 'Invoice Screen',
    subtitle: 'Professional PDF invoicing',
    color: 'from-blue-600 to-sky-400',
  },
];

export function MobileAppMockup({ active: externalActive, onChange }: { active?: number, onChange?: (i: number) => void }) {
  const [internalActive, setInternalActive] = useState(0);
  
  const active = externalActive !== undefined ? externalActive : internalActive;

  useEffect(() => {
    if (externalActive !== undefined) return;
    const interval = setInterval(() => {
      setInternalActive((prev) => (prev + 1) % screens.length);
    }, 2800);
    return () => clearInterval(interval);
  }, [externalActive]);

  const handleSetActive = (i: number) => {
    if (onChange) onChange(i);
    else setInternalActive(i);
  };

  return (
    <div className="relative flex h-full w-full items-center justify-center py-8">
      {/* Background circles */}
      <motion.div
        animate={{ rotate: 360 }}
        transition={{ duration: 30, repeat: Infinity, ease: 'linear' }}
        className="absolute h-[360px] w-[360px] lg:h-[400px] lg:w-[400px] rounded-full border border-dashed border-blue-500/20"
      />
      <motion.div
        animate={{ rotate: -360 }}
        transition={{ duration: 40, repeat: Infinity, ease: 'linear' }}
        className="absolute h-[280px] w-[280px] lg:h-[320px] lg:w-[320px] rounded-full border border-dashed border-sky-400/20"
      />

      {/* Phone frame */}
      <motion.div
        animate={{ y: [0, -16, 0], rotate: [0, 1.5, 0] }}
        transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
        className="relative h-[460px] w-[230px] lg:h-[480px] lg:w-[240px] rounded-[2.5rem] border-[8px] border-slate-900 bg-slate-900 shadow-2xl"
      >
        {/* Notch */}
        <div className="absolute left-1/2 top-0 z-20 h-5 w-24 lg:h-6 lg:w-28 -translate-x-1/2 rounded-b-2xl bg-slate-900" />

        {/* Screen */}
        <div className="relative h-full w-full overflow-hidden rounded-[2rem] bg-gradient-to-b from-slate-50 to-white">
          <AnimatePresence mode="wait">
            <motion.div
              key={active}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -50 }}
              transition={{ duration: 0.4 }}
              className="flex h-full flex-col p-4 pt-8 sm:pt-10"
            >
              {/* Status bar */}
              <div className="mb-3 flex items-center justify-between text-[8px] font-semibold text-slate-400">
                <span>9:41</span>
                <span>CONNECTZY</span>
                <span>100%</span>
              </div>

              {/* App header */}
              <div className="mb-3 flex items-center gap-2">
                <div className={`flex h-7 w-7 items-center justify-center rounded-lg bg-gradient-to-br ${screens[active].color}`}>
                  {(() => {
                    const Icon = screens[active].icon;
                    return <Icon className="h-4 w-4 text-white" />;
                  })()}
                </div>
                <div>
                  <p className="text-[10px] font-bold text-slate-900">{screens[active].title}</p>
                  <p className="text-[8px] text-slate-400">{screens[active].subtitle}</p>
                </div>
              </div>

              {/* Screen content */}
              <div className="flex-1 space-y-3">
                {active === 0 && <EstimatorScreen />}
                {active === 1 && <ProgressScreen />}
                {active === 2 && <OrdersScreen />}
                {active === 3 && <ChatScreen />}
                {active === 4 && <InvoiceScreen />}
              </div>

              {/* Bottom nav */}
              <div className="mt-3 flex justify-around rounded-2xl bg-white p-2 shadow-sm z-10 relative">
                {screens.slice(0, 5).map((s, i) => {
                  const Icon = s.icon;
                  return (
                    <button
                      key={s.title}
                      onClick={() => handleSetActive(i)}
                      className={`flex flex-col items-center gap-0.5 transition-colors ${active === i ? 'text-blue-600' : 'text-slate-300'}`}
                    >
                      <Icon className="h-4 w-4" />
                      <span className="text-[6px] font-medium">{s.title.split(' ')[0]}</span>
                    </button>
                  );
                })}
              </div>
            </motion.div>
          </AnimatePresence>
        </div>
      </motion.div>
    </div>
  );
}

function EstimatorScreen() {
  return (
    <div className="space-y-2">
      <div className="rounded-xl bg-blue-500/10 p-3">
        <p className="text-[8px] text-slate-500">Total Estimate</p>
        <p className="font-display text-xl font-extrabold text-blue-600">₹24,30,000</p>
      </div>
      <div className="space-y-1.5">
        {['Foundation', 'Structure', 'Interior'].map((s) => (
          <div key={s} className="flex items-center justify-between rounded-lg bg-white p-2 shadow-sm">
            <span className="text-[8px] font-medium text-slate-600">{s}</span>
            <span className="text-[8px] font-bold text-slate-900">₹6.5L</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ProgressScreen() {
  return (
    <div className="space-y-2">
      {[1, 2, 3].map((n) => (
        <div key={n} className="flex gap-2 rounded-xl bg-white p-2 shadow-sm">
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-gradient-to-br from-slate-100 to-slate-200">
            <Building2 className="h-5 w-5 text-slate-400" />
          </div>
          <div className="flex-1">
            <p className="text-[8px] font-bold text-slate-900">Day {n * 5}</p>
            <p className="text-[7px] text-slate-400">Foundation update</p>
            <div className="mt-1 h-1 rounded-full bg-slate-100">
              <div className="h-1 w-3/4 rounded-full bg-gradient-to-r from-blue-600 to-sky-400" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function OrdersScreen() {
  return (
    <div className="space-y-2">
      {[
        { name: 'Cement', qty: '150 bags', price: '₹52,500' },
        { name: 'TMT Steel', qty: '12 tons', price: '₹78,000' },
        { name: 'Bricks', qty: '5,000 units', price: '₹35,000' },
      ].map((item) => (
        <div key={item.name} className="flex items-center justify-between rounded-xl bg-white p-2.5 shadow-sm">
          <div>
            <p className="text-[9px] font-bold text-slate-900">{item.name}</p>
            <p className="text-[7px] text-slate-400">{item.qty}</p>
          </div>
          <span className="text-[9px] font-bold text-blue-600">{item.price}</span>
        </div>
      ))}
    </div>
  );
}

function ChatScreen() {
  return (
    <div className="space-y-2">
      <div className="ml-auto max-w-[75%] rounded-2xl rounded-tr-sm bg-gradient-to-br from-blue-600 to-sky-400 p-2.5 text-white">
        <p className="text-[8px]">Hi, I need a quote for 1800 sq ft house</p>
      </div>
      <div className="max-w-[75%] rounded-2xl rounded-tl-sm bg-white p-2.5 shadow-sm">
        <p className="text-[8px] text-slate-600">Sure! I will send the estimate by evening.</p>
      </div>
      <div className="ml-auto max-w-[75%] rounded-2xl rounded-tr-sm bg-gradient-to-br from-blue-600 to-sky-400 p-2.5 text-white">
        <p className="text-[8px]">Perfect, thank you!</p>
      </div>
    </div>
  );
}

function InvoiceScreen() {
  return (
    <div className="space-y-2">
      <div className="rounded-xl bg-slate-900 p-3 text-white">
        <div className="flex items-center justify-between">
          <span className="text-[8px] text-slate-300">Invoice #CONNECTZY-1024</span>
          <FileText className="h-3 w-3 text-sky-400" />
        </div>
        <p className="mt-1 font-display text-lg font-extrabold">₹4,20,000</p>
      </div>
      <div className="space-y-1.5">
        {[
          { label: 'Materials', value: '₹2,73,000' },
          { label: 'Labor', value: '₹1,47,000' },
          { label: 'GST (18%)', value: '₹75,600' },
        ].map((row) => (
          <div key={row.label} className="flex justify-between rounded-lg bg-white p-2 shadow-sm">
            <span className="text-[8px] text-slate-400">{row.label}</span>
            <span className="text-[8px] font-bold text-slate-900">{row.value}</span>
          </div>
        ))}
      </div>
      <div className="flex items-center gap-1 rounded-xl bg-emerald-500/10 p-2">
        <TrendingUp className="h-3 w-3 text-emerald-500" />
        <span className="text-[8px] font-semibold text-emerald-500">Payment received</span>
      </div>
    </div>
  );
}
