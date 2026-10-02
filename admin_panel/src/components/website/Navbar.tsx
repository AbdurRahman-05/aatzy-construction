'use client';

import { useEffect, useState } from 'react';
import { Menu, X, Download, Building2, Shield } from 'lucide-react';
import Link from 'next/link';
import { RippleButton } from './RippleButton';

const navLinks = [
  { label: 'Home', target: 'hero' },
  { label: 'Features', target: 'features' },
  { label: 'Cost Estimator', target: 'estimator' },
  { label: 'Homeowners', target: 'homeowners' },
  { label: 'Contractors', target: 'contractors' },
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
          ? 'glass shadow-[0_4px_30px_rgba(15,23,42,0.08)] py-2.5'
          : 'bg-transparent py-4'
      }`}
    >
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Brand */}
        <button
          onClick={() => handleLinkClick('hero')}
          className="group flex items-center gap-2.5 text-left"
          aria-label="Connectzy Construction home"
        >
          <div className="relative flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-blue-600 to-sky-400 shadow-lg shadow-blue-500/30 transition-transform group-hover:scale-110">
            <Building2 className="h-5 w-5 text-white" strokeWidth={2.5} />
          </div>
          <div className="flex flex-col leading-none">
            <span className="font-display text-base font-extrabold tracking-tight text-slate-900">
              CONNECTZY
            </span>
            <span className="text-[10px] font-semibold text-slate-500 tracking-wider">
              CONSTRUCTION
            </span>
          </div>
        </button>

        {/* Desktop nav */}
        <div className="hidden items-center gap-1 lg:flex">
          {navLinks.map((link) => (
            <button
              key={link.label}
              onClick={() => handleLinkClick(link.target)}
              className="group relative px-3 py-2 text-sm font-medium text-slate-700 transition-colors hover:text-blue-600"
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
            className="flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold text-slate-600 hover:text-blue-600 hover:bg-blue-50/80 rounded-full transition-all border border-slate-200/80"
          >
            <Shield className="h-3.5 w-3.5 text-blue-600" />
            Admin Portal
          </Link>

          <RippleButton
            variant="primary"
            className="text-sm shadow-md"
            onClick={() => handleLinkClick('download')}
          >
            <Download className="h-4 w-4" />
            Download App
          </RippleButton>
        </div>

        {/* Mobile toggle */}
        <button
          className="flex h-10 w-10 items-center justify-center rounded-lg text-slate-700 lg:hidden"
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
          menuOpen ? 'max-h-[600px] opacity-100' : 'max-h-0 opacity-0'
        }`}
      >
        <div className="glass mx-4 mt-3 rounded-2xl p-4 shadow-xl border border-white/80 bg-white/90">
          <div className="flex flex-col gap-1">
            {navLinks.map((link) => (
              <button
                key={link.label}
                onClick={() => handleLinkClick(link.target)}
                className="rounded-xl px-4 py-3 text-left text-sm font-medium text-slate-700 transition-colors hover:bg-blue-50 hover:text-blue-600"
              >
                {link.label}
              </button>
            ))}

            <Link
              href="/admin"
              className="flex items-center gap-2 rounded-xl px-4 py-3 text-left text-sm font-semibold text-blue-600 hover:bg-blue-50"
            >
              <Shield className="h-4 w-4" />
              Admin Portal
            </Link>

            <div className="my-2 h-px bg-slate-100" />
            <RippleButton
              variant="primary"
              className="mt-2 w-full justify-center"
              onClick={() => handleLinkClick('download')}
            >
              <Download className="h-4 w-4" />
              Download App
            </RippleButton>
          </div>
        </div>
      </div>
    </header>
  );
}
