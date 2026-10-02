'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Briefcase,
  Calculator,
  Users,
  Store,
  MessageSquareCheck,
  CheckCircle2,
  Sparkles,
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';

const slides = [
  {
    icon: Briefcase,
    category: 'PROJECT HUB',
    title: 'Post Projects & Get Verified Bids',
    subtitle: 'Publish building, remodeling or interior projects',
    bullets: [
      'Post custom project details with budget & target timeline',
      'Receive itemized proposals from verified local contractors',
      'Select and hire the best specialist for your exact budget',
    ],
    image: '/assets/tutorial_1.png',
    tag: 'TUTORIAL 01',
  },
  {
    icon: Calculator,
    category: 'SMART CALCULATOR',
    title: 'Instant Cost & Material Estimator',
    subtitle: 'Accurate budgets & material consumption estimates',
    bullets: [
      'Estimate total costs for House, Villa, Apartment, Office & Warehouse',
      'Calculate exact cement bags, steel MT, bricks & sand quantities',
      'Prevent cost overruns with live benchmark engineering rates',
    ],
    image: '/assets/tutorial_2.png',
    tag: 'TUTORIAL 02',
  },
  {
    icon: Users,
    category: 'TRUSTED EXPERTS',
    title: 'Browse 45+ Verified Trade Specialists',
    subtitle: 'Certified contractors, architects & interior designers',
    bullets: [
      'Inspect contractor portfolios, past work photos & GST credentials',
      'Read authentic client star ratings and completed project reviews',
      'Connect directly via one-tap call or encrypted in-app messaging',
    ],
    image: '/assets/tutorial_3.png',
    tag: 'TUTORIAL 03',
  },
  {
    icon: Store,
    category: 'B2B MARKETPLACE',
    title: 'Wholesale Building Materials Store',
    subtitle: 'Direct factory procurement for Cement, TMT Steel & Bricks',
    bullets: [
      'Browse verified brands (Ultratech, Tata Tiscon, JSW, Finolex)',
      'Submit bulk inquiry RFQs for discounted factory wholesale quotes',
      'Track raw material transit and dispatch delivery status in real-time',
    ],
    image: '/assets/tutorial_4.png',
    tag: 'TUTORIAL 04',
  },
  {
    icon: MessageSquareCheck,
    category: 'SITE AUDITING',
    title: 'Compare Quotes, Milestone Photos & Chat',
    subtitle: 'Full transparency and escrow stage payments',
    bullets: [
      'Side-by-side bidder quotation breakdown for maximum transparency',
      'Daily on-site photo proofs uploaded before stage payments release',
      'Direct in-app negotiations and progress updates with your contractor',
    ],
    image: '/assets/tutorial_5.png',
    tag: 'TUTORIAL 05',
  },
];

