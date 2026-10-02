'use client';

import { useMemo, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Home,
  Building2,
  Hotel,
  Briefcase,
  Store,
  Warehouse,
  Hammer,
  FileDown,
  Sparkles,
  Trees,
  SunMedium,
  Cpu,
  Check,
  Save,
  PhoneCall,
  ArrowRight,
  ArrowLeft,
  Loader2,
  CheckCircle2,
} from 'lucide-react';
import { useInView } from '../../hooks/useInView';
import { AnimatedCounter } from './AnimatedCounter';
import { RippleButton } from './RippleButton';

type BuildingType = 'house' | 'apartment' | 'villa' | 'office' | 'commercial' | 'warehouse' | 'renovation';
type QualityTier = 'basic' | 'standard' | 'premium' | 'ultra';

const buildingTypes: { id: BuildingType; label: string; desc: string; icon: typeof Home }[] = [
  { id: 'house', label: 'House', desc: 'Independent residential houses & custom home builds', icon: Home },
  { id: 'apartment', label: 'Apartment', desc: 'Multi-unit residential flats & builder floors', icon: Building2 },
  { id: 'villa', label: 'Villa', desc: 'Premium luxury homes & gated community villas', icon: Hotel },
  { id: 'office', label: 'Office', desc: 'Corporate office spaces & commercial interiors', icon: Briefcase },
  { id: 'commercial', label: 'Commercial', desc: 'Retail outlets, showrooms & shopping complexes', icon: Store },
  { id: 'warehouse', label: 'Warehouse', desc: 'Industrial storage units & logistics sheds', icon: Warehouse },
  { id: 'renovation', label: 'Renovation', desc: 'Complete home remodeling & structural updates', icon: Hammer },
];

const qualityTiers: { id: QualityTier; label: string; rate: number; desc: string }[] = [
  { id: 'basic', label: 'Basic Tier', rate: 1500, desc: 'High-durability standard materials, basic brickwork, standard electrical and plumbing fittings.' },
  { id: 'standard', label: 'Standard Tier', rate: 2025, desc: 'Branded cement & steel, vitrified tile flooring, updated bathroom fixtures, emulsion wall painting.' },
  { id: 'premium', label: 'Premium Tier', rate: 2625, desc: 'Top-tier structural materials, designer granite flooring, premium sanitaryware, decorative false ceiling.' },
  { id: 'ultra', label: 'Ultra Premium', rate: 3375, desc: 'Luxury Italian marble, custom architectural interiors, high-end imported fittings, smart wiring.' },
];

const configs: Record<BuildingType, string[]> = {
  house: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Custom Duplex'],
  apartment: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Penthouse'],
  villa: ['3 BHK Villa', '4 BHK Villa', '5 BHK Villa', 'Duplex Villa'],
  office: ['Standard Corporate', 'Open Plan Executive', 'Retail Showroom'],
  commercial: ['Retail Outlet', 'Showroom', 'Shopping Complex'],
  warehouse: ['Small Storage', 'Medium Logistics', 'Large Industrial'],
  renovation: ['Full Home Remodeling', 'Kitchen & Bath Upgrade', 'Structure Only'],
};

const addOns = [
  { id: 'interior', label: 'Modular Interior Design', desc: 'Custom wardrobes, modular kitchen, TV units, and woodwork', icon: Sparkles, uplift: 0.08 },
  { id: 'landscaping', label: 'Landscaping & Exterior', desc: 'Garden development, compound walling, and exterior lighting', icon: Trees, uplift: 0.05 },
  { id: 'smart', label: 'Smart Home Automation', desc: 'Keyless entry, automated light controls, and security cameras', icon: Cpu, uplift: 0.06 },
  { id: 'solar', label: 'Rooftop Solar Plant', desc: 'On-grid solar power generation setup for eco energy savings', icon: SunMedium, uplift: 0.07 },
];

const GST_RATE = 0.18;
const LABOR_SHARE = 0.35;
const MATERIAL_SHARE = 0.65;

interface EstimatorProps {
  onNavigate: (target: string) => void;
}

