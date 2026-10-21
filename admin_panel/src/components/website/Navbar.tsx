'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Menu, X } from 'lucide-react';
import { NavStoreButtons, PlayStoreIcon, AppleStoreIcon } from './StoreButtons';

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
          : 'bg-transparent py-3.5 sm:py-4'
      }`}
    >
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Brand - Logo Only (Enlarged, crisp & prominent) */}
        <button
          onClick={() => handleLinkClick('hero')}
          className="group flex items-center cursor-pointer focus:outline-none transition-transform duration-300 hover:scale-105"
          aria-label="Connectzy Construction Platform"
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/assets/logo.png"
            alt="Connectzy Logo"
            className="h-12 sm:h-14 md:h-16 max-h-16 w-auto object-contain drop-shadow-sm transition-all duration-300"
          />
        </button>

        {/* Desktop nav - Neatly aligned */}
        <div className="hidden items-center gap-1 xl:gap-2.5 lg:flex">
          {navLinks.map((link) => (
            <button
              key={link.label}
              onClick={() => handleLinkClick(link.target)}
              className="group relative px-3 py-2 text-xs xl:text-sm font-semibold text-slate-700 transition-colors hover:text-blue-600 cursor-pointer whitespace-nowrap"
            >
              {link.label}
              <span className="absolute bottom-0 left-1/2 h-0.5 w-0 -translate-x-1/2 rounded-full bg-gradient-to-r from-blue-600 to-sky-400 transition-all duration-300 group-hover:w-full" />
            </button>
          ))}
        </div>

        {/* Desktop Store Badges - Google Play & App Store */}
        <div className="hidden items-center lg:flex shrink-0">
          <NavStoreButtons onNavigate={handleLinkClick} />
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

            <div className="my-2 h-px bg-slate-100" />
            <div className="grid grid-cols-2 gap-2 mt-2">
              <button
                type="button"
                onClick={() => handleLinkClick('download-playstore')}
                className="flex items-center justify-center gap-2 rounded-xl bg-slate-950 px-3 py-2.5 text-xs font-bold text-white shadow-sm hover:bg-slate-900 border border-slate-800 cursor-pointer"
              >
                <PlayStoreIcon className="w-4 h-4 shrink-0" />
                <span>Google Play</span>
              </button>
              <button
                type="button"
                onClick={() => handleLinkClick('download-appstore')}
                className="flex items-center justify-center gap-2 rounded-xl bg-slate-950 px-3 py-2.5 text-xs font-bold text-white shadow-sm hover:bg-slate-900 border border-slate-800 cursor-pointer"
              >
                <AppleStoreIcon className="w-4 h-4 shrink-0 text-white" />
                <span>App Store</span>
              </button>
            </div>

            <div className="mt-3 pt-3 border-t border-slate-100 flex flex-wrap items-center justify-center gap-x-3 gap-y-1 text-xs text-slate-500 font-medium">
              <Link href="/privacy-policy" target="_blank" className="hover:text-blue-600 transition-colors">Privacy</Link>
              <span>•</span>
              <Link href="/terms-and-conditions" target="_blank" className="hover:text-blue-600 transition-colors">Terms &amp; Conditions</Link>
              <span>•</span>
              <Link href="/refund-policy" target="_blank" className="hover:text-blue-600 transition-colors">Refund Policy</Link>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
