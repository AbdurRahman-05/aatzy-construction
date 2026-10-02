import React from 'react';

export default function AdminLoading() {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col font-sans select-none">
      {/* Top Shimmer Progress Bar */}
      <div className="fixed top-0 left-0 right-0 h-[3.5px] z-[99999] pointer-events-none overflow-hidden bg-blue-600/10">
        <div className="h-full w-2/3 bg-gradient-to-r from-blue-600 via-indigo-500 to-amber-500 animate-bar-shimmer shadow-[0_0_12px_rgba(37,99,235,0.7)]" />
      </div>

      {/* Top Header Skeleton */}
      <header className="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between shadow-sm sticky top-0 z-40">
        <div className="flex items-center space-x-4">
          <div className="bg-blue-600 p-2 rounded-lg shadow-sm">
            <svg className="w-6 h-6 text-white animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <div className="flex flex-col space-y-1">
            <div className="h-5 w-40 bg-gray-200 rounded animate-pulse" />
            <div className="h-3 w-24 bg-gray-100 rounded animate-pulse" />
          </div>
        </div>

        <div className="flex items-center space-x-3">
          <div className="h-4 w-24 bg-gray-200 rounded animate-pulse" />
          <div className="w-8 h-8 rounded-full bg-blue-100 animate-pulse" />
        </div>
      </header>

      {/* Body Skeleton */}
      <div className="flex flex-1">
        {/* Sidebar Skeleton */}
        <aside className="w-64 bg-white border-r border-gray-200 py-6 px-4 flex flex-col shadow-sm sticky top-[73px] h-[calc(100vh-73px)]">
          <div className="h-3 w-28 bg-gray-200 rounded mb-4 animate-pulse px-3" />
          <div className="space-y-2.5">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div
                key={i}
                className="h-10 rounded-xl bg-gray-100 animate-pulse flex items-center px-4 space-x-3"
              >
                <div className="w-4 h-4 rounded bg-gray-200" />
                <div className="h-3 w-24 rounded bg-gray-200" />
              </div>
            ))}
          </div>
        </aside>

        {/* Main Content Area with Centered Futuristic Loader */}
        <main className="flex-1 p-8 overflow-y-auto bg-gray-50 flex flex-col">
          <div className="max-w-6xl mx-auto w-full flex-1 flex flex-col">
            {/* Top Stat Cards Skeleton */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center text-center animate-pulse"
                >
                  <div className="w-12 h-12 rounded-xl bg-blue-50 mb-3" />
                  <div className="h-3 w-20 bg-gray-200 rounded mb-2" />
                  <div className="h-7 w-12 bg-gray-300 rounded" />
                </div>
              ))}
            </div>

            {/* Central Animated Loading Banner */}
            <div className="flex-1 flex items-center justify-center py-12">
              <div className="bg-white/95 backdrop-blur-xl border border-blue-100 rounded-3xl p-10 max-w-md w-full shadow-2xl shadow-blue-500/10 flex flex-col items-center text-center relative overflow-hidden">
                {/* Ambient glow in corner */}
                <div className="absolute -top-16 -right-16 w-36 h-36 bg-blue-500/10 rounded-full blur-2xl pointer-events-none" />
                <div className="absolute -bottom-16 -left-16 w-36 h-36 bg-amber-500/10 rounded-full blur-2xl pointer-events-none" />

                {/* Animated Concentric Rings Icon */}
                <div className="relative w-20 h-20 mb-6 flex items-center justify-center">
                  {/* Outer spinning ring */}
                  <div className="absolute inset-0 border-[3px] border-blue-600/20 border-t-blue-600 rounded-full animate-spin-slow" />
                  {/* Inner reverse spinning ring */}
                  <div className="absolute inset-2 border-[2px] border-amber-500/30 border-b-amber-500 rounded-full animate-spin-reverse" />
                  {/* Center pulsating badge */}
                  <div className="w-11 h-11 bg-gradient-to-tr from-blue-600 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-500/30 animate-pulse-glow">
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                    </svg>
                  </div>
                </div>

                {/* Status Typography */}
                <h3 className="text-lg font-extrabold text-gray-900 tracking-tight mb-1.5">
                  Loading Admin Panel
                </h3>
                <p className="text-xs text-gray-500 mb-6">
                  Synchronizing records, quotes, providers & ads...
                </p>

                {/* Animated Mini Progress Track */}
                <div className="w-48 h-1.5 bg-gray-100 rounded-full overflow-hidden relative mb-4">
                  <div className="h-full bg-gradient-to-r from-blue-600 to-amber-500 rounded-full w-2/3 animate-bar-shimmer" />
                </div>

                {/* Staggered bouncing indicator dots */}
                <div className="flex items-center space-x-1.5 text-xs text-blue-600 font-semibold">
                  <span>Please wait</span>
                  <div className="flex items-center space-x-1">
                    <span className="w-1.5 h-1.5 bg-blue-600 rounded-full animate-bounce-dot-1" />
                    <span className="w-1.5 h-1.5 bg-indigo-500 rounded-full animate-bounce-dot-2" />
                    <span className="w-1.5 h-1.5 bg-amber-500 rounded-full animate-bounce-dot-3" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
