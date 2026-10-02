'use client';

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search,
  Hammer,
  Building2,
  HardHat,
  Ruler,
  Compass,
  FileCheck2,
  Paintbrush,
  Sparkles,
  Layers,
  Grid,
  Zap,
  Droplet,
  Truck,
  ShieldAlert,
  SlidersHorizontal,
  ArrowRight,
} from 'lucide-react';

interface ServiceItem {
  name: string;
  category: string;
  desc: string;
  icon: any;
  color: string;
  bg: string;
}

const serviceList: ServiceItem[] = [
  // --- 1. Core Construction ---
  { name: 'General Contractor / Builder', category: 'Core Construction', desc: 'Turnkey residential & commercial building execution end-to-end', icon: HardHat, color: 'text-blue-600', bg: 'bg-blue-50' },
  { name: 'Concrete & Foundation', category: 'Core Construction', desc: 'RCC column casting, slab reinforcement and pile foundations', icon: Building2, color: 'text-slate-600', bg: 'bg-slate-100' },
  { name: 'Bricklayer & Stonemason', category: 'Core Construction', desc: 'Red brick masonry, AAC block laying and compound stone walls', icon: Layers, color: 'text-amber-700', bg: 'bg-amber-50' },
  { name: 'Demolition & Earthworks', category: 'Core Construction', desc: 'Safe structural demolition, trenching, excavation & site clearance', icon: Hammer, color: 'text-red-600', bg: 'bg-red-50' },
  { name: 'Roofing, Shingles & Gutters', category: 'Core Construction', desc: 'Industrial metal roofing, truss fabrication and waterproofing', icon: Building2, color: 'text-orange-600', bg: 'bg-orange-50' },
  { name: 'Renovation & Floor Remodel', category: 'Core Construction', desc: 'Structural extensions, room additions and complete house redesign', icon: Hammer, color: 'text-emerald-600', bg: 'bg-emerald-50' },

  // --- 2. Design & Planning ---
  { name: 'Architectural Design & 3D', category: 'Design & Planning', desc: 'Floor plans, 3D exterior elevations, vastu layout & walk-throughs', icon: Compass, color: 'text-purple-600', bg: 'bg-purple-50' },
  { name: 'Civil & Structural Engineer', category: 'Design & Planning', desc: 'Structural calculations, steel reinforcement drawings & stability reports', icon: Ruler, color: 'text-indigo-600', bg: 'bg-indigo-50' },
  { name: 'Land Survey & Soil Testing', category: 'Design & Planning', desc: 'Total station contour surveys and bore-core soil bearing tests', icon: Compass, color: 'text-amber-600', bg: 'bg-amber-50' },
  { name: 'Building Approval & Sanctions', category: 'Design & Planning', desc: 'Municipal plan approvals, NOC clearance and blueprint certifications', icon: FileCheck2, color: 'text-emerald-600', bg: 'bg-emerald-50' },

  // --- 3. Interiors & Finishing ---
  { name: 'Residential Interior Designer', category: 'Interiors & Finishing', desc: 'Bespoke modern living spaces, modular furniture & ambient lighting', icon: Sparkles, color: 'text-purple-600', bg: 'bg-purple-50' },
  { name: 'Modular Kitchen Specialist', category: 'Interiors & Finishing', desc: 'Acrylic/PU finish cabinetry, quartz countertops & soft-close fittings', icon: Grid, color: 'text-pink-600', bg: 'bg-pink-50' },
  { name: 'Tile Worker & Marble Polishing', category: 'Interiors & Finishing', desc: 'Vitrified large-format tile laying, Italian marble diamond buffing', icon: Grid, color: 'text-teal-600', bg: 'bg-teal-50' },
  { name: 'Master Painter & Texture', category: 'Interiors & Finishing', desc: 'Royal luxury emulsion, exterior weather-guard coatings & texture art', icon: Paintbrush, color: 'text-rose-600', bg: 'bg-rose-50' },
  { name: 'False Ceiling & Drywall', category: 'Interiors & Finishing', desc: 'Gypsum board cove lighting ceilings, acoustic grid panels & partition', icon: Layers, color: 'text-sky-600', bg: 'bg-sky-50' },
  { name: 'Custom Carpenter & Woodwork', category: 'Interiors & Finishing', desc: 'Teak doors, custom wardrobe laminates & veneer wall paneling', icon: Hammer, color: 'text-amber-800', bg: 'bg-amber-50' },

  // --- 4. MEP & Utilities ---
  { name: 'Licensed Electrical Contractor', category: 'MEP & Utilities', desc: 'Concealed wiring, 3-phase distribution boards & earthing pits', icon: Zap, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Master Plumbing & Drainage', category: 'MEP & Utilities', desc: 'CPVC/UPVC water supply, sewage drainage & sanitary fixture fits', icon: Droplet, color: 'text-blue-600', bg: 'bg-blue-50' },
  { name: 'HVAC Air Conditioning', category: 'MEP & Utilities', desc: 'VRV/VRF central ducted air conditioning, copper piping & chillers', icon: Zap, color: 'text-cyan-600', bg: 'bg-cyan-50' },
  { name: 'Borewell Drilling & Pumps', category: 'MEP & Utilities', desc: 'Deep bore drilling, submersible pumps, sensor starters & piping', icon: Droplet, color: 'text-blue-700', bg: 'bg-blue-50' },
  { name: 'Solar Rooftop Power', category: 'MEP & Utilities', desc: 'On-grid net-metering solar panels, hybrid inverters & battery backup', icon: Zap, color: 'text-amber-500', bg: 'bg-amber-50' },

  // --- 5. Materials & Logistics ---
  { name: 'TMT Steel & Structural Rebar', category: 'Materials & Logistics', desc: 'Primary mill Fe-550D reinforcement steel with factory test certificates', icon: Truck, color: 'text-slate-800', bg: 'bg-slate-100' },
  { name: 'Cement Wholesale & Bulk', category: 'Materials & Logistics', desc: 'OPC & PPC 53-grade bags directly from factory authorized depots', icon: Building2, color: 'text-slate-700', bg: 'bg-slate-100' },
  { name: 'Ready-Mix Concrete (RMC)', category: 'Materials & Logistics', desc: 'Transit mixer supply of M20, M25, M30 grades with pump boom setup', icon: Truck, color: 'text-indigo-700', bg: 'bg-indigo-50' },
  { name: 'Sand, Aggregate & Blue Metal', category: 'Materials & Logistics', desc: 'Washed M-sand, plastering sand, 20mm aggregate directly from quarries', icon: Truck, color: 'text-orange-700', bg: 'bg-orange-50' },

  // --- 6. Specialist Services ---
  { name: 'Waterproofing & Chemical Injection', category: 'Specialist Services', desc: 'Terrace membrane, basement PU injection & bathroom sealants', icon: Droplet, color: 'text-teal-700', bg: 'bg-teal-50' },
  { name: 'Glass, UPVC & Aluminium Façade', category: 'Specialist Services', desc: 'Toughened glass railings, thermal UPVC soundproof sliding windows', icon: Building2, color: 'text-sky-700', bg: 'bg-sky-50' },
  { name: 'Elevator & Home Lifts', category: 'Specialist Services', desc: 'Machine-room-less hydraulic and gearless traction passenger elevators', icon: Layers, color: 'text-purple-700', bg: 'bg-purple-50' },
  { name: 'Smart Security & CCTV', category: 'Specialist Services', desc: 'IP security cameras, smart video doorbells & automated swing gates', icon: ShieldAlert, color: 'text-blue-800', bg: 'bg-blue-50' },
];

const categoryTabs = [
  'All 45+ Services',
  'Core Construction',
  'Design & Planning',
  'Interiors & Finishing',
  'MEP & Utilities',
  'Materials & Logistics',
  'Specialist Services',
];

export function ServicesDirectory({ onNavigate }: { onNavigate: (target: string) => void }) {
  const [selectedCategory, setSelectedCategory] = useState('All 45+ Services');
  const [searchQuery, setSearchQuery] = useState('');

  const filteredServices = useMemo(() => {
    return serviceList.filter((service) => {
      const matchesCategory =
        selectedCategory === 'All 45+ Services' || service.category === selectedCategory;
      const matchesSearch =
        service.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        service.desc.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }, [selectedCategory, searchQuery]);

  return (
    <section id="services-directory" className="py-20 sm:py-24 bg-slate-50 border-t border-slate-200">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-12">
          <span className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-blue-100/80 text-blue-700 text-xs font-black tracking-wider uppercase mb-3 border border-blue-200">
            <SlidersHorizontal className="w-3.5 h-3.5" /> 45+ Verified Trade Categories
          </span>
          <h2 className="font-display text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight">
            Every Construction Specialist on One App
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-600 leading-relaxed">
            From soil testing & blueprints to structural masonry, modular interiors, and raw material procurement —
            browse and hire GST-verified contractors across 45+ specialties.
          </p>

          {/* Search bar */}
          <div className="mt-8 relative max-w-lg mx-auto">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search services (e.g. Architect, TMT Steel, Plumber, Modular Kitchen)..."
              className="w-full pl-12 pr-4 py-3.5 text-sm rounded-2xl border border-slate-300 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-slate-800"
            />
          </div>
        </div>

        {/* Category Filter Tabs */}
        <div className="flex items-center justify-start lg:justify-center gap-2 overflow-x-auto pb-4 mb-8 scrollbar-none">
          {categoryTabs.map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold whitespace-nowrap transition cursor-pointer ${
                selectedCategory === cat
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-500/25'
                  : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        {/* Services Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-5">
          <AnimatePresence>
            {filteredServices.map((service, idx) => {
              const IconComponent = service.icon;
              return (
                <motion.div
                  key={service.name}
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ duration: 0.25, delay: idx * 0.02 }}
                  className="rounded-2xl border border-slate-200/90 bg-white p-5 shadow-sm hover:shadow-md hover:border-blue-400 transition flex flex-col justify-between group"
                >
                  <div>
                    <div className="flex items-center justify-between mb-3">
                      <div className={`p-2.5 rounded-xl ${service.bg} ${service.color} transition group-hover:scale-110 duration-200`}>
                        <IconComponent className="w-5 h-5" />
                      </div>
                      <span className="text-[10px] font-black uppercase text-slate-400 tracking-wider">
                        {service.category.split(' ')[0]}
                      </span>
                    </div>

                    <h3 className="font-extrabold text-slate-900 text-sm leading-snug group-hover:text-blue-600 transition-colors">
                      {service.name}
                    </h3>
                    <p className="mt-1.5 text-xs text-slate-500 leading-relaxed line-clamp-2">
                      {service.desc}
                    </p>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                    <span className="font-semibold text-emerald-600 text-[11px]">✓ Verified Pros Ready</span>
                    <button
                      type="button"
                      onClick={() => onNavigate('contact')}
                      className="inline-flex items-center gap-1 font-bold text-blue-600 group-hover:text-blue-800 transition cursor-pointer"
                    >
                      <span>Inquire</span>
                      <ArrowRight className="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" />
                    </button>
                  </div>
                </motion.div>
              );
            })}
          </AnimatePresence>
        </div>

        {/* Bottom CTA */}
        <div className="mt-12 p-6 rounded-3xl bg-gradient-to-r from-blue-900 via-indigo-900 to-slate-900 text-white flex flex-col sm:flex-row items-center justify-between gap-6 shadow-xl">
          <div>
            <h4 className="text-xl font-extrabold">Are you a contractor, engineer, or material supplier?</h4>
            <p className="text-slate-300 text-sm mt-1">Join our network of 500+ verified professionals and receive fresh project leads in your city.</p>
          </div>
          <button
            type="button"
            onClick={() => onNavigate('register/contractor')}
            className="px-6 py-3 bg-white text-blue-900 font-extrabold text-sm rounded-xl hover:bg-slate-100 shadow-md cursor-pointer whitespace-nowrap transition"
          >
            Register as a Provider
          </button>
        </div>
      </div>
    </section>
  );
}
