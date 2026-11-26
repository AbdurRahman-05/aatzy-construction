'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowUpDown, Ban, Briefcase, Columns3, Globe, Loader2, Mail, MapPin, Phone, Search, ShieldCheck, ShoppingBag, Star, Trash2, UserCheck } from 'lucide-react';
import SidePanel, { Field, ImageLightbox, PanelSection } from './SidePanel';
import DeleteDialog from './DeleteDialog';
import { useToast } from './Toast';
import { Avatar, StatusPill, customerPill, membershipPill, partnerPill } from './StatusPill';
import { inr, inrCompact, shortDate, timeAgo } from './format';

/* ------------------------------------------------------------------ shared */

function Toolbar({
  query,
  setQuery,
  placeholder,
  filters,
  filter,
  setFilter,
  count,
}: {
  query: string;
  setQuery: (s: string) => void;
  placeholder: string;
  filters: { id: string; label: string; count: number }[];
  filter: string;
  setFilter: (s: string) => void;
  count: number;
}) {
  return (
    <div className="mb-4 flex flex-wrap items-center gap-2">
      <div className="relative min-w-[220px] flex-1 sm:max-w-sm">
        <Search size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-cz-muted" />
        <input value={query} onChange={e => setQuery(e.target.value)} placeholder={placeholder} className="cz-input pl-10" />
      </div>
      <div className="flex flex-wrap gap-1 rounded-2xl border border-cz-line bg-cz-surface p-1 shadow-sm">
        {filters.map(f => (
          <button
            key={f.id}
            onClick={() => setFilter(f.id)}
            className={`flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-xs font-black transition ${
              filter === f.id ? 'bg-cz-hero text-white' : 'text-cz-muted hover:text-cz-ink'
            }`}
          >
            {f.label}
            <span className={`rounded-md px-1.5 text-[10px] ${filter === f.id ? 'bg-white/15' : 'bg-cz-soft'}`}>{f.count}</span>
          </button>
        ))}
      </div>
      <span className="ml-auto text-xs font-semibold text-cz-muted">{count} shown</span>
    </div>
  );
}

function useOpenFromUrl(initialOpen?: string) {
  const [openId, setOpenId] = useState<string | null>(initialOpen ?? null);
  const [last, setLast] = useState(initialOpen);
  if (last !== initialOpen) {
    setLast(initialOpen);
    if (initialOpen) setOpenId(initialOpen);
  }
  const close = () => {
    setOpenId(null);
    // Drop ?open= so a refresh does not reopen the panel
    const url = new URL(window.location.href);
    if (url.searchParams.has('open')) {
      url.searchParams.delete('open');
      window.history.replaceState(null, '', url.toString());
    }
  };
  return { openId, setOpenId, close };
}

function Th({ children, className = '', onClick }: { children: React.ReactNode; className?: string; onClick?: () => void }) {
  return (
    <th className={`px-4 py-3 text-[10px] font-black uppercase tracking-[0.12em] text-cz-muted ${className}`}>
      {onClick ? (
        <button onClick={onClick} className="inline-flex items-center gap-1 uppercase tracking-[0.12em] hover:text-cz-ink">
          {children} <ArrowUpDown size={11} />
        </button>
      ) : (
        children
      )}
    </th>
  );
}

function Stat({ label, value, icon }: { label: string; value: React.ReactNode; icon?: React.ReactNode }) {
  return (
    <div className="rounded-2xl bg-cz-soft px-3.5 py-3">
      <div className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider text-cz-muted">
        {icon}
        {label}
      </div>
      <div className="mt-1 text-lg font-black text-cz-ink">{value}</div>
    </div>
  );
}

/* --------------------------------------------------------------- customers */

export interface CustomerRow {
  id: string;
  name: string;
  email: string;
  phone: string;
  isApproved: boolean;
  createdAt: string;
  projects: number;
  orders: number;
}

interface CustomerDetail {
  id: string;
  name: string;
  email: string;
  phone: string;
  isApproved: boolean;
  createdAt: string;
  stats: { projects: number; budget: number; orders: number; reviews: number };
  projects: { id: string; title: string; type: string; location: string; budget: number; stage: string; quotes: number; partner: { id: string; businessName: string } | null }[];
  orders: { id: string; title: string; status: string; quantity: number; unit: string; quotedPrice: number | null; supplier: string; createdAt: string }[];
}

