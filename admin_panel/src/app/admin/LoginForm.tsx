'use client';

import { useState } from 'react';
import { ArrowRight, Building2, Eye, EyeOff, Inbox, Loader2, Lock, ShieldCheck, Columns3, AlertTriangle } from 'lucide-react';

export default function LoginForm() {
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await fetch('/api/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password }),
      });
      const data = await response.json();

      if (!response.ok) {
        setError(data.error || 'Authentication failed');
        setIsLoading(false);
        return;
      }
      if (data.success) {
        // The server sets a signed HttpOnly session cookie
        window.location.reload();
      }
    } catch {
      setError('Network error. Failed to reach the authentication server.');
      setIsLoading(false);
    }
  };

  return (
    <div className="admin-root grid min-h-screen lg:grid-cols-[1.1fr_1fr]" data-theme="light">
      {/* Brand side */}
      <div className="cz-hero cz-blueprint relative hidden overflow-hidden rounded-none p-12 lg:flex lg:flex-col">
        <div className="pointer-events-none absolute -right-24 -top-24 h-96 w-96 rounded-full bg-teal-400/20 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-32 left-10 h-80 w-80 rounded-full bg-teal-600/20 blur-3xl" />

        <div className="relative flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-teal-400 to-teal-700 shadow-lg shadow-teal-900/40">
            <Building2 size={22} />
          </span>
          <span className="text-lg font-black tracking-tight">Connectzy</span>
        </div>

        <div className="relative mt-auto max-w-md">
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-teal-300">Admin console</p>
          <h1 className="mt-3 text-4xl font-black leading-[1.1] tracking-tight">
            Every site, partner and order - <span className="text-teal-300">one place.</span>
          </h1>
          <div className="mt-8 space-y-3">
            {[
              { icon: Inbox, t: 'Approve new partners and products in seconds' },
              { icon: Columns3, t: 'See every project by stage and spot what is stuck' },
              { icon: ShieldCheck, t: 'KYC, memberships and deletes - with a safety net' },
            ].map(({ icon: Icon, t }) => (
              <div key={t} className="flex items-center gap-3 rounded-2xl bg-white/[0.06] px-4 py-3 ring-1 ring-white/10">
                <Icon size={18} className="shrink-0 text-teal-300" />
                <span className="text-sm font-semibold text-white/85">{t}</span>
              </div>
            ))}
          </div>
        </div>
        <p className="relative mt-10 text-xs text-white/40">© {new Date().getFullYear()} Connectzy · connectzy.app</p>
      </div>

      {/* Form side */}
      <div className="flex items-center justify-center px-5 py-12">
        <div className="w-full max-w-sm">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-teal-400 to-teal-700 text-white">
              <Building2 size={22} />
            </span>
            <span className="text-lg font-black text-cz-ink">Connectzy Admin</span>
          </div>

          <span className="mb-5 flex h-12 w-12 items-center justify-center rounded-2xl bg-cz-accent-soft text-cz-accent-text">
            <Lock size={20} />
          </span>
          <h2 className="text-2xl font-black tracking-tight text-cz-ink">Welcome back</h2>
          <p className="mt-1 text-sm text-cz-muted">Enter the admin password to continue.</p>

          <form onSubmit={handleSubmit} className="mt-8 space-y-4">
            <div>
              <label className="mb-1.5 block text-xs font-bold text-cz-muted">Admin password</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="cz-input py-3 pr-12"
                  required
                  autoFocus
                  disabled={isLoading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 rounded-lg p-1.5 text-cz-muted hover:text-cz-ink"
                  disabled={isLoading}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            {error && (
              <div className="flex items-center gap-2 rounded-2xl bg-red-500/10 px-4 py-3 text-xs font-semibold text-red-700">
                <AlertTriangle size={16} className="shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={isLoading}
              className="flex w-full items-center justify-center gap-2 rounded-2xl bg-cz-hero py-3.5 text-sm font-bold text-white shadow-lg shadow-black/10 transition hover:opacity-90 disabled:opacity-60"
            >
              {isLoading ? <Loader2 size={18} className="animate-spin" /> : <>Log in <ArrowRight size={16} /></>}
            </button>
          </form>
          <p className="mt-6 text-center text-xs text-cz-muted">Too many wrong tries locks login for 15 minutes.</p>
        </div>
      </div>
    </div>
  );
}
