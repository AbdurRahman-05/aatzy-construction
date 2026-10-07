'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Mail,
  Phone,
  ShieldCheck,
  ArrowUp,
  Send,
  CheckCircle2,
} from 'lucide-react';

interface FooterProps {
  onNavigate: (target: string) => void;
}

const linkSections: Array<{
  title: string;
  links: Array<{ label: string; target?: string; href?: string }>;
}> = [
  {
    title: 'Platform Features',
    links: [
      { label: 'Instant Cost Estimator', target: 'estimator' },
      { label: '45+ Trade Directory', target: 'services-directory' },
      { label: 'Platform Capabilities', target: 'features' },
      { label: 'Daily Commodity Ticker', target: 'commodity-ticker' },
    ],
  },
  {
    title: 'For Users & Builders',
    links: [
      { label: 'How Connectzy Works', target: 'how-it-works' },
      { label: 'Homeowner Experience', target: 'homeowners' },
      { label: 'Contractors & Suppliers', target: 'contractors' },
      { label: 'Mobile App Showcase', target: 'features' },
    ],
  },
  {
    title: 'Legal & Policies',
    links: [
      { label: 'Privacy Policy', href: '/privacy-policy' },
      { label: 'Terms & Conditions', href: '/terms-and-conditions' },
      { label: 'Refund & Cancellation Policy', href: '/refund-policy' },
    ],
  },
];

function FacebookIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" {...props}>
      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
    </svg>
  );
}

function InstagramIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <rect width="20" height="20" x="2" y="2" rx="5" ry="5"/>
      <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/>
      <line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/>
    </svg>
  );
}

function LinkedinIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" {...props}>
      <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/>
    </svg>
  );
}

function TwitterIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" {...props}>
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
  );
}

function YoutubeIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" {...props}>
      <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
    </svg>
  );
}

const socials = [
  { icon: FacebookIcon, label: 'Facebook', href: 'https://facebook.com' },
  { icon: InstagramIcon, label: 'Instagram', href: 'https://instagram.com' },
  { icon: LinkedinIcon, label: 'LinkedIn', href: 'https://linkedin.com' },
  { icon: TwitterIcon, label: 'X (Twitter)', href: 'https://x.com' },
  { icon: YoutubeIcon, label: 'YouTube', href: 'https://youtube.com' },
];

