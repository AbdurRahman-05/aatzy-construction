import React from 'react';

/**
 * One status pill for the whole admin, using the same words as the app:
 * Live / In review / Hidden for products, Verified / Waiting / Rejected for partners, etc.
 */
export type PillTone = 'green' | 'amber' | 'red' | 'teal' | 'gray' | 'violet' | 'ink';

const TONES: Record<PillTone, string> = {
  green: 'bg-emerald-500/12 text-emerald-700',
  amber: 'bg-amber-500/14 text-amber-700',
  red: 'bg-red-500/12 text-red-700',
  teal: 'bg-cz-accent-soft text-cz-accent-text',
  gray: 'bg-cz-soft text-cz-muted',
  violet: 'bg-violet-500/14 text-violet-700',
  ink: 'bg-cz-ink text-cz-surface',
};

const DOTS: Record<PillTone, string> = {
  green: 'bg-emerald-500',
  amber: 'bg-amber-500',
  red: 'bg-red-500',
  teal: 'bg-cz-accent',
  gray: 'bg-cz-muted',
  violet: 'bg-violet-500',
  ink: 'bg-cz-surface',
};

export function StatusPill({
  tone,
  children,
  dot = true,
  pulse = false,
  className = '',
}: {
  tone: PillTone;
  children: React.ReactNode;
  dot?: boolean;
  pulse?: boolean;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-1 text-[11px] font-bold leading-none ${TONES[tone]} ${className}`}
    >
      {dot && <span className={`h-1.5 w-1.5 rounded-full ${DOTS[tone]} ${pulse ? 'animate-pulse' : ''}`} />}
      {children}
    </span>
  );
}

/** Product status in the app's words. */
export function productPill(status: string) {
  switch (status) {
    case 'Approved':
      return <StatusPill tone="green">Live</StatusPill>;
    case 'Pending':
      return <StatusPill tone="amber" pulse>In review</StatusPill>;
    case 'Rejected':
      return <StatusPill tone="red">Hidden</StatusPill>;
    default:
      return <StatusPill tone="gray">{status}</StatusPill>;
  }
}

export function partnerPill(p: { isVerified: boolean; isRejected: boolean }) {
  if (p.isRejected) return <StatusPill tone="red">Rejected</StatusPill>;
  if (p.isVerified) return <StatusPill tone="green">Verified</StatusPill>;
  return <StatusPill tone="amber" pulse>Waiting</StatusPill>;
}

export function customerPill(isApproved: boolean) {
  return isApproved ? <StatusPill tone="green">Active</StatusPill> : <StatusPill tone="red">Suspended</StatusPill>;
}

export function membershipPill(m: { subscriptionStatus: string; daysLeft: number; subscriptionExpiresAt: string | null }) {
  if (m.subscriptionStatus === 'ACTIVE' && m.daysLeft > 0) {
    return <StatusPill tone={m.daysLeft <= 15 ? 'amber' : 'teal'}>{m.daysLeft}d left</StatusPill>;
  }
  if (m.subscriptionExpiresAt) return <StatusPill tone="red">Expired</StatusPill>;
  return <StatusPill tone="gray" dot={false}>Unpaid</StatusPill>;
}

export function Avatar({ name, size = 40, tone = 'accent' }: { name: string; size?: number; tone?: 'accent' | 'ink' }) {
  const parts = (name || '?').trim().split(/\s+/).filter(Boolean);
  const text = ((parts[0]?.[0] || '?') + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
  return (
    <span
      className={`inline-flex shrink-0 items-center justify-center rounded-2xl font-black ${
        tone === 'accent' ? 'bg-cz-accent-soft text-cz-accent-text' : 'bg-cz-ink text-cz-surface'
      }`}
      style={{ width: size, height: size, fontSize: Math.max(11, size * 0.34) }}
    >
      {text}
    </span>
  );
}