export function CustomersView({ customers, initialOpen }: { customers: CustomerRow[]; initialOpen?: string }) {
  const router = useRouter();
  const toast = useToast();
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState('all');
  const [sort, setSort] = useState<'new' | 'projects'>('new');
  const [overrides, setOverrides] = useState<Record<string, Partial<CustomerRow>>>({});
  const [deleted, setDeleted] = useState<Set<string>>(new Set());
  const { openId, setOpenId, close } = useOpenFromUrl(initialOpen);

  const rows = useMemo(
    () => customers.filter(c => !deleted.has(c.id)).map(c => ({ ...c, ...overrides[c.id] })),
    [customers, overrides, deleted]
  );

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    const list = rows.filter(
      c =>
        (filter === 'all' || (filter === 'active' ? c.isApproved : !c.isApproved)) &&
        (!q || `${c.name} ${c.email} ${c.phone}`.toLowerCase().includes(q))
    );
    return sort === 'projects' ? [...list].sort((a, b) => b.projects - a.projects) : list;
  }, [rows, query, filter, sort]);

  const toggleStatus = (c: CustomerRow) => {
    const next = !c.isApproved;
    setOverrides(o => ({ ...o, [c.id]: { ...o[c.id], isApproved: next } }));
    toast.deferred({
      message: next ? `${c.name} is active again` : `${c.name} suspended - they will be logged out`,
      undo: () => setOverrides(o => ({ ...o, [c.id]: { ...o[c.id], isApproved: c.isApproved } })),
      commit: async () => {
        const res = await fetch(`/api/users/${c.id}/toggle-status`, { method: 'PATCH' });
        if (res.ok) router.refresh();
        return res.ok;
      },
    });
  };

  const open = rows.find(c => c.id === openId) ?? null;

  return (
    <div>
      <Toolbar
        query={query}
        setQuery={setQuery}
        placeholder="Search name, email or phone"
        filters={[
          { id: 'all', label: 'All', count: rows.length },
          { id: 'active', label: 'Active', count: rows.filter(r => r.isApproved).length },
          { id: 'suspended', label: 'Suspended', count: rows.filter(r => !r.isApproved).length },
        ]}
        filter={filter}
        setFilter={setFilter}
        count={visible.length}
      />

      <div className="cz-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-left">
            <thead className="border-b border-cz-line bg-cz-soft/60">
              <tr>
                <Th>Customer</Th>
                <Th>Phone</Th>
                <Th className="text-center" onClick={() => setSort(s => (s === 'projects' ? 'new' : 'projects'))}>Projects</Th>
                <Th className="text-center">Orders</Th>
                <Th onClick={() => setSort('new')}>Joined</Th>
                <Th className="text-right">Status</Th>
              </tr>
            </thead>
            <tbody>
              {visible.map(c => (
                <tr
                  key={c.id}
                  onClick={() => setOpenId(c.id)}
                  className={`cursor-pointer border-b border-cz-line transition last:border-b-0 hover:bg-cz-soft/70 ${openId === c.id ? 'bg-cz-accent-soft/60' : ''}`}
                >
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <Avatar name={c.name} size={38} />
                      <div className="min-w-0">
                        <div className="truncate text-sm font-bold text-cz-ink">{c.name}</div>
                        <div className="truncate text-xs text-cz-muted">{c.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-sm text-cz-ink">{c.phone || <span className="text-cz-muted">—</span>}</td>
                  <td className="px-4 py-3 text-center text-sm font-bold text-cz-ink">{c.projects}</td>
                  <td className="px-4 py-3 text-center text-sm font-bold text-cz-ink">{c.orders}</td>
                  <td className="px-4 py-3 text-xs font-semibold text-cz-muted">{timeAgo(c.createdAt)}</td>
                  <td className="px-4 py-3 text-right">{customerPill(c.isApproved)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {visible.length === 0 && <div className="px-6 py-14 text-center text-sm text-cz-muted">No customers match.</div>}
        </div>
      </div>

      <CustomerPanel
        id={openId}
        row={open}
        onClose={close}
        onToggle={toggleStatus}
        onDeleted={id => {
          setDeleted(d => new Set(d).add(id));
          close();
          toast.show('Customer deleted');
          router.refresh();
        }}
      />
    </div>
  );
}

function CustomerPanel({
  id,
  row,
  onClose,
  onToggle,
  onDeleted,
}: {
  id: string | null;
  row: CustomerRow | null;
  onClose: () => void;
  onToggle: (c: CustomerRow) => void;
  onDeleted: (id: string) => void;
}) {
  // Result is tagged with the id it belongs to, so switching customers never shows stale data
  const [result, setResult] = useState<{ id: string; data?: CustomerDetail; error?: string } | null>(null);
  const data = result && result.id === id ? result.data ?? null : null;
  const error = result && result.id === id ? result.error ?? '' : '';
  const [confirmDelete, setConfirmDelete] = useState(false);

  useEffect(() => {
    if (!id) return;
    let alive = true;
    fetch(`/api/admin/users/${id}`)
      .then(r => r.json().then(d => ({ ok: r.ok, d })))
      .then(({ ok, d }) => alive && setResult(ok ? { id, data: d } : { id, error: d.error || 'Could not load this customer.' }))
      .catch(() => alive && setResult({ id, error: 'Could not load this customer.' }));
    return () => {
      alive = false;
    };
  }, [id]);

  const name = row?.name ?? data?.name ?? 'Customer';
  const isApproved = row?.isApproved ?? data?.isApproved ?? true;

  return (
    <>
      <SidePanel
        open={!!id}
        onClose={onClose}
        header={
          <div className="mb-3 flex items-center gap-3">
            <Avatar name={name} size={52} tone="ink" />
            <div className="min-w-0">
              <div className="truncate text-lg font-black text-cz-ink">{name}</div>
              <div className="mt-0.5 flex items-center gap-2">
                {customerPill(isApproved)}
                {data && <span className="text-xs text-cz-muted">Joined {shortDate(data.createdAt)}</span>}
              </div>
            </div>
          </div>
        }
        footer={
          row && (
            <div className="flex gap-2">
              <button
                onClick={() => onToggle(row)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-2xl py-2.5 text-sm font-bold transition ${
                  isApproved ? 'border border-cz-line bg-cz-surface text-cz-ink hover:bg-cz-soft' : 'bg-cz-accent text-white hover:bg-cz-accent-deep'
                }`}
              >
                {isApproved ? <Ban size={16} /> : <UserCheck size={16} />}
                {isApproved ? 'Suspend' : 'Activate'}
              </button>
              <button
                onClick={() => setConfirmDelete(true)}
                className="flex items-center justify-center gap-2 rounded-2xl border border-red-500/30 px-4 py-2.5 text-sm font-bold text-red-600 transition hover:bg-red-500/10"
              >
                <Trash2 size={16} /> Delete
              </button>
            </div>
          )
        }
      >
        {!data && !error && (
          <div className="flex items-center gap-2 text-sm text-cz-muted">
            <Loader2 size={16} className="animate-spin" /> Loading…
          </div>
        )}
        {error && <p className="text-sm font-semibold text-red-600">{error}</p>}
        {data && (
          <>
            <div className="mb-6 grid grid-cols-3 gap-2">
              <Stat label="Projects" value={data.stats.projects} icon={<Columns3 size={12} />} />
              <Stat label="Budget" value={inrCompact(data.stats.budget)} />
              <Stat label="Orders" value={data.stats.orders} icon={<ShoppingBag size={12} />} />
            </div>

            <PanelSection title="Contact">
              <div className="grid grid-cols-2 gap-2">
                <Field label="Phone" value={data.phone ? <a href={`tel:${data.phone}`} className="flex items-center gap-1.5 hover:text-cz-accent"><Phone size={13} />{data.phone}</a> : null} />
                <Field label="Reviews written" value={data.stats.reviews} />
                <Field label="Email" value={<a href={`mailto:${data.email}`} className="flex items-center gap-1.5 hover:text-cz-accent"><Mail size={13} />{data.email}</a>} wide />
              </div>
            </PanelSection>

            <PanelSection title={`Projects (${data.projects.length})`}>
              {data.projects.length === 0 ? (
                <p className="text-sm text-cz-muted">No projects yet.</p>
              ) : (
                <div className="space-y-2">
                  {data.projects.map(p => (
                    <Link
                      key={p.id}
                      href={`/admin?view=projects&open=${p.id}`}
                      className="block rounded-2xl bg-cz-soft px-4 py-3 transition hover:ring-1 hover:ring-cz-accent/40"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <span className="truncate text-sm font-bold text-cz-ink">{p.title}</span>
                        <span className="shrink-0 text-xs font-black text-cz-accent-text">{inrCompact(p.budget)}</span>
                      </div>
                      <div className="mt-0.5 truncate text-xs text-cz-muted">
                        {p.stage} · {p.partner ? `Partner: ${p.partner.businessName}` : `${p.quotes} quote${p.quotes === 1 ? '' : 's'}`}
                      </div>
                    </Link>
                  ))}
                </div>
              )}
            </PanelSection>

            {data.orders.length > 0 && (
              <PanelSection title="Recent material orders">
                <div className="overflow-hidden rounded-2xl border border-cz-line">
                  {data.orders.map(o => (
                    <div key={o.id} className="flex items-center gap-3 border-b border-cz-line px-4 py-2.5 last:border-b-0">
                      <div className="min-w-0 flex-1">
                        <div className="truncate text-sm font-semibold text-cz-ink">{o.title}</div>
                        <div className="truncate text-xs text-cz-muted">
                          {o.quantity} {o.unit} · {o.supplier} · {timeAgo(o.createdAt)}
                        </div>
                      </div>
                      <StatusPill tone={o.status === 'Completed' || o.status === 'Closed' ? 'green' : o.status === 'Rejected' ? 'red' : 'amber'}>{o.status}</StatusPill>
                    </div>
                  ))}
                </div>
              </PanelSection>
            )}
          </>
        )}
      </SidePanel>
      {confirmDelete && id && (
        <DeleteDialog
          kind="user"
          id={id}
          name={name}
          onClose={() => setConfirmDelete(false)}
          onDeleted={() => {
            setConfirmDelete(false);
            onDeleted(id);
          }}
        />
      )}
    </>
  );
}

/* ---------------------------------------------------------------- partners */

export interface PartnerRow {
  id: string;
  businessName: string;
  ownerName: string;
  email: string;
  phone: string;
  category: string;
  isVerified: boolean;
  isRejected: boolean;
  createdAt: string;
  subscriptionStatus: string;
  daysLeft: number;
  subscriptionExpiresAt: string | null;
  quotes: number;
  products: number;
}

interface PartnerDetail {
  id: string;
  businessName: string;
  ownerName: string;
  email: string;
  phone: string;
  category: string;
  experience: number;
  isVerified: boolean;
  isRejected: boolean;
  address: string | null;
  bio: string | null;
  aadharCard: string | null;
  panCard: string | null;
  profileCompletion: number;
  businessType: string | null;
  gstNumber: string | null;
  website: string | null;
  createdAt: string;
  subscriptionStatus: string;
  subscriptionAmount: number;
  subscriptionStartedAt: string | null;
  subscriptionExpiresAt: string | null;
  razorpayPaymentId: string | null;
  daysLeft: number;
  portfolioImages: { id: string; title: string; imageData: string }[];
  stats: { quotes: number; won: number; wonValue: number; productsLive: number; productsTotal: number; orders: number; reviews: number; rating: number | null };
  projects: { id: string; title: string; stage: string; value: number }[];
}

export function PartnersView({ partners, initialOpen }: { partners: PartnerRow[]; initialOpen?: string }) {
  const router = useRouter();
  const toast = useToast();
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState('all');
  const [overrides, setOverrides] = useState<Record<string, Partial<PartnerRow>>>({});
  const [deleted, setDeleted] = useState<Set<string>>(new Set());
  const { openId, setOpenId, close } = useOpenFromUrl(initialOpen);

  const rows = useMemo(
    () => partners.filter(p => !deleted.has(p.id)).map(p => ({ ...p, ...overrides[p.id] })),
    [partners, overrides, deleted]
  );

  const isMember = (p: PartnerRow) => p.subscriptionStatus === 'ACTIVE' && p.daysLeft > 0;

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    return rows.filter(p => {
      const okFilter =
        filter === 'all' ||
        (filter === 'verified' && p.isVerified) ||
        (filter === 'waiting' && !p.isVerified && !p.isRejected) ||
        (filter === 'rejected' && p.isRejected) ||
        (filter === 'members' && isMember(p));
      return okFilter && (!q || `${p.businessName} ${p.ownerName} ${p.email} ${p.phone} ${p.category}`.toLowerCase().includes(q));
    });
  }, [rows, query, filter]);

  const toggleVerified = (p: PartnerRow) => {
    const next = !p.isVerified;
    setOverrides(o => ({ ...o, [p.id]: { ...o[p.id], isVerified: next, isRejected: next ? false : p.isRejected } }));
    toast.deferred({
      message: next ? `${p.businessName} is verified` : `${p.businessName} is no longer verified`,
      undo: () => setOverrides(o => ({ ...o, [p.id]: { ...o[p.id], isVerified: p.isVerified, isRejected: p.isRejected } })),
      commit: async () => {
        const res = await fetch(`/api/providers/${p.id}/toggle-status`, { method: 'PATCH' });
        if (res.ok) router.refresh();
        return res.ok;
      },
    });
  };

  return (
    <div>
      <Toolbar
        query={query}
        setQuery={setQuery}
        placeholder="Search business, owner, phone or category"
        filters={[
          { id: 'all', label: 'All', count: rows.length },
          { id: 'verified', label: 'Verified', count: rows.filter(r => r.isVerified).length },
          { id: 'waiting', label: 'Waiting', count: rows.filter(r => !r.isVerified && !r.isRejected).length },
          { id: 'rejected', label: 'Rejected', count: rows.filter(r => r.isRejected).length },
          { id: 'members', label: 'Paid members', count: rows.filter(isMember).length },
        ]}
        filter={filter}
        setFilter={setFilter}
        count={visible.length}
      />

      <div className="cz-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[820px] text-left">
            <thead className="border-b border-cz-line bg-cz-soft/60">
              <tr>
                <Th>Partner</Th>
                <Th>Category</Th>
                <Th className="text-center">Quotes</Th>
                <Th className="text-center">Products</Th>
                <Th>Membership</Th>
                <Th className="text-right">Status</Th>
              </tr>
            </thead>
            <tbody>
              {visible.map(p => (
                <tr
                  key={p.id}
                  onClick={() => setOpenId(p.id)}
                  className={`cursor-pointer border-b border-cz-line transition last:border-b-0 hover:bg-cz-soft/70 ${openId === p.id ? 'bg-cz-accent-soft/60' : ''}`}
                >
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <Avatar name={p.businessName} size={38} tone={p.isVerified ? 'accent' : 'ink'} />
                      <div className="min-w-0">
                        <div className="truncate text-sm font-bold text-cz-ink">{p.businessName}</div>
                        <div className="truncate text-xs text-cz-muted">{p.ownerName} · {p.phone}</div>
                      </div>
                    </div>
                  </td>
                  <td className="max-w-xs px-4 py-3"><span className="line-clamp-2 text-xs text-cz-ink" title={p.category}>{p.category}</span></td>
                  <td className="px-4 py-3 text-center text-sm font-bold text-cz-ink">{p.quotes}</td>
                  <td className="px-4 py-3 text-center text-sm font-bold text-cz-ink">{p.products}</td>
                  <td className="px-4 py-3">{membershipPill(p)}</td>
                  <td className="px-4 py-3 text-right">{partnerPill(p)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {visible.length === 0 && <div className="px-6 py-14 text-center text-sm text-cz-muted">No partners match.</div>}
        </div>
      </div>

      <PartnerPanel
        id={openId}
        row={rows.find(p => p.id === openId) ?? null}
        onClose={close}
        onToggle={toggleVerified}
        onDeleted={id => {
          setDeleted(d => new Set(d).add(id));
          close();
          toast.show('Partner deleted');
          router.refresh();
        }}
      />
    </div>
  );
}

function PartnerPanel({
  id,
  row,
  onClose,
  onToggle,
  onDeleted,
}: {
  id: string | null;
  row: PartnerRow | null;
  onClose: () => void;
  onToggle: (p: PartnerRow) => void;
  onDeleted: (id: string) => void;
}) {
  // Result is tagged with the id it belongs to, so switching partners never shows stale data
  const [result, setResult] = useState<{ id: string; data?: PartnerDetail; error?: string } | null>(null);
  const data = result && result.id === id ? result.data ?? null : null;
  const error = result && result.id === id ? result.error ?? '' : '';
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [lightbox, setLightbox] = useState<{ src: string; title: string } | null>(null);

  useEffect(() => {
    if (!id) return;
    let alive = true;
    fetch(`/api/admin/providers/${id}`)
      .then(r => r.json().then(d => ({ ok: r.ok, d })))
      .then(({ ok, d }) => alive && setResult(ok ? { id, data: d } : { id, error: d.error || 'Could not load this partner.' }))
      .catch(() => alive && setResult({ id, error: 'Could not load this partner.' }));
    return () => {
      alive = false;
    };
  }, [id]);

  const name = row?.businessName ?? data?.businessName ?? 'Partner';
  const status = row ?? data;

  return (
    <>
      <SidePanel
        open={!!id}
        onClose={onClose}
        width={580}
        header={
          <div className="mb-3 flex items-center gap-3">
            <Avatar name={name} size={52} tone="ink" />
            <div className="min-w-0">
              <div className="truncate text-lg font-black text-cz-ink">{name}</div>
              <div className="mt-0.5 flex flex-wrap items-center gap-2">
                {status && partnerPill(status)}
                {data && membershipPill(data)}
                {data && <span className="line-clamp-2 basis-full text-xs text-cz-muted" title={data.category}>{data.category}</span>}
              </div>
            </div>
          </div>
        }
        footer={
          row && (
            <div className="flex gap-2">
              <button
                onClick={() => onToggle(row)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-2xl py-2.5 text-sm font-bold transition ${
                  row.isVerified ? 'border border-cz-line bg-cz-surface text-cz-ink hover:bg-cz-soft' : 'bg-cz-accent text-white hover:bg-cz-accent-deep'
                }`}
              >
                {row.isVerified ? <Ban size={16} /> : <ShieldCheck size={16} />}
                {row.isVerified ? 'Remove verification' : 'Verify partner'}
              </button>
              <button
                onClick={() => setConfirmDelete(true)}
                className="flex items-center justify-center gap-2 rounded-2xl border border-red-500/30 px-4 py-2.5 text-sm font-bold text-red-600 transition hover:bg-red-500/10"
              >
                <Trash2 size={16} /> Delete
              </button>
            </div>
          )
        }
      >
        {!data && !error && (
          <div className="flex items-center gap-2 text-sm text-cz-muted">
            <Loader2 size={16} className="animate-spin" /> Loading…
          </div>
        )}
        {error && <p className="text-sm font-semibold text-red-600">{error}</p>}
        {data && (
          <>
            <div className="mb-6 grid grid-cols-3 gap-2">
              <Stat label="Quotes" value={data.stats.quotes} />
              <Stat label="Hired" value={data.stats.won} />
              <Stat label="Work won" value={inrCompact(data.stats.wonValue)} />
              <Stat label="Products" value={`${data.stats.productsLive}/${data.stats.productsTotal}`} />
              <Stat label="Orders" value={data.stats.orders} />
              <Stat label="Rating" value={data.stats.rating ? <span className="flex items-center gap-1">{data.stats.rating}<Star size={14} className="fill-amber-400 text-amber-400" /></span> : '—'} />
            </div>

            <PanelSection title="Contact & business">
              <div className="grid grid-cols-2 gap-2">
                <Field label="Owner" value={data.ownerName} />
                <Field label="Phone" value={<a href={`tel:${data.phone}`} className="flex items-center gap-1.5 hover:text-cz-accent"><Phone size={13} />{data.phone}</a>} />
                <Field label="Email" value={<a href={`mailto:${data.email}`} className="flex items-center gap-1.5 hover:text-cz-accent"><Mail size={13} />{data.email}</a>} wide />
                <Field label="Address" value={data.address ? <span className="flex items-start gap-1.5"><MapPin size={13} className="mt-0.5 shrink-0" />{data.address}</span> : null} wide />
                <Field label="Experience" value={`${data.experience} years`} />
                <Field label="Business type" value={data.businessType ? <span className="flex items-center gap-1.5"><Briefcase size={13} />{data.businessType}</span> : null} />
                <Field label="GST" value={data.gstNumber} />
                <Field label="Website" value={data.website ? <span className="flex items-center gap-1.5"><Globe size={13} />{data.website}</span> : null} />
                <Field label="Profile complete" value={`${data.profileCompletion}%`} />
                <Field label="Joined" value={shortDate(data.createdAt)} />
                {data.bio && <Field label="About" value={<span className="font-normal leading-relaxed">{data.bio}</span>} wide />}
              </div>
            </PanelSection>

            <PanelSection title="Membership">
              <div className="grid grid-cols-2 gap-2">
                <Field label="Status" value={membershipPill(data)} />
                <Field label="Amount" value={inr(data.subscriptionAmount)} />
                <Field label="Started" value={shortDate(data.subscriptionStartedAt)} />
                <Field label="Expires" value={shortDate(data.subscriptionExpiresAt)} />
                {data.razorpayPaymentId && <Field label="Razorpay payment" value={<span className="font-mono text-xs">{data.razorpayPaymentId}</span>} wide />}
              </div>
            </PanelSection>

            {data.projects.length > 0 && (
              <PanelSection title="Hired on">
                <div className="space-y-2">
                  {data.projects.map(p => (
                    <Link key={p.id} href={`/admin?view=projects&open=${p.id}`} className="flex items-center gap-3 rounded-2xl bg-cz-soft px-4 py-2.5 transition hover:ring-1 hover:ring-cz-accent/40">
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-bold text-cz-ink">{p.title}</span>
                        <span className="block truncate text-xs text-cz-muted">{p.stage}</span>
                      </span>
                      <span className="text-xs font-black text-cz-accent-text">{inrCompact(p.value)}</span>
                    </Link>
                  ))}
                </div>
              </PanelSection>
            )}

            <PanelSection title="KYC documents">
              <div className="grid grid-cols-2 gap-3">
                {[
                  { src: data.aadharCard, title: 'Aadhaar' },
                  { src: data.panCard, title: 'PAN' },
                ].map(d =>
                  d.src ? (
                    <button key={d.title} onClick={() => setLightbox({ src: d.src!, title: d.title })} className="group relative aspect-video overflow-hidden rounded-2xl border border-cz-line">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={d.src} alt={d.title} className="h-full w-full object-cover transition group-hover:scale-105" />
                      <span className="absolute bottom-2 left-2 rounded-lg bg-black/60 px-2 py-0.5 text-[10px] font-bold text-white">{d.title}</span>
                    </button>
                  ) : (
                    <div key={d.title} className="flex aspect-video items-center justify-center rounded-2xl border-2 border-dashed border-cz-line text-xs font-bold text-cz-muted">
                      {d.title} missing
                    </div>
                  )
                )}
              </div>
            </PanelSection>

            {data.portfolioImages.length > 0 && (
              <PanelSection title={`Work photos (${data.portfolioImages.length})`}>
                <div className="grid grid-cols-3 gap-2">
                  {data.portfolioImages.map(img => (
                    <button key={img.id} onClick={() => setLightbox({ src: img.imageData, title: img.title || 'Work photo' })} className="aspect-square overflow-hidden rounded-2xl border border-cz-line">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={img.imageData} alt={img.title} className="h-full w-full object-cover transition hover:scale-105" />
                    </button>
                  ))}
                </div>
              </PanelSection>
            )}
          </>
        )}
      </SidePanel>
      {confirmDelete && id && (
        <DeleteDialog
          kind="provider"
          id={id}
          name={name}
          onClose={() => setConfirmDelete(false)}
          onDeleted={() => {
            setConfirmDelete(false);
            onDeleted(id);
          }}
        />
      )}
      {lightbox && <ImageLightbox src={lightbox.src} title={lightbox.title} onClose={() => setLightbox(null)} />}
    </>
  );
}
