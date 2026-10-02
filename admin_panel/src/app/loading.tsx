import React from 'react';

export default function RootLoading() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 flex flex-col items-center justify-center relative overflow-hidden select-none">
      {/* Top Shimmer Progress Bar */}
      <div className="fixed top-0 left-0 right-0 h-[3px] z-[99999] pointer-events-none overflow-hidden bg-blue-600/10">
        <div className="h-full w-3/4 bg-gradient-to-r from-blue-600 via-sky-400 to-indigo-500 animate-bar-shimmer shadow-[0_0_12px_rgba(37,99,235,0.6)]" />
      </div>

      {/* Ambient background glows */}
      <div className="absolute top-1/4 left-1/3 w-96 h-96 bg-blue-500/5 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/3 w-96 h-96 bg-sky-400/5 rounded-full blur-[140px] pointer-events-none" />

      {/* Central Loading Content */}
      <div className="relative z-10 flex flex-col items-center text-center px-6">
        {/* Animated Concentric Rings Icon */}
        <div className="relative w-20 h-20 mb-5 flex items-center justify-center">
          <div className="absolute inset-0 border-[3px] border-blue-600/20 border-t-blue-600 rounded-full animate-spin-slow" />
          <div className="absolute inset-2 border-[2px] border-sky-400/30 border-b-sky-400 rounded-full animate-spin-reverse" />
          <div className="w-10 h-10 bg-gradient-to-tr from-blue-600 to-sky-400 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/25 animate-pulse-glow">
            <svg className="w-5 h-5 text-white font-bold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
        </div>

        {/* Brand name & Loading Text */}
        <h2 className="text-xl font-black tracking-tight text-slate-900 mb-1 flex items-center space-x-1.5">
          <span>CONNECTZY</span>
          <span className="text-blue-600">CONSTRUCTION</span>
        </h2>
        <p className="text-xs text-slate-500 mb-5 max-w-xs">
          Loading platform modules and verified records...
        </p>

        {/* Mini progress line */}
        <div className="w-48 h-1 bg-slate-200 rounded-full overflow-hidden relative mb-3">
          <div className="h-full bg-gradient-to-r from-blue-600 via-sky-400 to-indigo-500 rounded-full w-2/3 animate-bar-shimmer" />
        </div>

        {/* Bouncing Dots */}
        <div className="flex items-center space-x-1.5 text-xs text-blue-600 font-medium">
          <span>Initializing</span>
          <div className="flex items-center space-x-1 pl-1">
            <span className="w-1.5 h-1.5 bg-blue-600 rounded-full animate-bounce-dot-1" />
            <span className="w-1.5 h-1.5 bg-sky-400 rounded-full animate-bounce-dot-2" />
            <span className="w-1.5 h-1.5 bg-indigo-500 rounded-full animate-bounce-dot-3" />
          </div>
        </div>
      </div>
    </div>
  );
}
