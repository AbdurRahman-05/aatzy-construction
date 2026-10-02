'use client';

import { useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { Download, Calculator } from 'lucide-react';
import { RippleButton } from './RippleButton';
import { MobileAppMockup } from './MobileAppMockup';

interface HeroProps {
  onNavigate: (target: string) => void;
}

export function Hero({ onNavigate }: HeroProps) {
  const heroRef = useRef<HTMLDivElement>(null);
  const mouseX = useRef(0);
  const mouseY = useRef(0);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const el = heroRef.current;
      if (!el) return;
      const rect = el.getBoundingClientRect();
      mouseX.current = (e.clientX - rect.left) / rect.width - 0.5;
      mouseY.current = (e.clientY - rect.top) / rect.height - 0.5;
      el.style.setProperty('--mx', `${mouseX.current * 30}px`);
      el.style.setProperty('--my', `${mouseY.current * 30}px`);
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  const scrollToEstimator = () => {
    onNavigate('estimator');
    setTimeout(() => {
      const firstInput = document.querySelector('[data-estimator-focus]') as HTMLElement;
      firstInput?.focus();
    }, 800);
  };

  return (
    <section
      ref={heroRef}
      id="hero"
      className="relative min-h-[calc(100vh-80px)] flex items-center overflow-hidden bg-gradient-to-b from-slate-50 via-white to-slate-50 pt-20 lg:pt-24 pb-12"
    >
      {/* Animated background */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute inset-0 bg-grid opacity-40" />
        <div className="absolute -left-40 top-20 h-96 w-96 rounded-full bg-blue-500/15 blur-[120px]" />
        <div className="absolute -right-40 top-40 h-96 w-96 rounded-full bg-sky-400/15 blur-[120px]" />
        <div className="absolute left-1/2 top-1/2 h-[500px] w-[500px] -translate-x-1/2 rounded-full bg-gradient-to-br from-blue-600/10 to-sky-400/10 blur-[100px]" />

        {/* Floating particles */}
        {[...Array(12)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute h-2 w-2 rounded-full bg-blue-500/30"
            style={{
              left: `${(i * 83) % 100}%`,
              top: `${(i * 47) % 90}%`,
            }}
            animate={{
              y: [0, -30, 0],
              opacity: [0.2, 0.6, 0.2],
            }}
            transition={{
              duration: 4 + i * 0.3,
              repeat: Infinity,
              ease: 'easeInOut',
              delay: i * 0.2,
            }}
          />
        ))}
      </div>

      <div className="relative mx-auto grid w-full max-w-7xl items-center gap-8 lg:gap-12 px-4 sm:px-6 lg:grid-cols-2 lg:px-8">
        {/* Left content */}
        <div className="flex flex-col items-start z-10">
          {/* Headline */}
          <h1 className="font-display text-4xl sm:text-5xl lg:text-[3.5rem] font-extrabold leading-[1.1] tracking-tight text-slate-900 max-w-2xl text-balance">
            <motion.span
              initial={{ opacity: 0, y: 20, filter: 'blur(8px)' }}
              animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="block"
            >
              Build Smart.
            </motion.span>
            <motion.span
              initial={{ opacity: 0, y: 20, filter: 'blur(8px)' }}
              animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="block mt-1 sm:mt-2"
            >
              Estimate Accurately.
            </motion.span>
            <motion.span
              initial={{ opacity: 0, y: 20, filter: 'blur(8px)' }}
              animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
              transition={{ duration: 0.5, delay: 0.3 }}
              className="block mt-1 sm:mt-2 gradient-text pb-1"
            >
              Connect with Verified Construction Experts.
            </motion.span>
          </h1>

          {/* Subheadline */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.5 }}
            className="mt-4 sm:mt-6 max-w-xl text-base sm:text-lg leading-relaxed text-slate-600 font-medium text-balance"
          >
            Plan your project with our real-time cost estimator, monitor site progress with
            daily photo verification, compare multi-vendor quotations, and order raw materials
            directly from certified B2B suppliers — all in one unified app.
          </motion.p>

          {/* CTA buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.6 }}
            className="mt-6 flex flex-col gap-3 sm:flex-row w-full sm:w-auto"
          >
            <RippleButton variant="primary" onClick={() => onNavigate('download')} className="group px-8 py-4 w-full sm:w-auto justify-center text-base shadow-lg shadow-blue-600/25">
              <Download className="h-5 w-5 transition-transform group-hover:translate-y-0.5" />
              Download Android App
            </RippleButton>

            <RippleButton variant="secondary" onClick={scrollToEstimator} className="group px-7 py-4 w-full sm:w-auto justify-center text-base border border-slate-200">
              <Calculator className="h-5 w-5 text-blue-600" />
              Cost Estimator
            </RippleButton>
          </motion.div>
        </div>

        {/* Right — Animated mobile app mockup */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="relative hidden h-[500px] lg:flex items-center justify-center"
        >
          <MobileAppMockup />
        </motion.div>
      </div>

      {/* Mobile dashboard mockup */}
      <div className="relative mx-auto max-w-md px-4 pb-12 lg:hidden flex items-center justify-center">
        <MobileAppMockup />
      </div>
    </section>
  );
}