export function CostEstimator({ onNavigate }: EstimatorProps) {
  const { ref, inView } = useInView({ threshold: 0.1 });
  const [step, setStep] = useState(0);
  const [buildingType, setBuildingType] = useState<BuildingType>('house');
  const [area, setArea] = useState(1000);
  const [config, setConfig] = useState('2 BHK');
  const [quality, setQuality] = useState<QualityTier>('standard');
  const [selectedAddOns, setSelectedAddOns] = useState<string[]>([]);
  const [pdfLoading, setPdfLoading] = useState(false);
  const [saved, setSaved] = useState(false);

  const calculation = useMemo(() => {
    const tier = qualityTiers.find((q) => q.id === quality)!;
    const baseRate = tier.rate;
    const upliftMultiplier = selectedAddOns.reduce((acc, id) => {
      const addon = addOns.find((a) => a.id === id);
      return acc + (addon?.uplift ?? 0);
    }, 1);
    const effectiveRate = Math.round(baseRate * upliftMultiplier);
    const subtotal = effectiveRate * area;
    const materialCost = Math.round(subtotal * MATERIAL_SHARE);
    const laborCost = Math.round(subtotal * LABOR_SHARE);
    const gst = Math.round(subtotal * GST_RATE);
    const total = subtotal + gst;
    return { effectiveRate, subtotal, materialCost, laborCost, gst, total, tier };
  }, [quality, area, selectedAddOns]);

  const toggleAddOn = (id: string) => {
    setSelectedAddOns((prev) =>
      prev.includes(id) ? prev.filter((a) => a !== id) : [...prev, id]
    );
  };

  const handleBuildingTypeChange = (id: BuildingType) => {
    setBuildingType(id);
    setConfig(configs[id][0]);
  };

  const generatePDF = () => {
    setPdfLoading(true);
    const tier = qualityTiers.find((q) => q.id === quality)!;
    const selectedAddonLabels = addOns
      .filter((a) => selectedAddOns.includes(a.id))
      .map((a) => a.label);

    const html = buildPdfHtml({
      buildingType: buildingTypes.find((b) => b.id === buildingType)!.label,
      area,
      config,
      quality: tier.label,
      rate: calculation.effectiveRate,
      materialCost: calculation.materialCost,
      laborCost: calculation.laborCost,
      subtotal: calculation.subtotal,
      gst: calculation.gst,
      total: calculation.total,
      addOns: selectedAddonLabels,
    });

    const blob = new Blob([html], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    const win = window.open(url, '_blank');
    if (win) {
      win.onload = () => {
        setTimeout(() => {
          win.print();
          setPdfLoading(false);
        }, 500);
      };
    } else {
      setPdfLoading(false);
    }
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  };

  const saveEstimate = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  return (
    <section
      ref={ref}
      id="estimator"
      className="relative overflow-hidden bg-gradient-to-b from-slate-50 to-white py-20 sm:py-28"
    >
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-30" />
      <div className="pointer-events-none absolute left-1/4 top-1/4 h-96 w-96 rounded-full bg-blue-500/10 blur-[120px]" />
      <div className="pointer-events-none absolute right-1/4 bottom-1/4 h-96 w-96 rounded-full bg-sky-400/10 blur-[120px]" />

      <div className="relative mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="mb-12 text-center"
        >
          <span className="glass mb-4 inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-xs font-semibold text-blue-600 border border-blue-200 bg-blue-50/50">
            <CalculatorIcon /> LIVE ESTIMATOR
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl">
            Generate an Instant Construction Budget
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-base text-slate-600">
            Select your building specifications below to calculate baseline estimates tailored to current market rates.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="glass-card overflow-hidden rounded-3xl shadow-2xl border border-slate-200 bg-white"
        >
          <div className="grid lg:grid-cols-[1fr_360px]">
            {/* Form area */}
            <div className="p-6 sm:p-8">
              {/* Step indicator */}
              <div className="mb-8 flex items-center gap-2">
                {['Type', 'Area', 'Quality', 'Add-ons'].map((label, i) => (
                  <div key={label} className="flex flex-1 items-center gap-2">
                    <button
                      onClick={() => setStep(i)}
                      className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold transition-all ${
                        step >= i
                          ? 'bg-gradient-to-br from-blue-600 to-sky-400 text-white shadow-lg shadow-blue-500/30'
                          : 'bg-slate-100 text-slate-400'
                      }`}
                    >
                      {step > i ? <Check className="h-4 w-4" /> : i + 1}
                    </button>
                    <span className={`hidden text-xs font-semibold sm:block ${step >= i ? 'text-slate-900' : 'text-slate-400'}`}>
                      {label}
                    </span>
                    {i < 3 && <div className={`h-0.5 flex-1 rounded-full transition-colors ${step > i ? 'bg-blue-600' : 'bg-slate-100'}`} />}
                  </div>
                ))}
              </div>

              <AnimatePresence mode="wait">
                {/* Step 1: Building Type */}
                {step === 0 && (
                  <motion.div
                    key="step1"
                    initial={{ opacity: 0, x: 30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -30 }}
                    transition={{ duration: 0.3 }}
                  >
                    <h3 className="mb-1 font-display text-xl font-bold text-slate-900">Select Building Type</h3>
                    <p className="mb-5 text-sm text-slate-500">Choose the type of construction project</p>
                    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                      {buildingTypes.map((type) => (
                        <button
                          key={type.id}
                          onClick={() => handleBuildingTypeChange(type.id)}
                          className={`group relative overflow-hidden rounded-2xl border-2 p-4 text-left transition-all duration-300 ${
                            buildingType === type.id
                              ? 'border-blue-600 bg-blue-50/50 shadow-lg shadow-blue-500/10'
                              : 'border-slate-100 bg-white hover:border-blue-300'
                          }`}
                        >
                          {buildingType === type.id && (
                            <span className="absolute right-2 top-2 flex h-5 w-5 items-center justify-center rounded-full bg-blue-600 text-white">
                              <Check className="h-3 w-3" />
                            </span>
                          )}
                          <type.icon className={`mb-2 h-6 w-6 transition-transform group-hover:scale-110 ${buildingType === type.id ? 'text-blue-600' : 'text-slate-400'}`} />
                          <p className="text-sm font-bold text-slate-900">{type.label}</p>
                          <p className="mt-0.5 text-[10px] leading-tight text-slate-400">{type.desc}</p>
                        </button>
                      ))}
                    </div>
                  </motion.div>
                )}

                {/* Step 2: Area + Config */}
                {step === 1 && (
                  <motion.div
                    key="step2"
                    initial={{ opacity: 0, x: 30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -30 }}
                    transition={{ duration: 0.3 }}
                  >
                    <h3 className="mb-1 font-display text-xl font-bold text-slate-900">Built-up Area & Configuration</h3>
                    <p className="mb-5 text-sm text-slate-500">Define the size and layout of your project</p>

                    <label className="mb-2 block text-sm font-semibold text-slate-900" data-estimator-focus tabIndex={-1}>
                      Total Area: <span className="text-blue-600">{area.toLocaleString('en-IN')} sq ft</span>
                    </label>
                    <input
                      type="range"
                      min={500}
                      max={10000}
                      step={100}
                      value={area}
                      onChange={(e) => setArea(Number(e.target.value))}
                      className="w-full accent-blue-600"
                    />
                    <div className="mb-6 mt-1 flex justify-between text-[10px] text-slate-400">
                      <span>500 sq ft</span>
                      <span>10,000+ sq ft</span>
                    </div>

                    <label className="mb-2 block text-sm font-semibold text-slate-900">Layout / Configuration</label>
                    <div className="flex flex-wrap gap-2">
                      {configs[buildingType].map((c) => (
                        <button
                          key={c}
                          onClick={() => setConfig(c)}
                          className={`rounded-xl border px-4 py-2 text-sm font-medium transition-all ${
                            config === c
                              ? 'border-blue-600 bg-blue-600 text-white shadow-lg shadow-blue-500/20'
                              : 'border-slate-200 bg-white text-slate-600 hover:border-blue-300'
                          }`}
                        >
                          {c}
                        </button>
                      ))}
                    </div>
                  </motion.div>
                )}

                {/* Step 3: Quality */}
                {step === 2 && (
                  <motion.div
                    key="step3"
                    initial={{ opacity: 0, x: 30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -30 }}
                    transition={{ duration: 0.3 }}
                  >
                    <h3 className="mb-1 font-display text-xl font-bold text-slate-900">Choose Quality Grade</h3>
                    <p className="mb-5 text-sm text-slate-500">Select material and finish quality tier</p>
                    <div className="grid gap-3 sm:grid-cols-2">
                      {qualityTiers.map((tier) => (
                        <button
                          key={tier.id}
                          onClick={() => setQuality(tier.id)}
                          className={`group relative overflow-hidden rounded-2xl border-2 p-4 text-left transition-all duration-300 ${
                            quality === tier.id
                              ? 'border-blue-600 bg-blue-50/50 shadow-lg shadow-blue-500/10'
                              : 'border-slate-100 bg-white hover:border-blue-300'
                          }`}
                        >
                          {quality === tier.id && (
                            <span className="absolute right-3 top-3 flex h-5 w-5 items-center justify-center rounded-full bg-blue-600 text-white">
                              <Check className="h-3 w-3" />
                            </span>
                          )}
                          <div className="flex items-baseline justify-between pr-6">
                            <span className="text-sm font-bold text-slate-900">{tier.label}</span>
                          </div>
                          <p className="mt-1 font-display text-xl font-extrabold text-blue-600">
                            ₹{tier.rate.toLocaleString('en-IN')}
                            <span className="text-xs font-medium text-slate-400">/sq ft</span>
                          </p>
                          <p className="mt-2 text-[10px] leading-tight text-slate-500">{tier.desc}</p>
                        </button>
                      ))}
                    </div>
                  </motion.div>
                )}

                {/* Step 4: Add-ons */}
                {step === 3 && (
                  <motion.div
                    key="step4"
                    initial={{ opacity: 0, x: 30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -30 }}
                    transition={{ duration: 0.3 }}
                  >
                    <h3 className="mb-1 font-display text-xl font-bold text-slate-900">Smart Add-ons & Facilities</h3>
                    <p className="mb-5 text-sm text-slate-500">Enhance your project with optional features</p>
                    <div className="grid gap-3 sm:grid-cols-2">
                      {addOns.map((addon) => {
                        const selected = selectedAddOns.includes(addon.id);
                        return (
                          <button
                            key={addon.id}
                            onClick={() => toggleAddOn(addon.id)}
                            className={`group relative overflow-hidden rounded-2xl border-2 p-4 text-left transition-all duration-300 ${
                              selected
                                ? 'border-blue-600 bg-blue-50/50 shadow-lg shadow-blue-500/10'
                                : 'border-slate-100 bg-white hover:border-blue-300'
                            }`}
                          >
                            <div className="flex items-start gap-3">
                              <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl transition-all ${selected ? 'bg-gradient-to-br from-blue-600 to-sky-400 text-white' : 'bg-slate-100 text-slate-400 group-hover:text-blue-600'}`}>
                                <addon.icon className="h-5 w-5" />
                              </div>
                              <div className="flex-1">
                                <div className="flex items-center justify-between">
                                  <span className="text-sm font-bold text-slate-900">{addon.label}</span>
                                  <span className={`flex h-5 w-5 items-center justify-center rounded-md border-2 transition-all ${selected ? 'border-blue-600 bg-blue-600 text-white' : 'border-slate-200'}`}>
                                    {selected && <Check className="h-3 w-3" />}
                                  </span>
                                </div>
                                <p className="mt-1 text-[10px] leading-tight text-slate-500">{addon.desc}</p>
                                <p className="mt-1 text-[10px] font-semibold text-blue-600">+{Math.round(addon.uplift * 100)}% on base rate</p>
                              </div>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>

              {/* Navigation */}
              <div className="mt-8 flex items-center justify-between">
                <button
                  onClick={() => setStep(Math.max(0, step - 1))}
                  disabled={step === 0}
                  className="flex items-center gap-1.5 rounded-full px-4 py-2 text-sm font-semibold text-slate-600 transition-all hover:bg-slate-100 disabled:opacity-30 disabled:cursor-not-allowed"
                >
                  <ArrowLeft className="h-4 w-4" /> Back
                </button>
                {step < 3 ? (
                  <RippleButton variant="primary" onClick={() => setStep(step + 1)} className="px-6">
                    Next <ArrowRight className="h-4 w-4" />
                  </RippleButton>
                ) : (
                  <div className="flex gap-2">
                    <RippleButton variant="secondary" onClick={saveEstimate} className="px-5">
                      {saved ? <><CheckCircle2 className="h-4 w-4 text-emerald-500" /> Saved</> : <><Save className="h-4 w-4" /> Save Estimate</>}
                    </RippleButton>
                  </div>
                )}
              </div>
            </div>

            {/* Output card */}
            <div className="relative border-t border-slate-200 bg-gradient-to-br from-slate-900 to-slate-800 p-6 text-white sm:p-8 lg:border-l lg:border-t-0">
              <div className="pointer-events-none absolute inset-0 bg-grid-dark opacity-30" />
              <div className="relative">
                <div className="mb-4 flex items-center justify-between">
                  <span className="text-xs font-semibold uppercase tracking-wider text-sky-400">Estimated Output</span>
                  <span className="flex items-center gap-1 rounded-full bg-white/10 px-2 py-0.5 text-[10px] font-medium">
                    <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400" /> Live
                  </span>
                </div>

                {/* Total budget */}
                <div className="mb-6">
                  <p className="text-xs text-slate-400">Total Estimated Budget</p>
                  <div className="mt-1 font-display text-3xl font-extrabold sm:text-4xl">
                    <AnimatedCounter
                      end={calculation.total}
                      prefix="₹ "
                      start={true}
                      duration={800}
                    />
                  </div>
                  <p className="mt-1 text-xs text-slate-400">
                    ₹{calculation.effectiveRate.toLocaleString('en-IN')} / sq ft · {area.toLocaleString('en-IN')} sq ft
                  </p>
                </div>

                {/* Breakdown */}
                <div className="space-y-2.5 rounded-2xl bg-white/5 p-4 backdrop-blur-sm">
                  {[
                    { label: 'Material Cost', value: calculation.materialCost },
                    { label: 'Labor Cost', value: calculation.laborCost },
                    { label: 'Subtotal', value: calculation.subtotal },
                    { label: `GST (18%)`, value: calculation.gst },
                  ].map((row) => (
                    <div key={row.label} className="flex items-center justify-between text-sm">
                      <span className="text-slate-400">{row.label}</span>
                      <span className="font-semibold">₹{row.value.toLocaleString('en-IN')}</span>
                    </div>
                  ))}
                  <div className="my-2 h-px bg-white/10" />
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-semibold">Total</span>
                    <span className="font-display text-lg font-extrabold text-sky-400">
                      ₹{calculation.total.toLocaleString('en-IN')}
                    </span>
                  </div>
                </div>

                {/* Actions */}
                <div className="mt-6 space-y-2.5">
                  <button
                    onClick={generatePDF}
                    disabled={pdfLoading}
                    className="flex w-full items-center justify-center gap-2 rounded-full bg-gradient-to-r from-blue-600 to-sky-400 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-500/30 transition-all hover:scale-[1.02] hover:shadow-blue-500/50 disabled:opacity-70"
                  >
                    {pdfLoading ? (
                      <><Loader2 className="h-4 w-4 animate-spin" /> Preparing PDF...</>
                    ) : (
                      <><FileDown className="h-4 w-4" /> Download Detailed PDF Quotation</>
                    )}
                  </button>
                  <button
                    onClick={() => onNavigate('contact')}
                    className="flex w-full items-center justify-center gap-2 rounded-full border border-white/20 px-6 py-3 text-sm font-semibold text-white transition-all hover:bg-white/10"
                  >
                    <PhoneCall className="h-4 w-4" /> Request Expert Consultation
                  </button>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function CalculatorIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" />
      <line x1="8" y1="6" x2="16" y2="6" />
      <line x1="8" y1="14" x2="8" y2="14" />
      <line x1="12" y1="14" x2="12" y2="14" />
      <line x1="16" y1="14" x2="16" y2="14" />
      <line x1="8" y1="18" x2="8" y2="18" />
      <line x1="12" y1="18" x2="12" y2="18" />
      <line x1="16" y1="18" x2="16" y2="18" />
    </svg>
  );
}

function buildPdfHtml(data: {
  buildingType: string;
  area: number;
  config: string;
  quality: string;
  rate: number;
  materialCost: number;
  laborCost: number;
  subtotal: number;
  gst: number;
  total: number;
  addOns: string[];
}): string {
  const fmt = (n: number) => `₹${n.toLocaleString('en-IN')}`;
  const today = new Date().toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
  const quoteId = `CONNECTZY-${Date.now().toString().slice(-6)}`;
  return `<!doctype html>
<html><head><meta charset="utf-8"><title>CONNECTZY Construction Quotation ${quoteId}</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box;font-family:'Helvetica Neue',Arial,sans-serif}
  body{padding:40px;color:#0f172a;background:#fff}
  .header{display:flex;justify-content:space-between;align-items:flex-start;border-bottom:3px solid #2563eb;padding-bottom:20px;margin-bottom:30px}
  .brand{font-size:24px;font-weight:900;color:#0f172a;letter-spacing:-0.5px}
  .brand span{color:#2563eb}
  .tagline{font-size:11px;color:#64748b;margin-top:2px}
  .quote-info{text-align:right}
  .quote-id{font-size:14px;font-weight:700;color:#0f172a}
  .quote-date{font-size:11px;color:#64748b;margin-top:2px}
  .title{font-size:20px;font-weight:700;margin-bottom:20px}
  .summary-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:30px}
  .summary-item{background:#f8fafc;border-radius:10px;padding:14px}
  .summary-label{font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:0.5px}
  .summary-value{font-size:15px;font-weight:700;color:#0f172a;margin-top:4px}
  table{width:100%;border-collapse:collapse;margin-bottom:24px}
  th{background:#0f172a;color:#fff;text-align:left;padding:12px;font-size:12px;text-transform:uppercase;letter-spacing:0.5px}
  td{padding:12px;border-bottom:1px solid #e2e8f0;font-size:13px}
  .total-row{background:#eff6ff;font-weight:700}
  .grand-total{background:#2563eb;color:#fff}
  .grand-total td{font-size:16px;font-weight:800;border:none}
  .addons{margin-bottom:24px}
  .addons h4{font-size:13px;margin-bottom:8px}
  .addon-list{display:flex;flex-wrap:wrap;gap:8px}
  .addon-tag{background:#dbeafe;color:#1e40af;padding:4px 12px;border-radius:20px;font-size:11px;font-weight:600}
  .footer{margin-top:40px;padding-top:20px;border-top:2px solid #e2e8f0;text-align:center;font-size:11px;color:#64748b}
  .footer strong{color:#0f172a}
  @media print{body{padding:20px}}
</style></head>
<body>
  <div class="header">
    <div>
      <div class="brand">CONNECTZY <span>Construction</span></div>
      <div class="tagline">Smart Building & Procurement Ecosystem</div>
    </div>
    <div class="quote-info">
      <div class="quote-id">Quote #${quoteId}</div>
      <div class="quote-date">${today}</div>
    </div>
  </div>
  <div class="title">Construction Budget Estimate</div>
  <div class="summary-grid">
    <div class="summary-item"><div class="summary-label">Building Type</div><div class="summary-value">${data.buildingType}</div></div>
    <div class="summary-item"><div class="summary-label">Configuration</div><div class="summary-value">${data.config}</div></div>
    <div class="summary-item"><div class="summary-label">Quality Grade</div><div class="summary-value">${data.quality}</div></div>
    <div class="summary-item"><div class="summary-label">Built-up Area</div><div class="summary-value">${data.area.toLocaleString('en-IN')} sq ft</div></div>
  </div>
  ${data.addOns.length ? `<div class="addons"><h4>Selected Add-ons</h4><div class="addon-list">${data.addOns.map(a => `<span class="addon-tag">${a}</span>`).join('')}</div></div>` : ''}
  <table>
    <tr><th>Description</th><th style="text-align:right">Amount</th></tr>
    <tr><td>Material Cost (65%)</td><td style="text-align:right">${fmt(data.materialCost)}</td></tr>
    <tr><td>Labor Cost (35%)</td><td style="text-align:right">${fmt(data.laborCost)}</td></tr>
    <tr class="total-row"><td>Subtotal</td><td style="text-align:right">${fmt(data.subtotal)}</td></tr>
    <tr><td>GST (18%)</td><td style="text-align:right">${fmt(data.gst)}</td></tr>
    <tr class="grand-total"><td>Grand Total</td><td style="text-align:right">${fmt(data.total)}</td></tr>
  </table>
  <p style="font-size:12px;color:#64748b;margin-bottom:8px">Effective Rate: <strong>${fmt(data.rate)}/sq ft</strong></p>
  <div class="footer">
    <p><strong>CONNECTZY Construction Technologies</strong></p>
    <p>support@connectzy.com · partners@connectzy.com</p>
    <p style="margin-top:8px">This is an indicative estimate based on current market rates. Final pricing may vary based on site conditions, material availability, and contractor negotiations.</p>
    <p style="margin-top:8px">© 2026 CONNECTZY Construction Technologies. All Rights Reserved.</p>
  </div>
</body></html>`;
}
