'use client';

import React, { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Check, EyeOff, Package, Search } from 'lucide-react';
import { useToast } from '../admin/_ui/Toast';
import { productPill } from '../admin/_ui/StatusPill';
import { inr, timeAgo } from '../admin/_ui/format';

export interface ModerationProduct {
  id: string;
  name: string;
  description: string;
  category: string;
  pricePerUnit: number;
  unitType: string;
  image: string | null;
  status: string; // Approved | Pending | Rejected
  rejectedReason: string | null;
  supplierName: string;
  supplierVerified: boolean;
  createdAt: string;
}

type Filter = 'Pending' | 'Approved' | 'Rejected' | 'All';

const FILTER_LABEL: Record<Filter, string> = {
  Pending: 'In review',
  Approved: 'Live',
  Rejected: 'Hidden',
  All: 'All',
};

const HIDE_REASONS = ['Photo is unclear', 'Price looks wrong', 'Wrong category', 'Not a construction material', 'Duplicate listing'];

export default function ProductsModeration({ initialProducts }: { initialProducts: ModerationProduct[] }) {
  const router = useRouter();
  const toast = useToast();
  const [products, setProducts] = useState<ModerationProduct[]>(initialProducts);
  const [filter, setFilter] = useState<Filter>(initialProducts.some(p => p.status === 'Pending') ? 'Pending' : 'All');
  const [search, setSearch] = useState('');
  const [hiding, setHiding] = useState<string | null>(null);
  const [reason, setReason] = useState('');

  const counts = useMemo(
    () => ({
      Pending: products.filter(p => p.status === 'Pending').length,
      Approved: products.filter(p => p.status === 'Approved').length,
      Rejected: products.filter(p => p.status === 'Rejected').length,
      All: products.length,
    }),
    [products]
  );

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    return products.filter(
      p =>
        (filter === 'All' || p.status === filter) &&
        (!q || p.name.toLowerCase().includes(q) || p.supplierName.toLowerCase().includes(q) || p.category.toLowerCase().includes(q))
    );
  }, [products, filter, search]);

  const moderate = (product: ModerationProduct, status: 'Approved' | 'Rejected', rejectedReason?: string) => {
    const before = { status: product.status, rejectedReason: product.rejectedReason };
    const patch = (s: string, r: string | null) => setProducts(prev => prev.map(p => (p.id === product.id ? { ...p, status: s, rejectedReason: r } : p)));
    patch(status, status === 'Rejected' ? rejectedReason ?? null : null);
    setHiding(null);
    setReason('');

    toast.deferred({
      message: status === 'Approved' ? `${product.name} is live` : `${product.name} hidden from customers`,
      undo: () => patch(before.status, before.rejectedReason),
      commit: async () => {
        const res = await fetch(`/api/admin/products/${product.id}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ status, rejectedReason }),
        });
        if (res.ok) router.refresh();
        return res.ok;
      },
      failMessage: `Could not update ${product.name}.`,
    });
  };

  const filters: Filter[] = ['Pending', 'Approved', 'Rejected', 'All'];

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <div className="relative min-w-[220px] flex-1 sm:max-w-sm">
          <Search size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-cz-muted" />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search product, supplier or category" className="cz-input pl-10" />
        </div>
        <div className="flex flex-wrap gap-1 rounded-2xl border border-cz-line bg-cz-surface p-1 shadow-sm">
          {filters.map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-xs font-black transition ${
                filter === f ? 'bg-cz-hero text-white' : 'text-cz-muted hover:text-cz-ink'
              }`}
            >
              {FILTER_LABEL[f]}
              <span className={`rounded-md px-1.5 text-[10px] ${filter === f ? 'bg-white/15' : 'bg-cz-soft'}`}>{counts[f]}</span>
            </button>
          ))}
        </div>
        <p className="w-full text-xs text-cz-muted">
          Products go live as soon as a partner lists them. Hide anything wrong or misleading - the partner sees your reason, and edited products come back to the Approvals inbox.
        </p>
      </div>

      {visible.length === 0 ? (
        <div className="cz-card flex flex-col items-center px-6 py-16 text-center">
          <Package size={28} className="mb-3 text-cz-muted" />
          <p className="text-sm font-semibold text-cz-muted">No products here.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {visible.map(p => (
            <div key={p.id} className="cz-card flex flex-col overflow-hidden">
              <div className="relative flex h-44 items-center justify-center bg-cz-soft">
                {p.image ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={p.image} alt={p.name} className="max-h-full max-w-full object-contain p-3" />
                ) : (
                  <Package size={28} className="text-cz-muted" />
                )}
                <span className="absolute left-3 top-3">{productPill(p.status)}</span>
              </div>
              <div className="flex flex-1 flex-col p-4">
                <h3 className="line-clamp-2 font-bold leading-snug text-cz-ink">{p.name}</h3>
                <p className="mt-1 truncate text-xs text-cz-muted">
                  {p.supplierName}
                  {p.supplierVerified ? ' ✓' : ''} · {p.category} · {timeAgo(p.createdAt)}
                </p>
                <p className="mt-2 text-base font-black text-cz-accent-text">
                  {inr(p.pricePerUnit)} <span className="text-xs font-semibold text-cz-muted">/ {p.unitType}</span>
                </p>
                <p className="mt-2 line-clamp-3 text-xs text-cz-muted">{p.description}</p>
                {p.status === 'Rejected' && p.rejectedReason && (
                  <p className="mt-2 rounded-xl bg-red-500/10 px-3 py-2 text-xs font-semibold text-red-700">Hidden: {p.rejectedReason}</p>
                )}

                {hiding === p.id ? (
                  <div className="mt-auto pt-4">
                    <div className="mb-2 flex flex-wrap gap-1">
                      {HIDE_REASONS.map(r => (
                        <button
                          key={r}
                          onClick={() => setReason(r)}
                          className={`rounded-full border px-2.5 py-0.5 text-[10px] font-bold ${
                            reason === r ? 'border-red-400 bg-red-500/10 text-red-700' : 'border-cz-line text-cz-muted hover:text-cz-ink'
                          }`}
                        >
                          {r}
                        </button>
                      ))}
                    </div>
                    <input
                      autoFocus
                      value={reason}
                      onChange={e => setReason(e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter' && reason.trim()) moderate(p, 'Rejected', reason.trim());
                        if (e.key === 'Escape') setHiding(null);
                      }}
                      placeholder="Reason (partner sees this)"
                      className="cz-input text-xs"
                    />
                    <div className="mt-2 flex gap-2">
                      <button onClick={() => setHiding(null)} className="flex-1 rounded-xl border border-cz-line py-2 text-xs font-bold text-cz-muted hover:bg-cz-soft">
                        Cancel
                      </button>
                      <button
                        disabled={!reason.trim()}
                        onClick={() => moderate(p, 'Rejected', reason.trim())}
                        className="flex-1 rounded-xl bg-red-600 py-2 text-xs font-bold text-white hover:bg-red-700 disabled:opacity-40"
                      >
                        Hide
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="mt-auto flex gap-2 pt-4">
                    {p.status !== 'Approved' && (
                      <button
                        onClick={() => moderate(p, 'Approved')}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-cz-accent py-2 text-xs font-bold text-white hover:bg-cz-accent-deep"
                      >
                        <Check size={14} /> {p.status === 'Rejected' ? 'Show again' : 'Make it live'}
                      </button>
                    )}
                    {p.status !== 'Rejected' && (
                      <button
                        onClick={() => {
                          setHiding(p.id);
                          setReason('');
                        }}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-red-500/30 py-2 text-xs font-bold text-red-600 hover:bg-red-500/10"
                      >
                        <EyeOff size={14} /> Hide
                      </button>
                    )}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
