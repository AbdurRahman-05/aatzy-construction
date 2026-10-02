'use client';

import { motion } from 'framer-motion';
import {
  Building2,
  PenTool,
  HardHat,
  Landmark,
  Home,
  Layers,
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';

const partners = [
  { name: 'BuildTech Construction', icon: Building2 },
  { name: 'ArchDesign Studio', icon: PenTool },
  { name: 'Vikram Supplies', icon: HardHat },
  { name: 'State Bank Partner', icon: Landmark },
  { name: 'PrimeReal Estate', icon: Home },
  { name: 'InfraCorp Ltd', icon: Layers },
  { name: 'SkyLine Builders', icon: Building2 },
  { name: 'MaterialHub', icon: HardHat },
];

export function Partners() {
  const { ref, inView } = useInView({ threshold: 0.3 });

  return (
    <section ref={ref} className="border-y border-primary-100 bg-white py-12 sm:py-16">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.p
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.5 }}
          className="mb-8 text-center text-sm font-semibold uppercase tracking-wider text-primary-400"
        >
          Trusted by leading construction companies, architects, suppliers & banks
        </motion.p>

        <div className="relative overflow-hidden">
          {/* Fade edges */}
          <div className="pointer-events-none absolute left-0 top-0 z-10 h-full w-24 bg-gradient-to-r from-white to-transparent" />
          <div className="pointer-events-none absolute right-0 top-0 z-10 h-full w-24 bg-gradient-to-l from-white to-transparent" />

          <div className="flex animate-marquee gap-12">
            {[...partners, ...partners].map((partner, i) => (
              <div
                key={i}
                className="group flex shrink-0 items-center gap-3 transition-all hover:scale-105"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary-50 text-primary-400 transition-all group-hover:bg-accent group-hover:text-white group-hover:shadow-lg">
                  <partner.icon className="h-6 w-6" />
                </div>
                <span className="font-display text-base font-bold text-primary-400 transition-colors group-hover:text-primary">
                  {partner.name}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
