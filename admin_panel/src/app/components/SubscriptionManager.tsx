'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';

export interface SubscriptionProvider {
  id: string;
  businessName: string;
  ownerName: string;
  email: string;
  phone: string;
  category: string;
  subscriptionStatus: string;
  subscriptionPlan?: string | null;
  subscriptionAmount?: number | null;
  subscriptionStartedAt?: string | null;
  subscriptionExpiresAt?: string | null;
  daysLeft: number;
  razorpayOrderId?: string | null;
  razorpayPaymentId?: string | null;
}

interface SubscriptionManagerProps {
  providers: SubscriptionProvider[];
}

export default function SubscriptionManager({ providers: initialProviders }: SubscriptionManagerProps) {
  const router = useRouter();
  const [providers, setProviders] = useState<SubscriptionProvider[]>(initialProviders);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | 'active' | 'expiring' | 'inactive'>('all');
  const [loadingId, setLoadingId] = useState<string | null>(null);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const activeCount = providers.filter((p) => p.subscriptionStatus === 'ACTIVE' && p.daysLeft > 0).length;
  const expiringCount = providers.filter((p) => p.subscriptionStatus === 'ACTIVE' && p.daysLeft > 0 && p.daysLeft <= 30).length;
  const totalRevenue = activeCount * 5999;

  const filteredProviders = providers.filter((p) => {
    const matchesSearch =
      p.businessName.toLowerCase().includes(search.toLowerCase()) ||
      p.ownerName.toLowerCase().includes(search.toLowerCase()) ||
      p.email.toLowerCase().includes(search.toLowerCase()) ||
      p.phone.includes(search);

    if (!matchesSearch) return false;

    const isActive = p.subscriptionStatus === 'ACTIVE' && p.daysLeft > 0;
    if (filter === 'active') return isActive;
    if (filter === 'expiring') return isActive && p.daysLeft <= 30;
    if (filter === 'inactive') return !isActive;
    return true;
  });

  const handleGrantSubscription = async (providerId: string, days: number, actionName: string) => {
    setLoadingId(providerId);
    setMessage(null);
    try {
      const res = await fetch('/api/admin/subscription/grant', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncodeSafe({ providerId, days, action: 'grant' }),
      });
      const data = await res.json();
      if (res.ok) {
        setMessage({ text: data.message || `Granted ${days} days successfully!`, type: 'success' });
        setProviders((prev) =>
          prev.map((p) => {
            if (p.id === providerId) {
              return {
                ...p,
                subscriptionStatus: 'ACTIVE',
                daysLeft: data.daysLeft,
                subscriptionExpiresAt: data.subscriptionExpiresAt,
              };
            }
            return p;
          })
        );
        router.refresh();
      } else {
        setMessage({ text: data.error || 'Failed to update subscription', type: 'error' });
      }
    } catch (err: any) {
      setMessage({ text: err.message || 'Network error', type: 'error' });
    } finally {
      setLoadingId(null);
    }
  };

  const handleRevokeSubscription = async (providerId: string) => {
    if (!confirm('Are you sure you want to revoke this provider membership?')) return;
    setLoadingId(providerId);
    setMessage(null);
    try {
      const res = await fetch('/api/admin/subscription/grant', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncodeSafe({ providerId, action: 'revoke' }),
      });
      const data = await res.json();
      if (res.ok) {
        setMessage({ text: 'Membership revoked successfully', type: 'success' });
        setProviders((prev) =>
          prev.map((p) => {
            if (p.id === providerId) {
              return {
                ...p,
                subscriptionStatus: 'INACTIVE',
                daysLeft: 0,
              };
            }
            return p;
          })
        );
        router.refresh();
      } else {
        setMessage({ text: data.error || 'Failed to revoke', type: 'error' });
      }
    } catch (err: any) {
      setMessage({ text: err.message || 'Network error', type: 'error' });
    } finally {
      setLoadingId(null);
    }
  };

  return (
    <div className="space-y-8">
      {/* Top Banner Message */}
      {message && (
        <div
          className={`p-4 rounded-2xl flex items-center justify-between text-sm font-semibold transition-all ${
            message.type === 'success' ? 'bg-emerald-50 text-emerald-800 border border-emerald-200' : 'bg-red-50 text-red-800 border border-red-200'
          }`}
        >
          <span>{message.text}</span>
          <button onClick={() => setMessage(null)} className="text-gray-400 hover:text-gray-600 font-bold ml-4">
            ✕
          </button>
        </div>
      )}

      {/* Stats Cards Row */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-gradient-to-br from-blue-600 to-indigo-700 rounded-3xl p-6 text-white shadow-xl shadow-blue-500/20 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between opacity-80 mb-2">
              <span className="text-xs uppercase font-bold tracking-wider">Total Revenue</span>
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 className="text-3xl font-black">₹{totalRevenue.toLocaleString('en-IN')}</h3>
          </div>
          <p className="text-xs opacity-75 mt-4">Calculated from ₹5,999/yr active plans</p>
        </div>

        <div className="bg-white rounded-3xl p-6 border border-gray-100 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs uppercase font-bold tracking-wider text-gray-400">Active Pro Members</span>
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              ✓
            </div>
          </div>
          <h3 className="text-3xl font-black text-gray-900">{activeCount}</h3>
          <p className="text-xs text-emerald-600 font-semibold mt-4">Verified active yearly subscribers</p>
        </div>

        <div className="bg-white rounded-3xl p-6 border border-gray-100 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs uppercase font-bold tracking-wider text-gray-400">Expiring Soon</span>
            <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
              !
            </div>
          </div>
          <h3 className="text-3xl font-black text-gray-900">{expiringCount}</h3>
          <p className="text-xs text-amber-600 font-semibold mt-4">&lt; 30 days left</p>
        </div>

        <div className="bg-white rounded-3xl p-6 border border-gray-100 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs uppercase font-bold tracking-wider text-gray-400">Membership Fee</span>
            <div className="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center font-bold">
              ₹
            </div>
          </div>
          <h3 className="text-3xl font-black text-gray-900">₹5,999</h3>
          <p className="text-xs text-gray-400 font-medium mt-4">Fixed Annual (365 Days) Rate</p>
        </div>
      </div>

      {/* Main Table Container */}
      <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
        {/* Header & Filters */}
        <div className="p-8 border-b border-gray-100 flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gray-50/50">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Provider Membership & Razorpay Subscriptions</h2>
            <p className="text-sm text-gray-500 mt-1">
              Track subscription status, days left, Razorpay transactions, and manage yearly access
            </p>
          </div>

          <div className="flex items-center gap-3">
            <div className="relative">
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search provider..."
                className="pl-9 pr-4 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <svg className="w-4 h-4 text-gray-400 absolute left-3 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>

            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as any)}
              className="py-2 px-3 bg-white border border-gray-200 rounded-xl text-sm font-semibold text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All ({providers.length})</option>
              <option value="active">Active Only ({activeCount})</option>
              <option value="expiring">Expiring Soon ({expiringCount})</option>
              <option value="inactive">Inactive / Expired</option>
            </select>
          </div>
        </div>

        {/* Providers Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/80 border-b border-gray-100">
                <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-wider">Provider / Business</th>
                <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-wider">Category</th>
                <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-wider text-center">Status</th>
                <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-wider text-center">Days Left</th>
                <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-wider">Validity Period</th>
                <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredProviders.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-12 text-center text-gray-400 font-medium">
                    No providers match the filter criteria.
                  </td>
                </tr>
              ) : (
                filteredProviders.map((provider) => {
                  const isActive = provider.subscriptionStatus === 'ACTIVE' && provider.daysLeft > 0;
                  const isExpiring = isActive && provider.daysLeft <= 30;
                  const isLoading = loadingId === provider.id;

                  return (
                    <tr key={provider.id} className="hover:bg-gray-50/60 transition-colors">
                      <td className="p-5">
                        <p className="font-bold text-gray-900">{provider.businessName}</p>
                        <p className="text-xs text-gray-500">{provider.ownerName} • {provider.phone}</p>
                        {provider.razorpayPaymentId && (
                          <span className="inline-block mt-1 text-[10px] font-mono bg-gray-100 text-gray-600 px-2 py-0.5 rounded">
                            ID: {provider.razorpayPaymentId}
                          </span>
                        )}
                      </td>
                      <td className="p-5 text-sm text-gray-600 font-medium">{provider.category}</td>
                      <td className="p-5 text-center">
                        {isActive ? (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">
                            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                            ACTIVE
                          </span>
                        ) : provider.daysLeft === 0 && provider.subscriptionExpiresAt ? (
                          <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-red-100 text-red-800">
                            EXPIRED
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
                            UNPAID
                          </span>
                        )}
                      </td>
                      <td className="p-5 text-center">
                        {isActive ? (
                          <div className="inline-flex flex-col items-center">
                            <span
                              className={`text-base font-black ${
                                isExpiring ? 'text-amber-600' : 'text-emerald-600'
                              }`}
                            >
                              {provider.daysLeft} days
                            </span>
                            <span className="text-[10px] text-gray-400 font-semibold uppercase">Remaining</span>
                          </div>
                        ) : (
                          <span className="text-xs text-gray-400 font-bold">0 Days</span>
                        )}
                      </td>
                      <td className="p-5 text-xs text-gray-500">
                        {provider.subscriptionExpiresAt ? (
                          <>
                            <div className="font-medium text-gray-700">
                              Expires: {new Date(provider.subscriptionExpiresAt).toLocaleDateString('en-IN', {
                                day: 'numeric',
                                month: 'short',
                                year: 'numeric',
                              })}
                            </div>
                            <div className="text-[11px] text-gray-400 mt-0.5">Annual Fee: ₹5,999</div>
                          </>
                        ) : (
                          <span className="text-gray-400 italic">No active subscription</span>
                        )}
                      </td>
                      <td className="p-5 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            disabled={isLoading}
                            onClick={() => handleGrantSubscription(provider.id, 365, 'Add 1 Year')}
                            className="inline-flex items-center gap-1 bg-blue-50 hover:bg-blue-100 text-blue-700 font-bold text-xs px-3 py-1.5 rounded-lg border border-blue-200 transition-colors disabled:opacity-50"
                            title="Grant or Extend 365 Days Membership"
                          >
                            {isLoading ? '...' : '+ 1 Year'}
                          </button>

                          <button
                            disabled={isLoading}
                            onClick={() => handleGrantSubscription(provider.id, 30, 'Add 30 Days')}
                            className="inline-flex items-center gap-1 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold text-xs px-2.5 py-1.5 rounded-lg transition-colors disabled:opacity-50"
                            title="Add 30 Days Grace Extension"
                          >
                            +30d
                          </button>

                          {isActive && (
                            <button
                              disabled={isLoading}
                              onClick={() => handleRevokeSubscription(provider.id)}
                              className="text-red-500 hover:text-red-700 font-semibold text-xs px-2 py-1.5 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50"
                              title="Revoke Membership"
                            >
                              Revoke
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function jsonEncodeSafe(data: any): string {
  return JSON.stringify(data);
}
