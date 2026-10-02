import React from 'react';

export default function RootLoading() {
  return (
    <div className="min-h-screen bg-[#0B0F19] text-gray-100 flex flex-col items-center justify-center relative overflow-hidden select-none">
      {/* Top Shimmer Progress Bar */}
      <div className="fixed top-0 left-0 right-0 h-[3.5px] z-[99999] pointer-events-none overflow-hidden bg-blue-600/20">
        <div className="h-full w-3/4 bg-gradient-to-r from-blue-500 via-amber-400 to-emerald-400 animate-bar-shimmer shadow-[0_0_16px_rgba(59,130,246,0.8)]" />
      </div>

      {/* Ambient background glows */}
      <div className="absolute top-1/4 left-1/3 w-96 h-96 bg-blue-600/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/3 w-96 h-96 bg-amber-500/10 rounded-full blur-[140px] pointer-events-none" />

      {/* Central Loading Content */}
      <div className="relative z-10 flex flex-col items-center text-center px-6">
        {/* Animated Concentric Rings Icon */}
        <div className="relative w-24 h-24 mb-6 flex items-center justify-center">
          <div className="absolute inset-0 border-[3px] border-blue-500/20 border-t-blue-500 rounded-full animate-spin-slow" />
          <div className="absolute inset-2.5 border-[2px] border-amber-400/30 border-b-amber-400 rounded-full animate-spin-reverse" />
          <div className="w-12 h-12 bg-gradient-to-tr from-amber-500 to-amber-600 rounded-2xl flex items-center justify-center shadow-lg shadow-amber-500/25 animate-pulse-glow">
            <svg className="w-7 h-7 text-black font-bold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
        </div>

        {/* Brand name & Loading Text */}
        <h2 className="text-2xl font-black tracking-tight text-white mb-2 flex items-center space-x-2">
          <span>Buildzy</span>
          <span className="text-amber-500">Platform</span>
        </h2>
        <p className="text-sm text-gray-400 mb-6 max-w-xs">
          Loading workspace, services and projects...
        </p>

        {/* Mini progress line */}
        <div className="w-52 h-1.5 bg-gray-800 rounded-full overflow-hidden relative mb-4">
          <div className="h-full bg-gradient-to-r from-amber-500 via-blue-500 to-indigo-500 rounded-full w-2/3 animate-bar-shimmer" />
        </div>

        {/* Bouncing Dots */}
        <div className="flex items-center space-x-1.5 text-xs text-amber-400 font-medium">
          <span>Preparing experience</span>
          <div className="flex items-center space-x-1 pl-1">
            <span className="w-1.5 h-1.5 bg-amber-400 rounded-full animate-bounce-dot-1" />
            <span className="w-1.5 h-1.5 bg-blue-400 rounded-full animate-bounce-dot-2" />
            <span className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce-dot-3" />
          </div>
        </div>
      </div>
    </div>
  );
}
