/** Small formatting helpers shared by the admin screens. */

export function inr(value: number | null | undefined): string {
  const n = Number(value) || 0;
  return `₹${Math.round(n).toLocaleString('en-IN')}`;
}

/** ₹12.4L / ₹1.2Cr style - for tiles where space is tight. */
export function inrCompact(value: number | null | undefined): string {
  const n = Number(value) || 0;
  if (n >= 1e7) return `₹${(n / 1e7).toFixed(n >= 1e8 ? 0 : 1)}Cr`;
  if (n >= 1e5) return `₹${(n / 1e5).toFixed(n >= 1e6 ? 0 : 1)}L`;
  if (n >= 1e3) return `₹${(n / 1e3).toFixed(n >= 1e4 ? 0 : 1)}K`;
  return `₹${Math.round(n)}`;
}

export function daysSince(iso: string | Date | null | undefined): number {
  if (!iso) return 0;
  const t = new Date(iso).getTime();
  if (Number.isNaN(t)) return 0;
  return Math.max(0, Math.floor((Date.now() - t) / 86_400_000));
}

export function timeAgo(iso: string | Date | null | undefined): string {
  if (!iso) return '';
  const t = new Date(iso).getTime();
  if (Number.isNaN(t)) return '';
  const s = Math.max(0, Math.floor((Date.now() - t) / 1000));
  if (s < 60) return 'just now';
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 30) return `${d}d ago`;
  const mo = Math.floor(d / 30);
  if (mo < 12) return `${mo}mo ago`;
  return `${Math.floor(mo / 12)}y ago`;
}

export function shortDate(iso: string | Date | null | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

export function initials(name: string | null | undefined): string {
  const parts = (name || '?').trim().split(/\s+/).filter(Boolean);
  return ((parts[0]?.[0] || '?') + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
}

/** Project stage buckets used by the Projects board and pills. */
export type StageBucket = 'quotes' | 'design' | 'building' | 'hold' | 'signoff' | 'done' | 'cancelled';

export const STAGE_COLUMNS: { id: StageBucket; label: string; hint: string }[] = [
  { id: 'quotes', label: 'Looking for partner', hint: 'Planning, collecting quotes' },
  { id: 'design', label: 'Design', hint: 'Drawings & approvals' },
  { id: 'building', label: 'Building', hint: 'Partner on site' },
  { id: 'hold', label: 'On hold', hint: 'Paused by client or partner' },
  { id: 'signoff', label: 'Awaiting sign-off', hint: 'Partner finished, client to confirm' },
  { id: 'done', label: 'Completed', hint: '' },
  { id: 'cancelled', label: 'Cancelled', hint: '' },
];

export function stageBucket(stage: string | null | undefined, hasAcceptedQuote: boolean): StageBucket {
  const s = (stage || '').toLowerCase().trim();
  if (s === 'cancelled') return 'cancelled';
  if (s === 'completed' || s === 'finished') return 'done';
  if (s.includes('pending approval')) return 'signoff';
  if (s === 'on hold' || s === 'hold' || s === 'paused') return 'hold';
  if (s.includes('track') || s.includes('execut') || hasAcceptedQuote) return 'building';
  if (s.includes('design')) return 'design';
  return 'quotes';
}

export function isClosedBucket(b: StageBucket): boolean {
  return b === 'done' || b === 'cancelled';
}
