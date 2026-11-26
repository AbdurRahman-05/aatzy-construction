'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { ArrowDownRight, ArrowRight, ArrowUpRight, Clock, Columns3, HardHat, Inbox, Package, ShoppingBag, Sparkles, Users } from 'lucide-react';
import { inr, inrCompact } from './format';

export interface OverviewData {
  events: {
    customers: string[];
    partners: string[];
    projects: string[];
    orders: string[];
    deals: { at: string; amount: number }[];
  };
  now: {
    pendingPartners: number;
    pendingProducts: number;
    oldestPendingDays: number;
    activeProjects: number;
    stuckProjects: number;
    openOrders: number;
    totalCustomers: number;
    totalPartners: number;
    verifiedPartners: number;
    liveProducts: number;
  };
}

type Range = 7 | 30 | 90;
const DAY = 86_400_000;

/** Buckets timestamps into `days` daily slots ending today; also returns the previous period total. */
function series(points: { at: number; v: number }[], days: number) {
  const end = new Date();
  end.setHours(23, 59, 59, 999);
  const endMs = end.getTime();
  const start = endMs - days * DAY;
  const prevStart = start - days * DAY;
  const buckets = new Array(days).fill(0);
  let total = 0;
  let prev = 0;
  for (const p of points) {
    if (p.at > start && p.at <= endMs) {
      const idx = Math.min(days - 1, Math.floor((p.at - start) / DAY));
      buckets[idx] += p.v;
      total += p.v;
    } else if (p.at > prevStart && p.at <= start) {
      prev += p.v;
    }
  }
  return { buckets, total, prev };
}

function toPoints(isoList: string[]) {
  return isoList.map(s => ({ at: new Date(s).getTime(), v: 1 }));
}

function Sparkline({ values, stroke = 'var(--a-accent)', height = 44, fillId }: { values: number[]; stroke?: string; height?: number; fillId: string }) {
  const w = 240;
  const h = height;
  const max = Math.max(1, ...values);
  const step = values.length > 1 ? w / (values.length - 1) : w;
  const pts = values.map((v, i) => [i * step, h - 3 - (v / max) * (h - 8)] as const);
  const line = pts.map(([x, y], i) => `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`).join(' ');
  const area = `${line} L${w},${h} L0,${h} Z`;
  return (
    <svg viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" className="block w-full" style={{ height }} aria-hidden>
      <defs>
        <linearGradient id={fillId} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor={stroke} stopOpacity="0.28" />
          <stop offset="100%" stopColor={stroke} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={area} fill={`url(#${fillId})`} />
      <path d={line} fill="none" stroke={stroke} strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" vectorEffect="non-scaling-stroke" />
    </svg>
  );
}

function Delta({ now, prev, invert = false, onDark = false }: { now: number; prev: number; invert?: boolean; onDark?: boolean }) {
  if (prev === 0 && now === 0) return <span className={`text-xs font-semibold ${onDark ? 'text-white/50' : 'text-cz-muted'}`}>No change</span>;
  if (prev === 0) return <span className={`text-xs font-bold ${onDark ? 'text-teal-300' : 'text-cz-accent-text'}`}>New this period</span>;
  const pct = Math.round(((now - prev) / prev) * 100);
  const up = pct >= 0;
  const good = invert ? !up : up;
  const color = onDark ? (good ? 'text-teal-300' : 'text-red-300') : good ? 'text-emerald-700' : 'text-red-700';
  const Icon = up ? ArrowUpRight : ArrowDownRight;
  return (
    <span className={`inline-flex items-center gap-0.5 text-xs font-bold ${color}`}>
      <Icon size={14} />
      {Math.abs(pct)}% <span className={`font-medium ${onDark ? 'text-white/50' : 'text-cz-muted'}`}>&nbsp;vs previous</span>
    </span>
  );
}

function TileLink({ href, children, className = '' }: { href: string; children: React.ReactNode; className?: string }) {
  return (
    <Link
      href={href}
      onClick={() => window.dispatchEvent(new CustomEvent('admin-page-transition-start', { detail: { label: 'Opening…' } }))}
      className={`group relative block overflow-hidden transition duration-200 hover:-translate-y-0.5 ${className}`}
    >
      {children}
    </Link>
  );
}

