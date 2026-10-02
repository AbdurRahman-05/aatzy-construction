'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';

interface NavItem {
  id: string;
  label: string;
  href: string;
  icon: (active: boolean) => React.ReactNode;
  badge?: number;
}

interface AdminSidebarProps {
  currentView: string;
  pendingApprovalsCount?: number;
}

export default function AdminSidebar({
  currentView,
  pendingApprovalsCount = 0,
}: AdminSidebarProps) {
  const [activeView, setActiveView] = useState(currentView);
  const [navigatingTo, setNavigatingTo] = useState<string | null>(null);

  // Sync state when server-rendered currentView changes
  useEffect(() => {
    setActiveView(currentView);
    setNavigatingTo(null);
  }, [currentView]);

  const navItems: NavItem[] = [
    {
      id: 'dashboard',
      label: 'Project Dashboard',
      href: '/admin?view=dashboard',
      icon: (active) => (
        <svg className={`w-5 h-5 transition-transform duration-200 ${active ? 'scale-110' : 'group-hover:scale-105'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 002 2h2a2 2 0 002-2z" />
        </svg>
      ),
    },
    {
      id: 'recent-actions',
      label: 'Recent Actions',
      href: '/admin?view=recent-actions',
      icon: (active) => (
        <svg className={`w-5 h-5 transition-transform duration-200 ${active ? 'scale-110' : 'group-hover:scale-105'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
      ),
    },
    {
      id: 'pending',
      label: 'Pending Approvals',
      href: '/admin?view=pending',
      badge: pendingApprovalsCount > 0 ? pendingApprovalsCount : undefined,
      icon: (active) => (
        <svg className={`w-5 h-5 transition-transform duration-200 ${active ? 'scale-110' : 'group-hover:scale-105'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
    },
    {
      id: 'users',
      label: 'User Management',
      href: '/admin?view=users',
      icon: (active) => (
        <svg className={`w-5 h-5 transition-transform duration-200 ${active ? 'scale-110' : 'group-hover:scale-105'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      ),
    },
    {
      id: 'providers',
      label: 'Provider Directory',
      href: '/admin?view=providers',
      icon: (active) => (
        <svg className={`w-5 h-5 transition-transform duration-200 ${active ? 'scale-110' : 'group-hover:scale-105'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
        </svg>
      ),
    },
    {
      id: 'subscriptions',
      label: 'Subscriptions',
      href: '/admin?view=subscriptions',
      icon: (active) => (
        <svg className={`w-5 h-5 transition-transform duration-200 ${active ? 'scale-110' : 'group-hover:scale-105'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
        </svg>
      ),
    },
    {
      id: 'ads',
      label: 'Manage Ads',
      href: '/admin?view=ads',
      icon: (active) => (
        <svg className={`w-5 h-5 transition-transform duration-200 ${active ? 'scale-110' : 'group-hover:scale-105'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" />
        </svg>
      ),
    },
  ];

  const handleNavClick = (item: NavItem) => {
    if (activeView === item.id) return;

    setActiveView(item.id);
    setNavigatingTo(item.id);

    // Fire custom page transition event
    if (typeof window !== 'undefined') {
      window.dispatchEvent(
        new CustomEvent('admin-page-transition-start', {
          detail: { label: `Switching to ${item.label}...` },
        })
      );
    }
  };

  return (
    <aside className="w-64 bg-white border-r border-gray-200 py-6 flex flex-col shadow-sm sticky top-[73px] h-[calc(100vh-73px)] select-none">
      <div className="px-4 mb-4">
        <span className="text-[11px] font-extrabold tracking-wider uppercase text-gray-400 px-3">
          Management Views
        </span>
      </div>

      <nav className="flex-1 px-3 space-y-1.5 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = activeView === item.id;
          const isPending = navigatingTo === item.id;

          return (
            <Link
              key={item.id}
              href={item.href}
              onClick={() => handleNavClick(item)}
              className={`group flex items-center justify-between px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all duration-200 relative ${
                isActive
                  ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/25'
                  : 'text-gray-600 hover:bg-gray-100/80 hover:text-gray-900'
              }`}
            >
              <div className="flex items-center space-x-3 min-w-0">
                <span className={isActive ? 'text-white' : 'text-gray-500 group-hover:text-blue-600'}>
                  {item.icon(isActive)}
                </span>
                <span className="truncate">{item.label}</span>
              </div>

              {/* Status indicator: micro spinner when loading, or badge */}
              <div className="flex items-center space-x-1.5 flex-shrink-0">
                {isPending && (
                  <span className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                )}

                {item.badge !== undefined && (
                  <span
                    className={`text-[10px] font-black px-2 py-0.5 rounded-full uppercase tracking-wider ${
                      isActive
                        ? 'bg-white/20 text-white'
                        : 'bg-amber-100 text-amber-800'
                    }`}
                  >
                    {item.badge}
                  </span>
                )}
              </div>
            </Link>
          );
        })}
      </nav>

      {/* Footer Navigation */}
      <div className="px-3 pt-4 border-t border-gray-100 mt-auto space-y-1">
        <Link
          href="/"
          className="flex items-center space-x-3 px-3.5 py-2.5 rounded-xl text-xs font-semibold text-gray-500 hover:text-blue-600 hover:bg-blue-50 transition-colors"
          onClick={() => {
            if (typeof window !== 'undefined') {
              window.dispatchEvent(
                new CustomEvent('admin-page-transition-start', {
                  detail: { label: 'Returning to Portfolio...' },
                })
              );
            }
          }}
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          <span>View Public Website</span>
        </Link>
      </div>
    </aside>
  );
}
