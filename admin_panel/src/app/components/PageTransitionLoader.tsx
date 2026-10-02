'use client';

import React, { useEffect, useState, useTransition, useRef } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';

export default function PageTransitionLoader() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isNavigating, setIsNavigating] = useState(false);
  const [progress, setProgress] = useState(0);
  const [loadingLabel, setLoadingLabel] = useState('Loading...');
  const [showFloatingPill, setShowFloatingPill] = useState(false);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const pillTimerRef = useRef<NodeJS.Timeout | null>(null);
  const progressIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Derive human-friendly view title from a URL
  const getViewTitle = (urlStr: string): string => {
    try {
      const url = new URL(urlStr, window.location.origin);
      const view = url.searchParams.get('view');
      if (view === 'dashboard') return 'Project Dashboard';
      if (view === 'pending') return 'Pending Approvals';
      if (view === 'users') return 'User Management';
      if (view === 'providers') return 'Provider Directory';
      if (view === 'subscriptions') return 'Subscriptions';
      if (view === 'ads') return 'Manage Ads';
      if (url.pathname === '/admin') return 'Admin Hub';
      if (url.pathname === '/') return 'Portfolio Home';
      return 'Next Page';
    } catch {
      return 'Loading...';
    }
  };

  const startTransition = (label: string = 'Loading...') => {
    setIsNavigating(true);
    setProgress(15);
    setLoadingLabel(label);

    // Show floating pill only if navigation takes more than 90ms (prevents flicker on instant cache hits)
    if (pillTimerRef.current) clearTimeout(pillTimerRef.current);
    pillTimerRef.current = setTimeout(() => {
      setShowFloatingPill(true);
    }, 90);

    // Increment progress in realistic steps
    if (progressIntervalRef.current) clearInterval(progressIntervalRef.current);
    progressIntervalRef.current = setInterval(() => {
      setProgress((prev) => {
        if (prev < 40) return prev + 12;
        if (prev < 75) return prev + 6;
        if (prev < 88) return prev + 1.5;
        return prev;
      });
    }, 120);

    // Safety timeout to reset if navigation is aborted
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      finishTransition();
    }, 5000);
  };

  const finishTransition = () => {
    if (progressIntervalRef.current) clearInterval(progressIntervalRef.current);
    if (pillTimerRef.current) clearTimeout(pillTimerRef.current);
    if (timerRef.current) clearTimeout(timerRef.current);

    setProgress(100);
    setTimeout(() => {
      setIsNavigating(false);
      setShowFloatingPill(false);
      setProgress(0);
    }, 280);
  };

  // When pathname or searchParams change, the navigation has completed!
  useEffect(() => {
    finishTransition();
  }, [pathname, searchParams?.toString()]);

  // Global click interceptor to catch Next.js Link and anchor clicks
  useEffect(() => {
    const handleDocumentClick = (e: MouseEvent) => {
      // Don't intercept clicks with modifier keys or secondary mouse button
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) {
        return;
      }

      const target = (e.target as HTMLElement)?.closest('a');
      if (!target) return;

      const href = target.getAttribute('href');
      if (!href || href.startsWith('#') || href.startsWith('mailto:') || href.startsWith('tel:')) {
        return;
      }

      if (target.target === '_blank') return;

      try {
        const targetUrl = new URL(href, window.location.origin);
        const currentUrl = new URL(window.location.href);

        // Only handle internal links
        if (targetUrl.origin !== currentUrl.origin) return;

        // Check if URL is actually different (different path or query params)
        const isDifferent =
          targetUrl.pathname !== currentUrl.pathname ||
          targetUrl.search !== currentUrl.search;

        if (isDifferent) {
          const title = getViewTitle(href);
          startTransition(`Loading ${title}...`);
        }
      } catch {
        // Ignore invalid URLs
      }
    };

    // Custom event listener for manual triggers
    const handleCustomTrigger = (e: Event) => {
      const customEvent = e as CustomEvent<{ label?: string }>;
      startTransition(customEvent.detail?.label || 'Loading...');
    };

    document.addEventListener('click', handleDocumentClick, { capture: true });
    window.addEventListener('admin-page-transition-start', handleCustomTrigger);

    return () => {
      document.removeEventListener('click', handleDocumentClick, { capture: true });
      window.removeEventListener('admin-page-transition-start', handleCustomTrigger);
      if (timerRef.current) clearTimeout(timerRef.current);
      if (pillTimerRef.current) clearTimeout(pillTimerRef.current);
      if (progressIntervalRef.current) clearInterval(progressIntervalRef.current);
    };
  }, []);

  if (!isNavigating && progress === 0) return null;

  return (
    <>
      {/* Top Radiant Progress Bar */}
      <div 
        className="fixed top-0 left-0 right-0 h-[3.5px] z-[99999] pointer-events-none transition-all duration-200 ease-out"
        style={{
          opacity: isNavigating || progress > 0 ? 1 : 0,
        }}
      >
        {/* Glow backdrop track */}
        <div className="absolute inset-0 bg-blue-600/10" />

        {/* Dynamic Progress Indicator */}
        <div
          className="h-full bg-gradient-to-r from-blue-600 via-indigo-500 to-amber-500 shadow-[0_0_12px_rgba(37,99,235,0.7),0_0_4px_rgba(245,158,11,0.6)] transition-all duration-200 ease-out relative overflow-hidden"
          style={{ width: `${progress}%` }}
        >
          {/* Shimmer sweep */}
          <div className="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/40 to-transparent animate-bar-shimmer" />

          {/* Glowing head at the front edge */}
          <div className="absolute right-0 top-0 bottom-0 w-4 bg-white rounded-full shadow-[0_0_8px_#ffffff] animate-pulse" />
        </div>
      </div>

      {/* Floating Glassmorphic Pill Transition Indicator */}
      <div
        className={`fixed top-5 left-1/2 -translate-x-1/2 z-[99998] pointer-events-none transition-all duration-300 ease-out transform ${
          showFloatingPill && isNavigating
            ? 'opacity-100 scale-100 translate-y-0'
            : 'opacity-0 scale-95 -translate-y-3 pointer-events-none'
        }`}
      >
        <div className="flex items-center space-x-3 bg-white/90 backdrop-blur-xl border border-gray-200/80 px-4 py-2 rounded-2xl shadow-xl shadow-blue-900/10">
          {/* Dual ring animated spinner */}
          <div className="relative w-5 h-5 flex items-center justify-center">
            <div className="absolute inset-0 border-2 border-blue-600/20 border-t-blue-600 rounded-full animate-spin" />
            <div className="absolute inset-0.5 border border-amber-500/30 border-b-amber-500 rounded-full animate-spin-reverse" />
          </div>

          {/* Transition label */}
          <span className="text-xs font-semibold text-gray-800 tracking-tight">
            {loadingLabel}
          </span>

          {/* Staggered animated pulse dots */}
          <div className="flex items-center space-x-1 pl-1">
            <span className="w-1.5 h-1.5 bg-blue-600 rounded-full animate-bounce-dot-1" />
            <span className="w-1.5 h-1.5 bg-indigo-500 rounded-full animate-bounce-dot-2" />
            <span className="w-1.5 h-1.5 bg-amber-500 rounded-full animate-bounce-dot-3" />
          </div>
        </div>
      </div>
    </>
  );
}