export default function OverviewTiles({ data }: { data: OverviewData }) {
  const [range, setRange] = useState<Range>(30);

  const s = useMemo(() => {
    const deals = series(data.events.deals.map(d => ({ at: new Date(d.at).getTime(), v: d.amount })), range);
    const dealCount = series(data.events.deals.map(d => ({ at: new Date(d.at).getTime(), v: 1 })), range);
    const customers = series(toPoints(data.events.customers), range);
    const partners = series(toPoints(data.events.partners), range);
    const projects = series(toPoints(data.events.projects), range);
    const orders = series(toPoints(data.events.orders), range);
    const signups = {
      buckets: customers.buckets.map((v, i) => v + partners.buckets[i]),
      total: customers.total + partners.total,
      prev: customers.prev + partners.prev,
    };
    return { deals, dealCount, customers, partners, projects, orders, signups };
  }, [data, range]);

  const waiting = data.now.pendingPartners + data.now.pendingProducts;
  const label = range === 7 ? 'last 7 days' : range === 30 ? 'last 30 days' : 'last 90 days';

  return (
    <section className="mb-8">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-sm font-semibold text-cz-muted">
          <Sparkles size={16} className="text-cz-accent" />
          Showing the <span className="font-black text-cz-ink">{label}</span>
        </div>
        <div className="flex rounded-2xl border border-cz-line bg-cz-surface p-1 shadow-sm">
          {([7, 30, 90] as Range[]).map(r => (
            <button
              key={r}
              onClick={() => setRange(r)}
              className={`rounded-xl px-3.5 py-1.5 text-xs font-black transition ${range === r ? 'bg-cz-hero text-white' : 'text-cz-muted hover:text-cz-ink'}`}
            >
              {r} days
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {/* Hero tile - deals won */}
        <TileLink href="/admin?view=projects" className="cz-hero cz-blueprint p-6 sm:col-span-2 xl:row-span-2">
          <div className="flex items-start justify-between">
            <div>
              <div className="text-xs font-bold uppercase tracking-[0.14em] text-white/55">Work won on Connectzy</div>
              <div className="mt-2 text-4xl font-black tracking-tight sm:text-5xl">{inrCompact(s.deals.total)}</div>
              <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1">
                <Delta now={s.deals.total} prev={s.deals.prev} onDark />
                <span className="text-xs font-semibold text-white/55">
                  {s.dealCount.total} quote{s.dealCount.total === 1 ? '' : 's'} accepted
                </span>
              </div>
            </div>
            <span className="rounded-2xl bg-white/10 p-2.5 text-teal-300 transition group-hover:bg-white/15">
              <ArrowUpRight size={18} />
            </span>
          </div>
          <div className="mt-6">
            <Sparkline values={s.deals.buckets} stroke="#2DD4BF" height={110} fillId="spark-deals" />
          </div>
          <div className="mt-5 grid grid-cols-3 gap-2">
            {[
              { k: 'Active projects', v: data.now.activeProjects },
              { k: 'Verified partners', v: data.now.verifiedPartners },
              { k: 'Live products', v: data.now.liveProducts },
            ].map(x => (
              <div key={x.k} className="rounded-2xl bg-white/[0.06] px-3 py-2.5 ring-1 ring-white/10">
                <div className="text-xl font-black">{x.v.toLocaleString('en-IN')}</div>
                <div className="text-[11px] font-semibold text-white/55">{x.k}</div>
              </div>
            ))}
          </div>
          <div className="mt-3 text-[11px] text-white/40">Total value of quotes customers accepted ({inr(s.deals.total)})</div>
        </TileLink>

        {/* Approvals */}
        <TileLink
          href="/admin?view=pending"
          className={`rounded-3xl p-5 ${waiting > 0 ? 'bg-amber-400 text-amber-950 shadow-lg shadow-amber-500/20' : 'cz-card'}`}
        >
          <div className="flex items-center justify-between">
            <span className={`flex h-10 w-10 items-center justify-center rounded-2xl ${waiting > 0 ? 'bg-amber-950/10' : 'bg-cz-accent-soft text-cz-accent-text'}`}>
              <Inbox size={18} />
            </span>
            <ArrowRight size={16} className="opacity-50 transition group-hover:translate-x-0.5 group-hover:opacity-100" />
          </div>
          <div className={`mt-4 text-3xl font-black ${waiting > 0 ? '' : 'text-cz-ink'}`}>{waiting}</div>
          <div className={`text-sm font-bold ${waiting > 0 ? '' : 'text-cz-ink'}`}>{waiting > 0 ? 'Waiting for your approval' : 'Approvals - all caught up'}</div>
          <div className={`mt-1 text-xs font-semibold ${waiting > 0 ? 'text-amber-950/70' : 'text-cz-muted'}`}>
            {waiting > 0
              ? `${data.now.pendingPartners} partner${data.now.pendingPartners === 1 ? '' : 's'} · ${data.now.pendingProducts} product${data.now.pendingProducts === 1 ? '' : 's'}${
                  data.now.oldestPendingDays > 0 ? ` · oldest ${data.now.oldestPendingDays}d` : ''
                }`
              : 'Nothing is waiting'}
          </div>
        </TileLink>

        {/* Signups */}
        <TileLink href="/admin?view=users" className="cz-card p-5">
          <div className="flex items-center justify-between">
            <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-cz-accent-soft text-cz-accent-text">
              <Users size={18} />
            </span>
            <Delta now={s.signups.total} prev={s.signups.prev} />
          </div>
          <div className="mt-4 text-3xl font-black text-cz-ink">{s.signups.total}</div>
          <div className="text-sm font-bold text-cz-ink">New sign-ups</div>
          <div className="mt-0.5 text-xs font-semibold text-cz-muted">
            {s.customers.total} customers · {s.partners.total} partners
          </div>
          <div className="mt-3">
            <Sparkline values={s.signups.buckets} fillId="spark-signups" height={36} />
          </div>
        </TileLink>

        {/* Active projects / stuck */}
        <TileLink href="/admin?view=projects" className="cz-card p-5">
          <div className="flex items-center justify-between">
            <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-cz-accent-soft text-cz-accent-text">
              <Columns3 size={18} />
            </span>
            {data.now.stuckProjects > 0 && (
              <span className="inline-flex items-center gap-1 rounded-full bg-red-500/12 px-2.5 py-1 text-[11px] font-black text-red-700">
                <Clock size={12} /> {data.now.stuckProjects} quiet
              </span>
            )}
          </div>
          <div className="mt-4 text-3xl font-black text-cz-ink">{s.projects.total}</div>
          <div className="text-sm font-bold text-cz-ink">Projects started</div>
          <div className="mt-0.5 text-xs font-semibold text-cz-muted">
            {data.now.stuckProjects > 0 ? `${data.now.stuckProjects} active project${data.now.stuckProjects === 1 ? '' : 's'} with no activity for 14+ days` : 'Every active project moved recently'}
          </div>
          <div className="mt-3">
            <Sparkline values={s.projects.buckets} fillId="spark-projects" height={36} />
          </div>
        </TileLink>

        {/* Material orders */}
        <TileLink href="/admin?view=products" className="cz-card p-5">
          <div className="flex items-center justify-between">
            <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-cz-accent-soft text-cz-accent-text">
              <ShoppingBag size={18} />
            </span>
            <Delta now={s.orders.total} prev={s.orders.prev} />
          </div>
          <div className="mt-4 text-3xl font-black text-cz-ink">{s.orders.total}</div>
          <div className="text-sm font-bold text-cz-ink">Material orders</div>
          <div className="mt-0.5 text-xs font-semibold text-cz-muted">{data.now.openOrders} still open</div>
          <div className="mt-3">
            <Sparkline values={s.orders.buckets} fillId="spark-orders" height={36} />
          </div>
        </TileLink>

        {/* Totals strip */}
        <div className="cz-card grid grid-cols-3 divide-x divide-cz-line p-0 sm:col-span-2 xl:col-span-4">
          {[
            { icon: Users, k: 'Customers', v: data.now.totalCustomers, href: '/admin?view=users' },
            { icon: HardHat, k: 'Partners', v: data.now.totalPartners, href: '/admin?view=providers' },
            { icon: Package, k: 'Live products', v: data.now.liveProducts, href: '/admin?view=products' },
          ].map(x => {
            const Icon = x.icon;
            return (
              <Link key={x.k} href={x.href} className="group flex items-center gap-3 px-5 py-4 transition hover:bg-cz-soft/60 first:rounded-l-3xl last:rounded-r-3xl">
                <Icon size={18} className="text-cz-muted transition group-hover:text-cz-accent" />
                <div>
                  <div className="text-xl font-black text-cz-ink">{x.v.toLocaleString('en-IN')}</div>
                  <div className="text-[11px] font-bold uppercase tracking-wider text-cz-muted">{x.k} total</div>
                </div>
              </Link>
            );
          })}
        </div>
      </div>
    </section>
  );
}