export function AppShowcase() {
  const { ref, inView } = useInView({ threshold: 0.2 });
  const [active, setActive] = useState(0);

  useEffect(() => {
    if (!inView) return;
    const interval = setInterval(() => {
      setActive((prev) => (prev + 1) % slides.length);
    }, 4200);
    return () => clearInterval(interval);
  }, [inView]);

  return (
    <section ref={ref} className="relative overflow-hidden bg-slate-900 py-20 sm:py-24 text-white">
      <div className="pointer-events-none absolute inset-0 bg-grid-dark opacity-30" />
      <div className="pointer-events-none absolute left-1/2 top-1/2 h-[500px] w-[500px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-blue-600/10 blur-[130px]" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-center gap-12 lg:gap-16 lg:grid-cols-12">
          {/* Left — Interactive Features List (7 cols) */}
          <div className="lg:col-span-7">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6 }}
            >
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-950 text-blue-400 text-xs font-black tracking-wider uppercase border border-blue-800">
                <Sparkles className="w-3.5 h-3.5 text-amber-400" /> Real App Experience
              </span>
              <h2 className="mt-3 font-display text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight text-white leading-tight">
                Everything Construction. <br />
                <span className="bg-gradient-to-r from-blue-400 via-sky-400 to-indigo-300 bg-clip-text text-transparent">
                  In One Unified App.
                </span>
              </h2>
              <p className="mt-4 text-base sm:text-lg text-slate-300 leading-relaxed">
                Take a guided look through the actual core modules powering the Connectzy Construction mobile app.
              </p>
            </motion.div>

            {/* Slide Navigation List */}
            <div className="mt-8 space-y-3">
              {slides.map((slide, i) => {
                const IconComponent = slide.icon;
                const isSelected = active === i;
                return (
                  <motion.button
                    key={slide.title}
                    initial={{ opacity: 0, x: -20 }}
                    animate={inView ? { opacity: 1, x: 0 } : {}}
                    transition={{ duration: 0.3, delay: i * 0.08 }}
                    onClick={() => setActive(i)}
                    className={`w-full text-left p-4 rounded-2xl border transition-all duration-300 cursor-pointer ${
                      isSelected
                        ? 'border-blue-500 bg-blue-950/60 shadow-lg shadow-blue-500/20'
                        : 'border-slate-800 bg-slate-800/40 hover:border-slate-700 hover:bg-slate-800/70'
                    }`}
                  >
                    <div className="flex items-start gap-4">
                      <div
                        className={`p-2.5 rounded-xl transition ${
                          isSelected
                            ? 'bg-blue-600 text-white shadow-md shadow-blue-500/30'
                            : 'bg-slate-800 text-slate-400'
                        }`}
                      >
                        <IconComponent className="w-5 h-5" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center justify-between mb-1">
                          <span
                            className={`text-[10px] font-black uppercase tracking-wider ${
                              isSelected ? 'text-sky-400' : 'text-slate-400'
                            }`}
                          >
                            {slide.category}
                          </span>
                          <span className="text-[10px] text-slate-400 font-bold">{slide.tag}</span>
                        </div>
                        <h3 className="font-extrabold text-base text-white">{slide.title}</h3>
                        <p className="text-xs text-slate-400 mt-0.5">{slide.subtitle}</p>

                        {/* Expanded bullet details if selected */}
                        {isSelected && (
                          <motion.div
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            transition={{ duration: 0.25 }}
                            className="mt-3 pt-3 border-t border-blue-900/60 space-y-1.5"
                          >
                            {slide.bullets.map((b, bIdx) => (
                              <div key={bIdx} className="flex items-center gap-2 text-xs text-slate-300 font-medium">
                                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 flex-shrink-0" />
                                <span>{b}</span>
                              </div>
                            ))}
                          </motion.div>
                        )}
                      </div>
                    </div>
                  </motion.button>
                );
              })}
            </div>
          </div>

          {/* Right — Real Phone Frame Showcase (5 cols) */}
          <div className="lg:col-span-5 flex items-center justify-center">
            <div className="relative">
              {/* Outer decorative glow */}
              <div className="absolute inset-0 rounded-[3rem] bg-gradient-to-r from-blue-600 to-indigo-600 opacity-20 blur-2xl -z-10" />

              {/* Phone Mockup Frame */}
              <div className="relative h-[560px] w-[285px] sm:h-[600px] sm:w-[305px] rounded-[3.2rem] border-[10px] border-slate-800 bg-slate-950 shadow-2xl p-2 flex flex-col justify-between overflow-hidden">
                {/* Dynamic notch */}
                <div className="absolute left-1/2 top-2 z-20 h-4 w-28 -translate-x-1/2 rounded-full bg-slate-800 flex items-center justify-center">
                  <div className="h-1.5 w-1.5 rounded-full bg-slate-700 mr-2" />
                  <div className="h-2 w-8 rounded-full bg-slate-700" />
                </div>

                {/* Top Status */}
                <div className="pt-6 px-3 flex items-center justify-between text-[9px] font-bold text-slate-400 z-10">
                  <span>9:41</span>
                  <span className="text-slate-300 font-extrabold">CONNECTZY</span>
                  <span>5G 100%</span>
                </div>

                {/* Display Screen */}
                <div className="relative flex-1 my-2 rounded-2xl overflow-hidden bg-slate-900 flex items-center justify-center border border-slate-800">
                  <AnimatePresence mode="wait">
                    <motion.div
                      key={active}
                      initial={{ opacity: 0, scale: 0.95 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 1.05 }}
                      transition={{ duration: 0.35 }}
                      className="h-full w-full flex items-center justify-center p-1.5"
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={slides[active].image}
                        alt={slides[active].title}
                        className="h-full w-full object-contain rounded-xl"
                      />
                    </motion.div>
                  </AnimatePresence>
                </div>

                {/* Screen Caption Tag */}
                <div className="bg-slate-900/90 rounded-xl p-2 text-center border border-slate-800">
                  <p className="text-[10px] font-black text-white leading-tight">{slides[active].title}</p>
                  <p className="text-[8px] text-blue-400 font-bold uppercase mt-0.5">{slides[active].category}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
