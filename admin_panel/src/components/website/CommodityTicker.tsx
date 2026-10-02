'use client';

import { motion } from 'framer-motion';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

const commodityItems = [
  { name: 'Ultratech Cement (50kg)', price: '₹380 / bag', change: '+₹5', trend: 'up' },
  { name: 'TMT Steel Fe-550D', price: '₹54,200 / MT', change: '-₹350', trend: 'down' },
  { name: 'Manufactured Sand (M-Sand)', price: '₹52 / cu.ft', change: 'Stable', trend: 'flat' },
  { name: 'Wire-cut Clay Bricks', price: '₹9.40 / pc', change: '+₹0.20', trend: 'up' },
  { name: 'AAC Light Blocks (4")', price: '₹58 / block', change: 'Stable', trend: 'flat' },
  { name: 'Crushed Blue Metal (20mm)', price: '₹38 / cu.ft', change: 'Stable', trend: 'flat' },
  { name: 'Ready-Mix Concrete (M25)', price: '₹3,650 / m³', change: '+₹40', trend: 'up' },
  { name: 'Polycab 2.5mm² FR Wire', price: '₹2,140 / 90m', change: '-₹15', trend: 'down' },
  { name: 'Finolex 4" SWR Pipe', price: '₹740 / 10ft', change: 'Stable', trend: 'flat' },
];

interface CommodityTickerProps {
  onNavigate?: (target: string) => void;
}

export function CommodityTicker({ onNavigate }: CommodityTickerProps) {
  return (
    <div
      id="commodity-ticker"
      onClick={() => onNavigate?.('features')}
      className="bg-slate-900 border-y border-slate-800 text-slate-200 py-2.5 overflow-hidden select-none cursor-pointer transition-colors hover:bg-slate-800/90"
      title="Click to view wholesale materials & market features"
    >
      <div className="flex items-center">
        {/* Fixed Title Tag */}
        <div className="flex items-center gap-1.5 px-4 bg-slate-900 z-10 font-bold text-xs tracking-wider uppercase text-amber-400 whitespace-nowrap border-r border-slate-800">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          Live Daily Market Rates
        </div>

        {/* Marquee Animation */}
        <motion.div
          className="flex items-center gap-8 whitespace-nowrap"
          animate={{ x: [0, -1000] }}
          transition={{ repeat: Infinity, duration: 25, ease: 'linear' }}
        >
          {[...commodityItems, ...commodityItems, ...commodityItems].map((item, idx) => (
            <div key={idx} className="flex items-center gap-2 text-xs font-medium">
              <span className="text-slate-300 font-semibold">{item.name}:</span>
              <span className="text-white font-bold">{item.price}</span>
              <span
                className={`flex items-center gap-0.5 text-[11px] font-bold px-1.5 py-0.5 rounded ${
                  item.trend === 'up'
                    ? 'text-emerald-400 bg-emerald-950/60'
                    : item.trend === 'down'
                    ? 'text-red-400 bg-red-950/60'
                    : 'text-slate-400 bg-slate-800'
                }`}
              >
                {item.trend === 'up' && <TrendingUp className="w-3 h-3" />}
                {item.trend === 'down' && <TrendingDown className="w-3 h-3" />}
                {item.trend === 'flat' && <Minus className="w-3 h-3" />}
                {item.change}
              </span>
              <span className="text-slate-700">|</span>
            </div>
          ))}
        </motion.div>
      </div>
    </div>
  );
}
