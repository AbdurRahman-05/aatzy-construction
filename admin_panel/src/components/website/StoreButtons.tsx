'use client';

import React from 'react';

export function PlayStoreIcon({ className = 'w-5 h-5' }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M3.609 1.814L13.792 12 3.61 22.186a2.023 2.023 0 0 1-.22-.916V2.73c0-.337.078-.653.22-.916z"
        fill="#00C1A6"
      />
      <path
        d="M17.218 8.574L13.792 12l3.426 3.426 3.882-2.242c.86-.497.86-1.871 0-2.368l-3.882-2.242z"
        fill="#FFD400"
      />
      <path
        d="M3.609 1.814a1.99 1.99 0 0 1 1.777-.076l11.832 6.836L13.792 12 3.61 1.814z"
        fill="#00A0FF"
      />
      <path
        d="M3.609 22.186L13.792 12l3.426 3.426-11.832 6.836a1.99 1.99 0 0 1-1.777-.076z"
        fill="#FF3333"
      />
    </svg>
  );
}

export function AppleStoreIcon({ className = 'w-5 h-5' }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.84c.66-.8 1.11-1.92.99-3.04-.96.04-2.13.64-2.82 1.44-.61.7-.1.14 1.83-1.01 2.97 1.07-.02 2.18-.57 2.84-1.37z" />
    </svg>
  );
}

interface StoreButtonProps {
  onNavigate?: (target: string) => void;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

/**
 * Compact navigation buttons for headers / navbars
 */
export function NavStoreButtons({ onNavigate, className = '' }: StoreButtonProps) {
  return (
    <div className={`flex items-center gap-2 ${className}`}>
      {/* Google Play */}
      <button
        type="button"
        onClick={() => onNavigate?.('download-playstore')}
        className="group inline-flex items-center gap-2 rounded-xl bg-slate-900 px-3.5 py-2 text-xs font-bold text-white shadow-sm transition-all duration-200 hover:bg-slate-800 hover:shadow hover:-translate-y-0.5 active:translate-y-0 whitespace-nowrap cursor-pointer border border-slate-700/60"
        title="Download for Android on Google Play"
      >
        <PlayStoreIcon className="w-4 h-4 shrink-0 transition-transform group-hover:scale-110" />
        <span className="hidden xl:inline">Google Play</span>
        <span className="xl:hidden">Android</span>
      </button>

      {/* App Store */}
      <button
        type="button"
        onClick={() => onNavigate?.('download-appstore')}
        className="group inline-flex items-center gap-2 rounded-xl bg-slate-900 px-3.5 py-2 text-xs font-bold text-white shadow-sm transition-all duration-200 hover:bg-slate-800 hover:shadow hover:-translate-y-0.5 active:translate-y-0 whitespace-nowrap cursor-pointer border border-slate-700/60"
        title="Download on Apple App Store"
      >
        <AppleStoreIcon className="w-4 h-4 shrink-0 transition-transform group-hover:scale-110 text-white" />
        <span className="hidden xl:inline">App Store</span>
        <span className="xl:hidden">iOS</span>
      </button>
    </div>
  );
}

/**
 * Official Store Badges for Hero and CTA sections
 */
export function HeroStoreBadges({ onNavigate, className = '' }: StoreButtonProps) {
  return (
    <div className={`flex flex-wrap items-center gap-3 ${className}`}>
      {/* Google Play Badge */}
      <button
        type="button"
        onClick={() => onNavigate?.('download-playstore')}
        className="group relative inline-flex items-center gap-3.5 rounded-2xl bg-slate-950 px-5 py-3 text-left text-white shadow-xl shadow-slate-950/20 ring-1 ring-white/10 transition-all duration-200 hover:bg-slate-900 hover:ring-white/20 hover:-translate-y-0.5 active:translate-y-0 cursor-pointer min-w-[165px]"
      >
        <PlayStoreIcon className="w-7 h-7 shrink-0 transition-transform group-hover:scale-105" />
        <div className="flex flex-col">
          <span className="text-[10px] font-semibold tracking-wider text-slate-400 uppercase leading-none">
            GET IT ON
          </span>
          <span className="text-sm sm:text-base font-extrabold text-white tracking-tight leading-snug">
            Google Play
          </span>
        </div>
      </button>

      {/* Apple App Store Badge */}
      <button
        type="button"
        onClick={() => onNavigate?.('download-appstore')}
        className="group relative inline-flex items-center gap-3.5 rounded-2xl bg-slate-950 px-5 py-3 text-left text-white shadow-xl shadow-slate-950/20 ring-1 ring-white/10 transition-all duration-200 hover:bg-slate-900 hover:ring-white/20 hover:-translate-y-0.5 active:translate-y-0 cursor-pointer min-w-[165px]"
      >
        <AppleStoreIcon className="w-7 h-7 shrink-0 text-white transition-transform group-hover:scale-105" />
        <div className="flex flex-col">
          <span className="text-[10px] font-semibold tracking-wider text-slate-400 uppercase leading-none">
            DOWNLOAD ON THE
          </span>
          <span className="text-sm sm:text-base font-extrabold text-white tracking-tight leading-snug">
            App Store
          </span>
        </div>
      </button>
    </div>
  );
}