export function Footer({ onNavigate }: FooterProps) {
  const [email, setEmail] = useState('');
  const [subscribed, setSubscribed] = useState(false);

  const handleSubscribe = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !email.includes('@')) return;
    setSubscribed(true);
    setEmail('');
    setTimeout(() => setSubscribed(false), 3000);
  };

  const scrollTop = () => window.scrollTo({ top: 0, behavior: 'smooth' });

  return (
    <footer className="relative overflow-hidden bg-gradient-to-b from-primary-900 to-primary text-white">
      <div className="pointer-events-none absolute inset-0 bg-grid-dark opacity-20" />
      <div className="pointer-events-none absolute left-1/2 top-0 h-px w-full bg-gradient-to-r from-transparent via-accent-2/40 to-transparent" />

      <div className="relative mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        {/* Newsletter */}
        <div className="mb-14 flex flex-col items-center justify-between gap-6 rounded-3xl bg-white/5 p-8 backdrop-blur-sm lg:flex-row">
          <div className="text-center lg:text-left">
            <h3 className="font-display text-xl font-bold">Stay Updated on Construction Trends</h3>
            <p className="mt-1 text-sm text-primary-300">Get material price alerts and platform updates delivered to your inbox.</p>
          </div>
          <form onSubmit={handleSubscribe} className="flex w-full max-w-md gap-2">
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              required
              className="flex-1 rounded-full border border-white/20 bg-white/10 px-5 py-3 text-sm text-white placeholder:text-primary-400 transition-all focus:border-accent-2 focus:outline-none focus:ring-2 focus:ring-accent-2/30"
            />
            <button
              type="submit"
              className="flex items-center gap-2 rounded-full bg-gradient-to-r from-accent to-accent-2 px-5 py-3 text-sm font-semibold text-white shadow-lg transition-all hover:scale-105"
            >
              {subscribed ? <><CheckCircle2 className="h-4 w-4" /> Subscribed</> : <><Send className="h-4 w-4" /> Subscribe</>}
            </button>
          </form>
        </div>

        {/* Main footer grid */}
        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-[1.8fr_1fr_1fr_1fr_1.3fr]">
          {/* Brand column */}
          <div>
            <div className="flex items-center gap-3">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="/assets/logo.png"
                alt="Connectzy Construction"
                className="h-9 w-auto object-contain brightness-150 contrast-125"
              />
              <div>
                <p className="font-display text-base font-extrabold tracking-tight">CONNECTZY</p>
                <p className="text-[10px] uppercase tracking-wider text-primary-300">Construction Platform</p>
              </div>
            </div>
            <p className="mt-4 max-w-xs text-sm leading-relaxed text-primary-300">
              Smart cost &amp; raw material estimation, 45+ verified trade specialties, milestone photo verification, live commodity prices, and direct wholesale sourcing.
            </p>
          </div>

          {/* Link columns */}
          {linkSections.map((section) => (
            <div key={section.title}>
              <h4 className="font-display text-sm font-bold uppercase tracking-wider text-accent-2">
                {section.title}
              </h4>
              <ul className="mt-4 space-y-2.5">
                {section.links.map((link) => (
                  <li key={link.label}>
                    {link.href ? (
                      <Link
                        href={link.href}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="group relative inline-flex items-center text-sm text-primary-300 transition-colors hover:text-white"
                      >
                        {link.label}
                        <span className="absolute -bottom-0.5 left-0 h-px w-0 bg-accent-2 transition-all duration-300 group-hover:w-full" />
                      </Link>
                    ) : (
                      <button
                        onClick={() => link.target && onNavigate(link.target)}
                        className="group relative text-sm text-primary-300 transition-colors hover:text-white cursor-pointer"
                      >
                        {link.label}
                        <span className="absolute -bottom-0.5 left-0 h-px w-0 bg-accent-2 transition-all duration-300 group-hover:w-full" />
                      </button>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          ))}

          {/* Contact column */}
          <div>
            <h4 className="font-display text-sm font-bold uppercase tracking-wider text-accent-2">
              Contact & Support
            </h4>
            <ul className="mt-4 space-y-3">
              <li>
                <a href="mailto:support@connectzy.com" className="group flex items-center gap-2 text-sm text-primary-300 transition-colors hover:text-white">
                  <Mail className="h-4 w-4 text-accent" />
                  support@connectzy.com
                </a>
              </li>
              <li>
                <a href="mailto:partners@connectzy.com" className="group flex items-center gap-2 text-sm text-primary-300 transition-colors hover:text-white">
                  <Mail className="h-4 w-4 text-accent" />
                  partners@connectzy.com
                </a>
              </li>
              <li>
                <a href="tel:+918000000000" className="group flex items-center gap-2 text-sm text-primary-300 transition-colors hover:text-white">
                  <Phone className="h-4 w-4 text-accent" />
                  +91 80000 00000
                </a>
              </li>
            </ul>

            {/* Socials */}
            <div className="mt-5 flex gap-2">
              {socials.map((social) => (
                <a
                  key={social.label}
                  href={social.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={social.label}
                  className="flex h-9 w-9 items-center justify-center rounded-lg bg-white/5 text-primary-300 transition-all hover:bg-gradient-to-br hover:from-accent hover:to-accent-2 hover:text-white hover:rotate-6"
                >
                  <social.icon className="h-4 w-4" />
                </a>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="mt-12 flex flex-col items-center justify-between gap-4 border-t border-white/10 pt-6 sm:flex-row">
          <p className="text-xs text-primary-400">
            © 2026 Connectzy Construction Technologies. All Rights Reserved.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-xs">
            {[
              { name: 'Privacy Policy', href: '/privacy-policy' },
              { name: 'Terms & Conditions', href: '/terms-and-conditions' },
              { name: 'Refund & Cancellation Policy', href: '/refund-policy' }
            ].map((item) => (
              <Link
                key={item.name}
                href={item.href}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary-300 transition-colors hover:text-white hover:underline underline-offset-4"
              >
                {item.name}
              </Link>
            ))}
          </div>
        </div>
      </div>

      {/* Scroll to top */}
      <button
        onClick={scrollTop}
        aria-label="Scroll to top"
        className="absolute bottom-6 right-6 flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-accent to-accent-2 text-white shadow-lg transition-all hover:scale-110 hover:shadow-xl"
      >
        <ArrowUp className="h-5 w-5" />
      </button>
    </footer>
  );
}
