'use client';

import React, { useMemo, useState } from 'react';

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

const STATUS_STYLES: Record<string, string> = {
  Approved: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  Pending: 'bg-amber-50 text-amber-700 border-amber-200',
  Rejected: 'bg-red-50 text-red-700 border-red-200',
};

const STATUS_LABEL: Record<string, string> = {
  Approved: 'Live',
  Pending: 'Waiting for review',
  Rejected: 'Hidden',
};

function rupees(value: number): string {
  return `₹${Math.round(value).toLocaleString('en-IN')}`;
}

export default function ProductsModeration({ initialProducts }: { initialProducts: ModerationProduct[] }) {
  const [products, setProducts] = useState<ModerationProduct[]>(initialProducts);
  const [filter, setFilter] = useState<Filter>(
    initialProducts.some(p => p.status === 'Pending') ? 'Pending' : 'All'
  );
  const [search, setSearch] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState('');

  const counts = useMemo(() => ({
    Pending: products.filter(p => p.status === 'Pending').length,
    Approved: products.filter(p => p.status === 'Approved').length,
    Rejected: products.filter(p => p.status === 'Rejected').length,
    All: products.length,
  }), [products]);

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    return products.filter(p =>
      (filter === 'All' || p.status === filter) &&
      (!q || p.name.toLowerCase().includes(q) || p.supplierName.toLowerCase().includes(q) || p.category.toLowerCase().includes(q))
    );
  }, [products, filter, search]);

  const moderate = async (product: ModerationProduct, status: 'Approved' | 'Rejected') => {
    let rejectedReason: string | undefined;
    if (status === 'Rejected') {
      const reason = window.prompt(
        `Why are you hiding "${product.name}"? The partner will see this reason.`,
        product.rejectedReason || ''
      );
      if (reason === null) return;
      if (!reason.trim()) {
        setError('A reason is required to hide a product.');
        return;
      }
      rejectedReason = reason.trim();
    }

    setBusyId(product.id);
    setError('');
    try {
      const res = await fetch(`/api/admin/products/${product.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, rejectedReason }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(data.error || 'Could not update the product.');
        return;
      }
      setProducts(prev => prev.map(p =>
        p.id === product.id ? { ...p, status, rejectedReason: status === 'Rejected' ? rejectedReason ?? null : null } : p
      ));
    } catch {
      setError('Network error while updating the product.');
    } finally {
      setBusyId(null);
    }
  };

  const filters: Filter[] = ['Pending', 'Approved', 'Rejected', 'All'];

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 p-8">
        <div className="flex flex-col md:flex-row md:items-center justify-between pb-6 border-b border-gray-100 mb-6 gap-4">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Material Products</h2>
            <p className="text-sm text-gray-500 mt-1">
              Products go live as soon as a partner lists them. Hide anything wrong or misleading; edited products come back here for review.
            </p>
          </div>
          <input
            type="search"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search product, supplier or category"
            className="w-full md:w-72 px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
          />
        </div>

        <div className="flex flex-wrap gap-2 mb-6">
          {filters.map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-full text-xs font-bold border transition ${
                filter === f
                  ? 'bg-gray-900 text-white border-gray-900'
                  : 'bg-white text-gray-600 border-gray-200 hover:border-gray-400'
              }`}
            >
              {f === 'Approved' ? 'Live' : f === 'Rejected' ? 'Hidden' : f === 'Pending' ? 'Needs review' : 'All'}
              <span className={`ml-2 px-1.5 py-0.5 rounded-md ${filter === f ? 'bg-teal-500 text-white' : 'bg-gray-100 text-gray-500'}`}>
                {counts[f]}
              </span>
            </button>
          ))}
        </div>

        {error && (
          <div className="mb-4 p-4 bg-red-50 text-red-700 text-sm font-semibold rounded-xl border border-red-200">{error}</div>
        )}

        {visible.length === 0 ? (
          <div className="text-center py-16 text-gray-400 text-sm font-semibold">No products here.</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
            {visible.map(p => (
              <div key={p.id} className="rounded-2xl border border-gray-100 overflow-hidden flex flex-col bg-white shadow-sm">
                <div className="h-40 bg-gray-50 flex items-center justify-center">
                  {p.image ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={p.image} alt={p.name} className="max-h-full max-w-full object-contain p-2" />
                  ) : (
                    <span className="text-gray-300 text-xs font-bold">No image</span>
                  )}
                </div>
                <div className="p-4 flex-1 flex flex-col">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-bold text-gray-900 leading-snug">{p.name}</h3>
                    <span className={`shrink-0 text-[10px] font-black px-2 py-1 rounded-full border ${STATUS_STYLES[p.status] || 'bg-gray-50 text-gray-600 border-gray-200'}`}>
                      {STATUS_LABEL[p.status] || p.status}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    {p.supplierName}{p.supplierVerified ? ' ✓' : ''} · {p.category}
                  </p>
                  <p className="text-sm font-black text-teal-700 mt-2">{rupees(p.pricePerUnit)} / {p.unitType}</p>
                  <p className="text-xs text-gray-500 mt-2 line-clamp-3">{p.description}</p>
                  {p.status === 'Rejected' && p.rejectedReason && (
                    <p className="text-xs text-red-600 mt-2 font-semibold">Reason: {p.rejectedReason}</p>
                  )}
                  <div className="mt-auto pt-4 flex gap-2">
                    {p.status !== 'Approved' && (
                      <button
                        disabled={busyId === p.id}
                        onClick={() => moderate(p, 'Approved')}
                        className="flex-1 px-3 py-2 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold disabled:opacity-50"
                      >
                        {p.status === 'Rejected' ? 'Show again' : 'Approve'}
                      </button>
                    )}
                    {p.status !== 'Rejected' && (
                      <button
                        disabled={busyId === p.id}
                        onClick={() => moderate(p, 'Rejected')}
                        className="flex-1 px-3 py-2 rounded-xl border border-red-200 text-red-600 hover:bg-red-50 text-xs font-bold disabled:opacity-50"
                      >
                        Hide
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
