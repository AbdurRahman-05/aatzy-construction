'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Columns3, CornerDownLeft, HardHat, LogOut, Moon, PanelLeftClose, Search, Sun, User } from 'lucide-react';
import { NAV_ITEMS, type SearchIndex } from './nav';

interface PaletteItem {
  id: string;
  group: string;
  label: string;
  hint?: string;
  icon: React.ReactNode;
  keywords: string;
  run: () => void;
}

function matches(haystack: string, q: string): boolean {
  if (!q) return true;
  const h = haystack.toLowerCase();
  return q
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean)
    .every(word => h.includes(word));
}

export default function CommandPalette({
  open,
  onClose,
  index,
  theme,
  onToggleTheme,
  onToggleSidebar,
  onLogout,
  onNavigate,
}: {
  open: boolean;
  onClose: () => void;
  index: SearchIndex;
  theme: 'light' | 'dark';
  onToggleTheme: () => void;
  onToggleSidebar: () => void;
  onLogout: () => void;
  onNavigate: (href: string, label: string) => void;
}) {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [active, setActive] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);

  const go = (href: string, label: string) => {
    onClose();
    onNavigate(href, label);
    router.push(href);
  };

  const items = useMemo<PaletteItem[]>(() => {
    const q = query.trim();
    const out: PaletteItem[] = [];

    // Commands & pages
    const commands: PaletteItem[] = [
      ...NAV_ITEMS.map(n => {
        const Icon = n.icon;
        return {
          id: `nav-${n.id}`,
          group: 'Go to',
          label: n.title,
          hint: n.subtitle,
          icon: <Icon size={16} />,
          keywords: `go open ${n.label} ${n.title} ${n.id}`,
          run: () => go(`/admin?view=${n.id}`, n.title),
        };
      }),
      {
        id: 'cmd-approve',
        group: 'Actions',
        label: 'Review approvals',
        hint: 'Approve or reject waiting partners & products',
        icon: <CornerDownLeft size={16} />,
        keywords: 'approve reject review verify pending kyc',
        run: () => go('/admin?view=pending', 'Approvals inbox'),
      },
      {
        id: 'cmd-theme',
        group: 'Actions',
        label: theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode',
        icon: theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />,
        keywords: 'theme dark light mode night',
        run: () => {
          onClose();
          onToggleTheme();
        },
      },
      {
        id: 'cmd-sidebar',
        group: 'Actions',
        label: 'Collapse / expand sidebar',
        icon: <PanelLeftClose size={16} />,
        keywords: 'sidebar collapse expand menu',
        run: () => {
          onClose();
          onToggleSidebar();
        },
      },
      {
        id: 'cmd-logout',
        group: 'Actions',
        label: 'Log out',
        icon: <LogOut size={16} />,
        keywords: 'logout sign out exit',
        run: () => {
          onClose();
          onLogout();
        },
      },
    ];
    out.push(...commands.filter(c => matches(`${c.label} ${c.keywords}`, q)).slice(0, q ? 5 : 12));

    if (q.length >= 1) {
      const customers = index.users
        .filter(u => matches(`${u.name} ${u.email} ${u.phone}`, q))
        .slice(0, 5)
        .map<PaletteItem>(u => ({
          id: `u-${u.id}`,
          group: 'Customers',
          label: u.name,
          hint: [u.phone, u.email].filter(Boolean).join(' · '),
          icon: <User size={16} />,
          keywords: '',
          run: () => go(`/admin?view=users&open=${u.id}`, u.name),
        }));
      const partners = index.providers
        .filter(p => matches(`${p.name} ${p.owner} ${p.email} ${p.phone} ${p.category}`, q))
        .slice(0, 5)
        .map<PaletteItem>(p => ({
          id: `p-${p.id}`,
          group: 'Partners',
          label: p.name,
          hint: [p.owner, p.category, p.verified ? 'Verified' : 'Not verified'].filter(Boolean).join(' · '),
          icon: <HardHat size={16} />,
          keywords: '',
          run: () => go(`/admin?view=providers&open=${p.id}`, p.name),
        }));
      const projects = index.projects
        .filter(p => matches(`${p.title} ${p.location} ${p.client}`, q))
        .slice(0, 5)
        .map<PaletteItem>(p => ({
          id: `pr-${p.id}`,
          group: 'Projects',
          label: p.title,
          hint: [p.client, p.location, p.stage].filter(Boolean).join(' · '),
          icon: <Columns3 size={16} />,
          keywords: '',
          run: () => go(`/admin?view=projects&open=${p.id}`, p.title),
        }));
      out.push(...customers, ...partners, ...projects);
    }
    return out;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [query, index, theme]);

  useEffect(() => {
    listRef.current?.querySelector(`[data-idx="${active}"]`)?.scrollIntoView({ block: 'nearest' });
  }, [active]);

  if (!open) return null;

  const onKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setActive(a => Math.min(items.length - 1, a + 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setActive(a => Math.max(0, a - 1));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      items[active]?.run();
    } else if (e.key === 'Escape') {
      e.preventDefault();
      onClose();
    }
  };

  let lastGroup = '';

  return (
    <div className="fixed inset-0 z-[70] flex items-start justify-center px-4 pt-[12vh]">
      <div className="cz-fade-in absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="cz-pop relative w-full max-w-xl overflow-hidden rounded-3xl border border-cz-line bg-cz-surface shadow-2xl">
        <div className="flex items-center gap-3 border-b border-cz-line px-5">
          <Search size={18} className="text-cz-muted" />
          <input
            autoFocus
            value={query}
            onChange={e => {
              setQuery(e.target.value);
              setActive(0);
            }}
            onKeyDown={onKeyDown}
            placeholder="Search customers, partners, projects or type a command…"
            className="h-14 flex-1 bg-transparent text-[15px] text-cz-ink outline-none placeholder:text-cz-muted"
          />
          <span className="cz-kbd">Esc</span>
        </div>

        <div ref={listRef} className="cz-scroll max-h-[55vh] overflow-y-auto p-2">
          {items.length === 0 && (
            <div className="px-4 py-10 text-center text-sm text-cz-muted">
              Nothing matches <span className="font-bold text-cz-ink">“{query}”</span>
            </div>
          )}
          {items.map((item, i) => {
            const header = item.group !== lastGroup ? item.group : null;
            lastGroup = item.group;
            return (
              <div key={item.id}>
                {header && <div className="px-3 pb-1 pt-3 text-[10px] font-black uppercase tracking-[0.14em] text-cz-muted">{header}</div>}
                <button
                  data-idx={i}
                  onMouseMove={() => setActive(i)}
                  onClick={() => item.run()}
                  className={`flex w-full items-center gap-3 rounded-2xl px-3 py-2.5 text-left transition ${
                    i === active ? 'bg-cz-accent-soft text-cz-accent-text' : 'text-cz-ink'
                  }`}
                >
                  <span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-xl ${i === active ? 'bg-cz-accent text-white' : 'bg-cz-soft text-cz-muted'}`}>
                    {item.icon}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-bold">{item.label}</span>
                    {item.hint && <span className="block truncate text-xs text-cz-muted">{item.hint}</span>}
                  </span>
                  {i === active && <CornerDownLeft size={14} className="shrink-0 opacity-70" />}
                </button>
              </div>
            );
          })}
        </div>

        <div className="flex items-center gap-4 border-t border-cz-line bg-cz-soft/60 px-5 py-2.5 text-[11px] text-cz-muted">
          <span className="flex items-center gap-1"><span className="cz-kbd">↑</span><span className="cz-kbd">↓</span> move</span>
          <span className="flex items-center gap-1"><span className="cz-kbd">↵</span> open</span>
          <span className="ml-auto flex items-center gap-1"><span className="cz-kbd">Ctrl</span><span className="cz-kbd">K</span> anywhere</span>
        </div>
      </div>
    </div>
  );
}
