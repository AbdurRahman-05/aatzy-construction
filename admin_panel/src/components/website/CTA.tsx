'use client';

import { motion } from 'framer-motion';
import { Download } from 'lucide-react';
import { useInView } from '../../hooks/useInView';
import { RippleButton } from './RippleButton';

interface CTAProps {
  onNavigate: (target: string) => void;
}

export function CTA({ onNavigate }: CTAProps) {
  const { ref, inView } = useInView({ threshold: 0.2 });

  return (
    <section ref={ref} className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={inView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 0.7 }}
          className="relative overflow-hidden rounded-[2.5rem] bg-gradient-to-br from-primary via-primary-800 to-primary-900 px-6 py-16 text-center shadow-2xl sm:px-12 sm:py-20"
        >
          {/* Animated background */}
          <div className="pointer-events-none absolute inset-0 bg-grid-dark opacity-30" />
          <div className="pointer-events-none absolute left-1/4 top-0 h-72 w-72 rounded-full bg-accent/20 blur-[100px]" />
          <div className="pointer-events-none absolute right-1/4 bottom-0 h-72 w-72 rounded-full bg-accent-2/20 blur-[100px]" />

          {/* Floating particles */}
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="pointer-events-none absolute h-2 w-2 rounded-full bg-accent-2/40"
              style={{ left: `${15 + i * 15}%`, top: `${20 + (i % 3) * 25}%` }}
              animate={{ y: [0, -25, 0], opacity: [0.3, 0.7, 0.3] }}
              transition={{ duration: 4 + i, repeat: Infinity, delay: i * 0.3 }}
            />
          ))}

          <div className="relative">
            <h2 className="font-display text-3xl font-extrabold leading-tight tracking-tight text-white sm:text-4xl lg:text-5xl">
              Ready to Transform Your
              <br />
              <span className="gradient-text">Construction Experience?</span>
            </h2>
            <p className="mx-auto mt-5 max-w-2xl text-base text-primary-300">
              Join thousands of homeowners, contractors, and suppliers already building smarter with Aatzy.
            </p>

            <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.98 }}>
                <RippleButton
                  variant="primary"
                  onClick={() => onNavigate('download')}
                  className="group bg-gradient-to-r from-accent to-accent-2 px-8 py-4 text-base shadow-xl shadow-accent/30"
                >
                  <Download className="h-5 w-5 transition-transform group-hover:translate-y-0.5" />
                  Download Mobile App
                </RippleButton>
              </motion.div>
            </div>

            <p className="mt-6 text-xs text-primary-400">
              Free to download · No credit card required · Available on Google Play
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
