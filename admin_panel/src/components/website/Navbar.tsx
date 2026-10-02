'use client';

import { useEffect, useState } from 'react';
import { Menu, X, Download, Shield, Sparkles } from 'lucide-react';
import Link from 'next/link';
import { RippleButton } from './RippleButton';

const navLinks = [
  { label: 'Home', target: 'hero' },
  { label: 'Cost Estimator', target: 'estimator' },
  { label: '45+ Services', target: 'services-directory' },
  { label: 'Platform Features', target: 'features' },
  { label: 'How It Works', target: 'how-it-works' },
  { label: 'For Clients', target: 'homeowners' },
  { label: 'For Contractors', target: 'contractors' },
];

interface NavbarProps {
  onNavigate: (target: string) => void;
}

export function Navbar({ onNavigate }: NavbarProps) {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    handleScroll();
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleLinkClick = (target: string) => {
    setMenuOpen(false);
    onNavigate(target);
  };

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        scrolled
          ? 'glass shadow-[0_4px_30px_rgba(15,23,42,0.08)] py-2.5 bg-white/85 backdrop-blur-md border-b border-slate-200/60'
          : 'bg-transparent py-4'
      }`}
    >
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Brand */}
        <button
          onClick={() => handleLinkClick('hero')}
          className="group flex items-center gap-3 text-left cursor-pointer"
          aria-label="Connectzy Construction Platform"
        >
          <div className="relative flex h-11 w-11 items-center justify-center rounded-2xl bg-white shadow-md shadow-slate-900/10 border border-slate-200/80 p-1.5 transition-transform duration-300 group-hover:scale-105">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/assets/logo.png"
              alt="Connectzy Logo"
              className="h-full w-full object-contain"
            />
          </div>
          <div className="flex flex-col leading-none">
            <span className="font-display text-lg font-black tracking-tight text-slate-900 group-hover:text-blue-600 transition-colors">
              CONNECTZY
            </span>
            <span className="text-[10px] font-bold text-blue-600 tracking-widest uppercase mt-0.5 flex items-center gap-1">
              <span>CONSTRUCTION APP</span>
              <Sparkles className="w-2.5 h-2.5 text-amber-500" />
            </span>
          </div>
        </button>

        {/* Desktop nav */}
        <div className="hidden items-center gap-1 xl:gap-1.5 lg:flex">
          {navLinks.map((link) => (
            <button
              key={link.label}
              onClick={() => handleLinkClick(link.target)}
              className="group relative px-3 py-2 text-xs xl:text-sm font-semibold text-slate-700 transition-colors hover:text-blue-600 cursor-pointer"
            >
              {link.label}
              <span className="absolute bottom-0 left-1/2 h-0.5 w-0 -translate-x-1/2 rounded-full bg-gradient-to-r from-blue-600 to-sky-400 transition-all duration-300 group-hover:w-full" />
            </button>
          ))}
        </div>

        {/* Desktop CTAs */}
        <div className="hidden items-center gap-3 lg:flex">
          <Link
            href="/admin"
            className="flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold text-slate-700 hover:text-blue-600 hover:bg-blue-50/80 rounded-full transition-all border border-slate-200 shadow-sm"
          >
            <Shield className="h-3.5 w-3.5 text-blue-600" />
            Admin Hub
          </Link>

          <RippleButton
            variant="primary"
            className="text-xs xl:text-sm shadow-md font-bold"
            onClick={() => handleLinkClick('download')}
          >
            <Download className="h-4 w-4" />
            Get Android App
          </RippleButton>
        </div>

        {/* Mobile toggle */}
        <button
          className="flex h-10 w-10 items-center justify-center rounded-lg text-slate-700 lg:hidden cursor-pointer"
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label={menuOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={menuOpen}
        >
          {menuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </nav>

      {/* Mobile menu */}
      <div
        className={`overflow-hidden transition-all duration-500 lg:hidden ${
          menuOpen ? 'max-h-[640px] opacity-100' : 'max-h-0 opacity-0'
        }`}
      >
        <div className="glass mx-4 mt-3 rounded-2xl p-4 shadow-xl border border-white/80 bg-white/95">
          <div className="flex flex-col gap-1">
            {navLinks.map((link) => (
              <button
                key={link.label}
                onClick={() => handleLinkClick(link.target)}
                className="rounded-xl px-4 py-2.5 text-left text-sm font-semibold text-slate-700 transition-colors hover:bg-blue-50 hover:text-blue-600 cursor-pointer"
              >
                {link.label}
              </button>
            ))}

            <Link
              href="/admin"
              className="flex items-center gap-2 rounded-xl px-4 py-2.5 text-left text-sm font-bold text-blue-600 hover:bg-blue-50"
            >
              <Shield className="h-4 w-4" />
              Admin Hub
            </Link>

            <div className="my-2 h-px bg-slate-100" />
            <RippleButton
              variant="primary"
              className="mt-2 w-full justify-center text-sm font-bold"
              onClick={() => handleLinkClick('download')}
            >
              <Download className="h-4 w-4" />
              Download Android App
            </RippleButton>
          </div>
        </div>
      </div>
    </header>
  );
}
