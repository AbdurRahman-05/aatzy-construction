'use client';

import { motion } from 'framer-motion';
import { IndianRupee, Users, Clock, Star } from 'lucide-react';
import { useInView } from '../../hooks/useInView';
import { AnimatedCounter } from './AnimatedCounter';

const metrics = [
  {
    icon: IndianRupee,
    value: 50,
    prefix: '₹',
    suffix: '+ Cr',
    label: 'Project Budget Estimations Generated',
    color: 'from-blue-600 to-sky-400',
    decimals: 0,
  },
  {
    icon: Users,
    value: 1200,
    prefix: '',
    suffix: '+',
    label: 'Verified Contractors, Architects & Material Suppliers',
    color: 'from-sky-400 to-blue-600',
    decimals: 0,
  },
  {
    icon: Clock,
    value: 98,
    prefix: '',
    suffix: '%',
    label: 'On-Time Project Milestone Completion Rate',
    color: 'from-emerald-500 to-blue-600',
    decimals: 0,
  },
  {
    icon: Star,
    value: 4.9,
    prefix: '',
    suffix: ' / 5',
    label: 'Customer Satisfaction Rating',
    color: 'from-amber-500 to-sky-400',
    decimals: 1,
  },
];

export function Metrics() {
  const { ref, inView } = useInView({ threshold: 0.3 });

  return (
    <section ref={ref} className="relative -mt-8 py-8 sm:py-12">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 gap-4 sm:gap-6 lg:grid-cols-4">
          {metrics.map((metric, i) => (
            <motion.div
              key={metric.label}
              initial={{ opacity: 0, y: 40 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.5, delay: i * 0.12 }}
              whileHover={{ y: -6 }}
              className="glass-card group relative overflow-hidden rounded-3xl p-6 text-center border border-slate-200/80 bg-white/80 backdrop-blur-md shadow-xl"
            >
              {/* Glow on hover */}
              <div
                className={`absolute inset-0 bg-gradient-to-br ${metric.color} opacity-0 transition-opacity duration-500 group-hover:opacity-[0.06]`}
              />
              <div
                className={`mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br ${metric.color} shadow-lg transition-transform duration-300 group-hover:scale-110 group-hover:rotate-6`}
              >
                <metric.icon className="h-6 w-6 text-white" strokeWidth={2.5} />
              </div>
              <div className="font-display text-3xl font-extrabold text-slate-900 sm:text-4xl">
                <AnimatedCounter
                  end={metric.value}
                  prefix={metric.prefix}
                  suffix={metric.suffix}
                  decimals={metric.decimals}
                  start={inView}
                />
              </div>
              <p className="mt-2 text-xs font-medium leading-snug text-slate-500 sm:text-sm">
                {metric.label}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
