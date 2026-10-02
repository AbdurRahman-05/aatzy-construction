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
import { useInView } from '../../hooks/useInView';

const screens = [
  {
    icon: Calculator,
    title: 'Cost Estimator',
    subtitle: 'Instant budget calculation',
    color: 'from-accent to-accent-2',
  },
  {
    icon: Camera,
    title: 'Construction Progress',
    subtitle: 'Daily photo verification',
    color: 'from-accent-2 to-success',
  },
  {
    icon: Package,
    title: 'Material Orders',
    subtitle: 'Direct B2B purchasing',
    color: 'from-warning to-accent-2',
  },
  {
    icon: MessageSquare,
    title: 'Vendor Chat',
    subtitle: 'Real-time messaging',
    color: 'from-success to-accent',
  },
  {
    icon: FileText,
    title: 'Invoice Screen',
    subtitle: 'Professional PDF invoicing',
    color: 'from-accent to-accent-2',
  },
];

export function AppShowcase() {
  const { ref, inView } = useInView({ threshold: 0.2 });
  const [active, setActive] = useState(0);

  useEffect(() => {
    if (!inView) return;
    const interval = setInterval(() => {
      setActive((prev) => (prev + 1) % screens.length);
    }, 2800);
    return () => clearInterval(interval);
  }, [inView]);

  return (
    <section ref={ref} className="relative overflow-hidden bg-gradient-to-b from-primary-50 to-white py-12 sm:py-16">
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-20" />
      <div className="pointer-events-none absolute left-1/2 top-1/2 h-[400px] w-[400px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-accent/10 blur-[100px]" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-center gap-8 lg:gap-12 lg:grid-cols-2">
          {/* Left — Content */}
          <div>
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6 }}
            >
              <span className="glass mb-4 inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-xs font-semibold text-accent">
                MOBILE APP
              </span>
              <h2 className="font-display text-3xl font-extrabold tracking-tight text-primary sm:text-4xl lg:text-4xl">
                Your Entire Construction Project in Your Pocket
              </h2>
              <p className="mt-4 text-base text-primary-600">
                From cost estimation to material ordering to daily site monitoring — manage every aspect of your build from a single, beautifully designed mobile app.
              </p>
            </motion.div>

            {/* Screen list */}
            <div className="mt-6 space-y-2">
              {screens.map((screen, i) => (
                <motion.button
                  key={screen.title}
                  initial={{ opacity: 0, x: -30 }}
                  animate={inView ? { opacity: 1, x: 0 } : {}}
                  transition={{ duration: 0.4, delay: 0.2 + i * 0.08 }}
                  onClick={() => setActive(i)}
                  className={`flex w-full items-center gap-4 rounded-2xl border p-3.5 text-left transition-all duration-300 ${
                    active === i
                      ? 'border-accent bg-accent/5 shadow-lg'
                      : 'border-primary-100 bg-white hover:border-accent/30'
                  }`}
                >
                  <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ${screen.color} shadow-md transition-transform ${active === i ? 'scale-110' : ''}`}>
                    <screen.icon className="h-4 w-4 text-white" />
                  </div>
                  <div className="flex-1">
                    <p className={`text-sm font-bold transition-colors ${active === i ? 'text-accent' : 'text-primary'}`}>{screen.title}</p>
                    <p className="text-[11px] text-primary-400">{screen.subtitle}</p>
                  </div>
                  {active === i && (
                    <motion.div layoutId="app-active" className="h-2 w-2 rounded-full bg-accent" />
                  )}
                </motion.button>
              ))}
            </div>
          </div>

          {/* Right — Phone mockup */}
          <motion.div
            initial={{ opacity: 0, scale: 0.85 }}
            animate={inView ? { opacity: 1, scale: 1 } : {}}
            transition={{ duration: 0.8 }}
            className="relative flex items-center justify-center"
          >
            {/* Background circles */}
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 30, repeat: Infinity, ease: 'linear' }}
              className="absolute h-[380px] w-[380px] rounded-full border border-dashed border-accent/20"
            />
            <motion.div
              animate={{ rotate: -360 }}
              transition={{ duration: 40, repeat: Infinity, ease: 'linear' }}
              className="absolute h-[300px] w-[300px] rounded-full border border-dashed border-accent-2/20"
            />

            {/* Phone frame */}
            <motion.div
              animate={{ y: [0, -12, 0], rotate: [0, 1.5, 0] }}
              transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
              className="relative h-[480px] w-[240px] rounded-[2.5rem] border-[8px] border-primary-900 bg-primary-900 shadow-2xl"
            >
              {/* Notch */}
              <div className="absolute left-1/2 top-0 z-20 h-5 w-28 -translate-x-1/2 rounded-b-xl bg-primary-900" />

              {/* Screen */}
              <div className="relative h-full w-full overflow-hidden rounded-[2rem] bg-gradient-to-b from-primary-50 to-white">
                <AnimatePresence mode="wait">
                  <motion.div
                    key={active}
                    initial={{ opacity: 0, x: 50 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -50 }}
                    transition={{ duration: 0.4 }}
                    className="flex h-full flex-col p-4 pt-10"
                  >
                    {/* Status bar */}
                    <div className="mb-3 flex items-center justify-between text-[8px] font-semibold text-primary-400">
                      <span>9:41</span>
                      <span>AATZY</span>
                      <span>100%</span>
                    </div>

                    {/* App header */}
                    <div className="mb-3 flex items-center gap-2">
                      <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-gradient-to-br from-accent to-accent-2">
                        <Building2 className="h-4 w-4 text-white" />
                      </div>
                      <div>
                        <p className="text-[10px] font-bold text-primary">{screens[active].title}</p>
                        <p className="text-[8px] text-primary-400">{screens[active].subtitle}</p>
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
                    <div className="mt-3 flex justify-around rounded-2xl bg-white p-2 shadow-sm">
                      {screens.slice(0, 5).map((s, i) => (
                        <button
                          key={s.title}
                          onClick={() => setActive(i)}
                          className={`flex flex-col items-center gap-0.5 transition-colors ${active === i ? 'text-accent' : 'text-primary-300'}`}
                        >
                          <s.icon className="h-4 w-4" />
                          <span className="text-[6px] font-medium">{s.title.split(' ')[0]}</span>
                        </button>
                      ))}
                    </div>
                  </motion.div>
                </AnimatePresence>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function EstimatorScreen() {
  return (
    <div className="space-y-2">
      <div className="rounded-xl bg-accent/10 p-3">
        <p className="text-[8px] text-primary-500">Total Estimate</p>
        <p className="font-display text-xl font-extrabold text-accent">₹24,30,000</p>
      </div>
      <div className="space-y-1.5">
        {['Foundation', 'Structure', 'Interior'].map((s) => (
          <div key={s} className="flex items-center justify-between rounded-lg bg-white p-2 shadow-sm">
            <span className="text-[8px] font-medium text-primary-600">{s}</span>
            <span className="text-[8px] font-bold text-primary">₹6.5L</span>
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
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-gradient-to-br from-primary-100 to-primary-200">
            <Building2 className="h-5 w-5 text-primary-400" />
          </div>
          <div className="flex-1">
            <p className="text-[8px] font-bold text-primary">Day {n * 5}</p>
            <p className="text-[7px] text-primary-400">Foundation update</p>
            <div className="mt-1 h-1 rounded-full bg-primary-100">
              <div className="h-1 w-3/4 rounded-full bg-gradient-to-r from-accent to-accent-2" />
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
            <p className="text-[9px] font-bold text-primary">{item.name}</p>
            <p className="text-[7px] text-primary-400">{item.qty}</p>
          </div>
          <span className="text-[9px] font-bold text-accent">{item.price}</span>
        </div>
      ))}
    </div>
  );
}

function ChatScreen() {
  return (
    <div className="space-y-2">
      <div className="ml-auto max-w-[75%] rounded-2xl rounded-tr-sm bg-gradient-to-br from-accent to-accent-2 p-2.5 text-white">
        <p className="text-[8px]">Hi, I need a quote for 1800 sq ft house</p>
      </div>
      <div className="max-w-[75%] rounded-2xl rounded-tl-sm bg-white p-2.5 shadow-sm">
        <p className="text-[8px] text-primary-600">Sure! I will send the estimate by evening.</p>
      </div>
      <div className="ml-auto max-w-[75%] rounded-2xl rounded-tr-sm bg-gradient-to-br from-accent to-accent-2 p-2.5 text-white">
        <p className="text-[8px]">Perfect, thank you!</p>
      </div>
    </div>
  );
}

function InvoiceScreen() {
  return (
    <div className="space-y-2">
      <div className="rounded-xl bg-primary p-3 text-white">
        <div className="flex items-center justify-between">
          <span className="text-[8px] text-primary-300">Invoice #AATZY-1024</span>
          <FileText className="h-3 w-3 text-accent-2" />
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
            <span className="text-[8px] text-primary-500">{row.label}</span>
            <span className="text-[8px] font-bold text-primary">{row.value}</span>
          </div>
        ))}
      </div>
      <div className="flex items-center gap-1 rounded-xl bg-success/10 p-2">
        <TrendingUp className="h-3 w-3 text-success" />
        <span className="text-[8px] font-semibold text-success">Payment received</span>
      </div>
    </div>
  );
}
