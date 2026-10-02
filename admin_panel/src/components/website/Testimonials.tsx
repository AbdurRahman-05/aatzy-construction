'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Quote, Star, ChevronLeft, ChevronRight } from 'lucide-react';
import { useInView } from '../../hooks/useInView';
import { RippleButton } from './RippleButton';

const testimonials = [
  {
    quote: 'Connectzy saved us over ₹3.5 Lakhs on our home construction.',
    detail: 'The cost estimator provided an accurate baseline before we even spoke to contractors. Being able to track daily photo logs while living in another city gave us complete confidence.',
    name: 'Ramesh K.',
    role: 'Homeowner & Property Developer',
    location: 'Bengaluru',
    rating: 5,
  },
  {
    quote: 'Our material inquiries doubled within 30 days of joining.',
    detail: 'Listing our cement and steel products on Connectzy allowed us to reach verified builders directly. The automated PDF quotation feature makes managing sales effortless.',
    name: 'Vikram Construction Supplies',
    role: 'Authorized Material Dealer',
    location: 'Chennai',
    rating: 5,
  },
  {
    quote: 'The most transparent construction experience we have ever had.',
    detail: 'From budget estimation to final handover, every single rupee was accounted for. The milestone tracking with photo proof meant we always knew exactly where our money was going.',
    name: 'Priya & Arjun S.',
    role: 'Homeowners',
    location: 'Hyderabad',
    rating: 5,
  },
];

interface TestimonialsProps {
  onNavigate: (target: string) => void;
}

export function Testimonials({ onNavigate }: TestimonialsProps) {
  const { ref, inView } = useInView({ threshold: 0.2 });
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);

  const next = useCallback(() => setIndex((i) => (i + 1) % testimonials.length), []);
  const prev = useCallback(() => setIndex((i) => (i - 1 + testimonials.length) % testimonials.length), []);

  useEffect(() => {
    if (!inView || paused) return;
    const interval = setInterval(next, 5000);
    return () => clearInterval(interval);
  }, [inView, paused, next]);

  return (
    <section
      ref={ref}
      className="relative overflow-hidden bg-gradient-to-b from-white to-primary-50 py-20 sm:py-28"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
    >
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-20" />
      <div className="pointer-events-none absolute left-1/4 top-1/4 h-72 w-72 rounded-full bg-accent/10 blur-[100px]" />
      <div className="pointer-events-none absolute right-1/4 bottom-1/4 h-72 w-72 rounded-full bg-accent-2/10 blur-[100px]" />

      <div className="relative mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-12 text-center"
        >
          <span className="glass mb-4 inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-xs font-semibold text-accent">
            TESTIMONIALS
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight text-primary sm:text-4xl lg:text-5xl">
            Trusted by Homeowners & Businesses Alike
          </h2>
        </motion.div>

        <div className="relative">
          <AnimatePresence mode="wait">
            <motion.div
              key={index}
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: -20 }}
              transition={{ duration: 0.4 }}
              className="glass-card relative rounded-3xl p-8 text-center shadow-xl sm:p-12"
            >
              <Quote className="mx-auto mb-6 h-12 w-12 text-accent/20" fill="currentColor" />

              <div className="mb-4 flex justify-center gap-1">
                {[...Array(testimonials[index].rating)].map((_, i) => (
                  <motion.span
                    key={i}
                    initial={{ opacity: 0, scale: 0 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: i * 0.1 }}
                  >
                    <Star className="h-5 w-5 text-warning" fill="currentColor" />
                  </motion.span>
                ))}
              </div>

              <p className="font-display text-xl font-bold leading-relaxed text-primary sm:text-2xl">
                &ldquo;{testimonials[index].quote}&rdquo;
              </p>
              <p className="mx-auto mt-4 max-w-2xl text-sm leading-relaxed text-primary-500">
                {testimonials[index].detail}
              </p>

              <div className="mt-6 flex items-center justify-center gap-3">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-accent to-accent-2 font-display text-lg font-bold text-white">
                  {testimonials[index].name.charAt(0)}
                </div>
                <div className="text-left">
                  <p className="font-display text-sm font-bold text-primary">{testimonials[index].name}</p>
                  <p className="text-xs text-primary-400">
                    {testimonials[index].role} · {testimonials[index].location}
                  </p>
                </div>
              </div>
            </motion.div>
          </AnimatePresence>

          {/* Controls */}
          <div className="mt-8 flex items-center justify-center gap-4">
            <button
              onClick={prev}
              className="flex h-10 w-10 items-center justify-center rounded-full border border-primary-200 bg-white text-primary-600 transition-all hover:border-accent hover:text-accent hover:shadow-lg"
              aria-label="Previous testimonial"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>

            <div className="flex gap-2">
              {testimonials.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setIndex(i)}
                  className={`h-2 rounded-full transition-all ${i === index ? 'w-8 bg-accent' : 'w-2 bg-primary-200'}`}
                  aria-label={`Go to testimonial ${i + 1}`}
                />
              ))}
            </div>

            <button
              onClick={next}
              className="flex h-10 w-10 items-center justify-center rounded-full border border-primary-200 bg-white text-primary-600 transition-all hover:border-accent hover:text-accent hover:shadow-lg"
              aria-label="Next testimonial"
            >
              <ChevronRight className="h-5 w-5" />
            </button>
          </div>

          {/* Read more */}
          <div className="mt-6 flex justify-center gap-3">
            <RippleButton variant="secondary" onClick={() => onNavigate('about')} className="text-sm">
              Read More Stories
            </RippleButton>
          </div>
        </div>
      </div>
    </section>
  );
}
