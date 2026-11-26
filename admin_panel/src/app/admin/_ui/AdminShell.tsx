'use client';

import { useCallback, useEffect, useState, useSyncExternalStore } from 'react';
import Link from 'next/link';
import { Building2, ExternalLink, LogOut, Menu, Moon, PanelLeftClose, PanelLeftOpen, Search, Sun, X } from 'lucide-react';
import { ToastProvider } from './Toast';
import CommandPalette from './CommandPalette';
import { NAV_ITEMS, SIDEBAR_COOKIE, THEME_COOKIE, navFor, setPrefCookie, type SearchIndex } from './nav';

function announceNavigation(label: string) {
  window.dispatchEvent(new CustomEvent('admin-page-transition-start', { detail: { label: `Opening ${label}…` } }));
}

export default function AdminShell({
  view,
  initialTheme,
  initialCollapsed,
  approvalsCount,
  searchIndex,
  children,
}: {
  view: string;
  initialTheme: 'light' | 'dark';
  initialCollapsed: boolean;
  approvalsCount: number;
  searchIndex: SearchIndex;
  children: React.ReactNode;
}) {
  const [theme, setTheme] = useState<'light' | 'dark'>(initialTheme);
  const [collapsed, setCollapsed] = useState(initialCollapsed);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [pendingView, setPendingView] = useState<string | null>(null);
  const isMac = useSyncExternalStore(
    () => () => {},
    () => /Mac|iPhone|iPad/.test(navigator.platform),
    () => false
  );

  const activeView = pendingView ?? view;
  const current = navFor(view);

  // When the server finishes rendering the new view, drop the optimistic highlight.
  const [lastView, setLastView] = useState(view);
  if (lastView !== view) {
    setLastView(view);
    setPendingView(null);
    setMobileOpen(false);
  }

  const toggleTheme = useCallback(() => {
    setTheme(t => {
      const next = t === 'dark' ? 'light' : 'dark';
      setPrefCookie(THEME_COOKIE, next);
      return next;
    });
  }, []);

  const toggleSidebar = useCallback(() => {
    setCollapsed(c => {
      setPrefCookie(SIDEBAR_COOKIE, c ? '0' : '1');
      return !c;
    });
  }, []);

  const logout = useCallback(async () => {
    await fetch('/api/admin/login', { method: 'DELETE' }).catch(() => null);
    window.location.href = '/admin';
  }, []);

  // Ctrl/⌘+K anywhere, "/" when not typing
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      const typing = !!target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable || target.tagName === 'SELECT');
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setPaletteOpen(o => !o);
      } else if (e.key === '/' && !typing) {
        e.preventDefault();
        setPaletteOpen(true);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const groups = ['Run', 'People', 'Marketplace', 'System'] as const;

  const sidebar = (isMobile: boolean) => {
    const slim = collapsed && !isMobile;
    return (
      <div className="flex h-full flex-col">
        <div className={`flex items-center gap-3 px-4 pb-5 pt-5 ${slim ? 'justify-center px-0' : ''}`}>
          <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-teal-400 to-teal-700 text-white shadow-lg shadow-teal-700/30">
            <Building2 size={20} />
          </span>
          {!slim && (
            <div className="min-w-0">
              <div className="truncate text-[15px] font-black tracking-tight text-cz-ink">Connectzy</div>
              <div className="text-[11px] font-semibold text-cz-muted">Admin console</div>
            </div>
          )}
          {isMobile && (
            <button onClick={() => setMobileOpen(false)} className="ml-auto rounded-xl p-2 text-cz-muted hover:bg-cz-soft" aria-label="Close menu">
              <X size={18} />
            </button>
          )}
        </div>

        <nav className="cz-scroll flex-1 space-y-5 overflow-y-auto px-3">
          {groups.map(group => (
            <div key={group}>
              {!slim && <div className="mb-1.5 px-3 text-[10px] font-black uppercase tracking-[0.16em] text-cz-muted/80">{group}</div>}
              {slim && <div className="mx-auto mb-2 h-px w-6 bg-cz-line" />}
              <div className="space-y-1">
                {NAV_ITEMS.filter(n => n.group === group).map(item => {
                  const Icon = item.icon;
                  const isActive = activeView === item.id;
                  const isLoading = pendingView === item.id && view !== item.id;
                  const badge = item.id === 'pending' && approvalsCount > 0 ? approvalsCount : null;
                  return (
                    <Link
                      key={item.id}
                      href={`/admin?view=${item.id}`}
                      title={slim ? item.label : undefined}
                      onClick={() => {
                        if (view === item.id) return;
                        setPendingView(item.id);
                        announceNavigation(item.title);
                      }}
                      className={`group relative flex items-center gap-3 rounded-2xl py-2.5 text-sm font-semibold transition ${
                        slim ? 'justify-center px-0' : 'px-3'
                      } ${isActive ? 'cz-nav-active bg-cz-hero text-white shadow-lg shadow-black/10' : 'text-cz-muted hover:bg-cz-soft hover:text-cz-ink'}`}
                    >
                      <Icon size={18} className={isActive ? 'text-teal-300' : ''} />
                      {!slim && <span className="flex-1 truncate">{item.label}</span>}
                      {isLoading && !slim && <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white/30 border-t-white" />}
                      {badge !== null && !isLoading && (
                        <span
                          className={`${slim ? 'absolute right-1.5 top-1.5 h-4 min-w-4 px-1 text-[9px]' : 'px-2 py-0.5 text-[10px]'} rounded-full bg-amber-400 font-black leading-4 text-amber-950`}
                        >
                          {badge}
                        </span>
                      )}
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        <div className={`space-y-1 border-t border-cz-line p-3 ${slim ? 'flex flex-col items-center' : ''}`}>
          <Link
            href="/"
            target="_blank"
            title="Open public website"
            className={`flex items-center gap-3 rounded-2xl py-2 text-xs font-semibold text-cz-muted hover:bg-cz-soft hover:text-cz-ink ${slim ? 'justify-center px-2.5' : 'px-3'}`}
          >
            <ExternalLink size={16} />
            {!slim && 'Public website'}
          </Link>
          {!isMobile && (
            <button
              onClick={toggleSidebar}
              title={slim ? 'Expand sidebar' : 'Collapse sidebar'}
              className={`flex w-full items-center gap-3 rounded-2xl py-2 text-xs font-semibold text-cz-muted hover:bg-cz-soft hover:text-cz-ink ${slim ? 'justify-center px-2.5' : 'px-3'}`}
            >
              {slim ? <PanelLeftOpen size={16} /> : <PanelLeftClose size={16} />}
              {!slim && 'Collapse'}
            </button>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="admin-root min-h-screen w-full" data-theme={theme}>
      <ToastProvider>
        <div className="flex min-h-screen">
          {/* Desktop sidebar */}
          <aside
            className={`sticky top-0 hidden h-screen shrink-0 border-r border-cz-line bg-cz-surface transition-[width] duration-200 md:block ${
              collapsed ? 'w-[76px]' : 'w-64'
            }`}
          >
            {sidebar(false)}
          </aside>

          {/* Mobile drawer */}
          {mobileOpen && (
            <div className="fixed inset-0 z-[55] md:hidden">
              <div className="cz-fade-in absolute inset-0 bg-black/40" onClick={() => setMobileOpen(false)} />
              <aside className="cz-pop absolute left-0 top-0 h-full w-72 border-r border-cz-line bg-cz-surface">{sidebar(true)}</aside>
            </div>
          )}

          <div className="flex min-w-0 flex-1 flex-col">
            <header className="sticky top-0 z-40 border-b border-cz-line bg-cz-canvas/85 backdrop-blur-xl">
              <div className="mx-auto flex max-w-[1400px] items-center gap-3 px-4 py-3.5 sm:px-6 lg:px-8">
                <button onClick={() => setMobileOpen(true)} className="rounded-xl p-2 text-cz-muted hover:bg-cz-soft md:hidden" aria-label="Open menu">
                  <Menu size={20} />
                </button>
                <div className="min-w-0 flex-1">
                  <h1 className="truncate text-lg font-black tracking-tight text-cz-ink sm:text-xl">{current.title}</h1>
                  <p className="hidden truncate text-xs font-medium text-cz-muted sm:block">{current.subtitle}</p>
                </div>

                <button
                  onClick={() => setPaletteOpen(true)}
                  className="group flex items-center gap-2.5 rounded-2xl border border-cz-line bg-cz-surface px-3 py-2 text-sm text-cz-muted shadow-sm transition hover:border-cz-accent/50 hover:text-cz-ink lg:w-80"
                >
                  <Search size={16} />
                  <span className="hidden flex-1 text-left lg:inline">Search anything…</span>
                  <span className="hidden items-center gap-1 lg:flex">
                    <span className="cz-kbd">{isMac ? '⌘' : 'Ctrl'}</span>
                    <span className="cz-kbd">K</span>
                  </span>
                </button>

                <button
                  onClick={toggleTheme}
                  className="rounded-2xl border border-cz-line bg-cz-surface p-2.5 text-cz-muted shadow-sm transition hover:text-cz-ink"
                  title={theme === 'dark' ? 'Light mode' : 'Dark mode'}
                  aria-label="Toggle dark mode"
                >
                  {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
                </button>

                <div className="hidden items-center gap-2.5 rounded-2xl border border-cz-line bg-cz-surface py-1.5 pl-1.5 pr-2 shadow-sm sm:flex">
                  <span className="flex h-7 w-7 items-center justify-center rounded-xl bg-cz-accent text-[11px] font-black text-white">AD</span>
                  <span className="text-xs font-bold text-cz-ink">Admin</span>
                  <button onClick={logout} className="rounded-lg p-1 text-cz-muted hover:bg-cz-soft hover:text-red-600" title="Log out" aria-label="Log out">
                    <LogOut size={15} />
                  </button>
                </div>
              </div>
            </header>

            <main className="flex-1">
              <div className="mx-auto w-full max-w-[1400px] px-4 py-6 sm:px-6 lg:px-8 lg:py-8">{children}</div>
            </main>
          </div>
        </div>

        {paletteOpen && (
        <CommandPalette
          open={paletteOpen}
          onClose={() => setPaletteOpen(false)}
          index={searchIndex}
          theme={theme}
          onToggleTheme={toggleTheme}
          onToggleSidebar={toggleSidebar}
          onLogout={logout}
          onNavigate={(_href, label) => announceNavigation(label)}
        />
        )}
      </ToastProvider>
    </div>
  );
}
