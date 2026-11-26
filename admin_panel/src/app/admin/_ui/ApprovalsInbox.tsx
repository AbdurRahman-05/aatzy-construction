'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft, Briefcase, Check, CheckCircle2, FileText, Globe, HardHat, Image as ImageIcon, Loader2, Mail, MapPin, Package, Phone, ShieldCheck, X,
} from 'lucide-react';
import { useToast } from './Toast';
import { Avatar, StatusPill } from './StatusPill';
import { Field, ImageLightbox, PanelSection } from './SidePanel';
import { inr, shortDate, timeAgo } from './format';

export type InboxItem =
  | {
      kind: 'partner';
      id: string;
      title: string;
      owner: string;
      category: string;
      createdAt: string;
      profileCompletion: number;
    }
  | {
      kind: 'product';
      id: string;
      title: string;
      supplierName: string;
      supplierVerified: boolean;
      category: string;
      createdAt: string;
      image: string | null;
      pricePerUnit: number;
      unitType: string;
      description: string;
      rejectedReason: string | null;
    };

interface PartnerDetail {
  id: string;
  businessName: string;
  ownerName: string;
  email: string;
  phone: string;
  category: string;
  experience: number;
  address: string | null;
  bio: string | null;
  aadharCard: string | null;
  panCard: string | null;
  profileImage: string | null;
  profileCompletion: number;
  businessType: string | null;
  gstNumber: string | null;
  website: string | null;
  createdAt: string;
  portfolioImages: { id: string; title: string; imageData: string }[];
}

const HIDE_REASONS = ['Photo is unclear', 'Price looks wrong', 'Wrong category', 'Not a construction material', 'Duplicate listing'];

type Filter = 'all' | 'partner' | 'product';

export default function ApprovalsInbox({ items }: { items: InboxItem[] }) {
  const router = useRouter();
  const toast = useToast();
  const [removed, setRemoved] = useState<Set<string>>(new Set());
  const [filter, setFilter] = useState<Filter>('all');
  const [selectedKey, setSelectedKey] = useState<string | null>(null);
  const [mobileDetail, setMobileDetail] = useState(false);
  const [doneCount, setDoneCount] = useState(0);
  const [details, setDetails] = useState<Record<string, PartnerDetail | 'error'>>({});
  const [reason, setReason] = useState('');
  const [lightbox, setLightbox] = useState<{ src: string; title: string } | null>(null);
  const reasonRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  const keyOf = (i: InboxItem) => `${i.kind}:${i.id}`;

  const visible = useMemo(
    () => items.filter(i => !removed.has(keyOf(i)) && (filter === 'all' || i.kind === filter)),
    [items, removed, filter]
  );
  const counts = useMemo(() => {
    const left = items.filter(i => !removed.has(keyOf(i)));
    return { all: left.length, partner: left.filter(i => i.kind === 'partner').length, product: left.filter(i => i.kind === 'product').length };
  }, [items, removed]);

  const selected = visible.find(i => keyOf(i) === selectedKey) ?? visible[0] ?? null;
  const selKey = selected ? keyOf(selected) : null;

  // Load partner KYC details for the selected item
  useEffect(() => {
    if (!selected || selected.kind !== 'partner' || details[selected.id]) return;
    let alive = true;
    fetch(`/api/admin/providers/${selected.id}`)
      .then(r => (r.ok ? r.json() : Promise.reject()))
      .then(d => alive && setDetails(prev => ({ ...prev, [selected.id]: d })))
      .catch(() => alive && setDetails(prev => ({ ...prev, [selected.id]: 'error' })));
    return () => {
      alive = false;
    };
  }, [selected, details]);

  const [reasonFor, setReasonFor] = useState<string | null>(selKey);
  if (reasonFor !== selKey) {
    setReasonFor(selKey);
    setReason('');
  }

  useEffect(() => {
    if (selKey) listRef.current?.querySelector(`[data-key="${CSS.escape(selKey)}"]`)?.scrollIntoView({ block: 'nearest' });
  }, [selKey]);

  const move = useCallback(
    (dir: 1 | -1) => {
      if (!visible.length) return;
      const idx = selected ? visible.findIndex(i => keyOf(i) === keyOf(selected)) : -1;
      const next = visible[Math.max(0, Math.min(visible.length - 1, idx + dir))];
      if (next) setSelectedKey(keyOf(next));
    },
    [visible, selected]
  );

  const decide = useCallback(
    (item: InboxItem, decision: 'approve' | 'reject', hideReason?: string) => {
      const key = keyOf(item);
      const idx = visible.findIndex(i => keyOf(i) === key);
      const after = visible.filter(i => keyOf(i) !== key);
      const nextSel = after[Math.min(idx, after.length - 1)];

      setRemoved(prev => new Set(prev).add(key));
      setSelectedKey(nextSel ? keyOf(nextSel) : null);
      setDoneCount(c => c + 1);

      const verb =
        item.kind === 'partner'
          ? decision === 'approve' ? 'Approved partner' : 'Rejected partner'
          : decision === 'approve' ? 'Product is live' : 'Product hidden';

      toast.deferred({
        message: `${verb}: ${item.title}`,
        undo: () => {
          setRemoved(prev => {
            const n = new Set(prev);
            n.delete(key);
            return n;
          });
          setSelectedKey(key);
          setDoneCount(c => Math.max(0, c - 1));
        },
        commit: async () => {
          let res: Response;
          if (item.kind === 'partner') {
            res = await fetch(`/api/providers/${item.id}/${decision}`, { method: 'PATCH' });
          } else {
            res = await fetch(`/api/admin/products/${item.id}`, {
              method: 'PATCH',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(decision === 'approve' ? { status: 'Approved' } : { status: 'Rejected', rejectedReason: hideReason }),
            });
          }
          if (res.ok) router.refresh();
          return res.ok;
        },
        failMessage: `Could not update ${item.title}. It is back in the list.`,
      });
    },
    [visible, toast, router]
  );

  const approve = useCallback(() => selected && decide(selected, 'approve'), [selected, decide]);
  const reject = useCallback(() => {
    if (!selected) return;
    if (selected.kind === 'product') {
      if (!reason.trim()) {
        reasonRef.current?.focus();
        return;
      }
      decide(selected, 'reject', reason.trim());
    } else {
      decide(selected, 'reject');
    }
  }, [selected, reason, decide]);

  // Keyboard: J/K or arrows to move, A approve, R reject
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.metaKey || e.altKey || lightbox) return;
      const t = e.target as HTMLElement | null;
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return;
      if (document.querySelector('[role="dialog"]')) return;
      const k = e.key.toLowerCase();
      if (k === 'j' || e.key === 'ArrowDown') {
        e.preventDefault();
        move(1);
      } else if (k === 'k' || e.key === 'ArrowUp') {
        e.preventDefault();
        move(-1);
      } else if (k === 'a') {
        e.preventDefault();
        approve();
      } else if (k === 'r') {
        e.preventDefault();
        reject();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [move, approve, reject, lightbox]);

  const filters: { id: Filter; label: string; icon: React.ReactNode }[] = [
    { id: 'all', label: 'All', icon: null },
    { id: 'partner', label: 'Partners', icon: <HardHat size={13} /> },
    { id: 'product', label: 'Products', icon: <Package size={13} /> },
  ];

  if (counts.all === 0) {
    return (
      <div className="cz-card flex flex-col items-center justify-center px-6 py-20 text-center">
        <span className="mb-5 flex h-16 w-16 items-center justify-center rounded-3xl bg-cz-accent-soft text-cz-accent-text">
          <CheckCircle2 size={30} />
        </span>
        <h2 className="text-xl font-black text-cz-ink">All caught up</h2>
        <p className="mt-1 max-w-sm text-sm text-cz-muted">
          {doneCount > 0 ? `You cleared ${doneCount} item${doneCount === 1 ? '' : 's'} this session. ` : ''}
          New partner sign-ups and edited products will show up here.
        </p>
      </div>
    );
  }

  const partnerDetail = selected?.kind === 'partner' ? details[selected.id] : undefined;

  return (
    <div className="grid gap-4 lg:grid-cols-[380px_minmax(0,1fr)]">
      {/* Queue */}
      <div className={`cz-card flex flex-col overflow-hidden lg:sticky lg:top-24 lg:max-h-[calc(100vh-8rem)] ${mobileDetail ? 'hidden lg:flex' : 'flex'}`}>
        <div className="border-b border-cz-line p-3">
          <div className="flex gap-1 rounded-2xl bg-cz-soft p-1">
            {filters.map(f => (
              <button
                key={f.id}
                onClick={() => setFilter(f.id)}
                className={`flex flex-1 items-center justify-center gap-1.5 rounded-xl py-1.5 text-xs font-black transition ${
                  filter === f.id ? 'bg-cz-surface text-cz-ink shadow-sm' : 'text-cz-muted hover:text-cz-ink'
                }`}
              >
                {f.icon}
                {f.label}
                <span className={`rounded-md px-1.5 text-[10px] ${filter === f.id ? 'bg-cz-accent text-white' : 'bg-cz-line/70'}`}>{counts[f.id]}</span>
              </button>
            ))}
          </div>
        </div>
        <div ref={listRef} className="cz-scroll flex-1 overflow-y-auto p-2">
          {visible.length === 0 && <div className="px-4 py-10 text-center text-sm text-cz-muted">Nothing in this filter.</div>}
          {visible.map(item => {
            const k = keyOf(item);
            const isSel = k === selKey;
            return (
              <button
                key={k}
                data-key={k}
                onClick={() => {
                  setSelectedKey(k);
                  setMobileDetail(true);
                }}
                className={`mb-1 flex w-full items-center gap-3 rounded-2xl p-3 text-left transition ${
                  isSel ? 'bg-cz-accent-soft ring-1 ring-cz-accent/40' : 'hover:bg-cz-soft'
                }`}
              >
                {item.kind === 'product' && item.image ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={item.image} alt="" className="h-11 w-11 shrink-0 rounded-2xl object-cover" />
                ) : item.kind === 'product' ? (
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-cz-soft text-cz-muted">
                    <Package size={18} />
                  </span>
                ) : (
                  <Avatar name={item.title} size={44} />
                )}
                <span className="min-w-0 flex-1">
                  <span className="flex items-center gap-2">
                    <span className="truncate text-sm font-bold text-cz-ink">{item.title}</span>
                  </span>
                  <span className="block truncate text-xs text-cz-muted">
                    {item.kind === 'partner' ? `${item.owner} · ${item.category}` : `${item.supplierName} · ${inr(item.pricePerUnit)}/${item.unitType}`}
                  </span>
                </span>
                <span className="flex shrink-0 flex-col items-end gap-1">
                  <span className={`rounded-md px-1.5 py-0.5 text-[9px] font-black uppercase tracking-wider ${item.kind === 'partner' ? 'bg-cz-hero text-white' : 'bg-cz-soft text-cz-muted'}`}>
                    {item.kind}
                  </span>
                  <span className="text-[10px] font-semibold text-cz-muted">{timeAgo(item.createdAt)}</span>
                </span>
              </button>
            );
          })}
        </div>
        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 border-t border-cz-line px-4 py-2.5 text-[11px] text-cz-muted">
          <span className="flex items-center gap-1"><span className="cz-kbd">J</span><span className="cz-kbd">K</span> move</span>
          <span className="flex items-center gap-1"><span className="cz-kbd">A</span> approve</span>
          <span className="flex items-center gap-1"><span className="cz-kbd">R</span> reject / hide</span>
          {doneCount > 0 && <span className="ml-auto font-bold text-cz-accent-text">{doneCount} done</span>}
        </div>
      </div>

      {/* Detail */}
      {selected && (
        <div className={`cz-card flex min-h-[60vh] flex-col overflow-hidden ${mobileDetail ? 'flex' : 'hidden lg:flex'}`}>
          <div className="flex items-start gap-4 border-b border-cz-line p-5 sm:p-6">
            <button onClick={() => setMobileDetail(false)} className="rounded-xl p-2 text-cz-muted hover:bg-cz-soft lg:hidden" aria-label="Back to list">
              <ArrowLeft size={18} />
            </button>
            {selected.kind === 'partner' ? (
              <Avatar name={selected.title} size={56} tone="ink" />
            ) : selected.image ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={selected.image} alt="" className="h-14 w-14 rounded-2xl object-cover" />
            ) : (
              <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-cz-soft text-cz-muted"><Package size={22} /></span>
            )}
            <div className="min-w-0 flex-1">
              <div className="mb-1 flex flex-wrap items-center gap-2">
                <StatusPill tone="amber" pulse>{selected.kind === 'partner' ? 'New partner' : 'Product in review'}</StatusPill>
                <span className="text-xs font-semibold text-cz-muted">Submitted {timeAgo(selected.createdAt)}</span>
              </div>
              <h2 className="truncate text-xl font-black tracking-tight text-cz-ink">{selected.title}</h2>
              <p className="truncate text-sm text-cz-muted">
                {selected.kind === 'partner' ? `${selected.owner} · ${selected.category}` : `${selected.category} · by ${selected.supplierName}${selected.supplierVerified ? ' ✓' : ''}`}
              </p>
            </div>
          </div>

          <div className="cz-scroll flex-1 overflow-y-auto p-5 sm:p-6">
            {selected.kind === 'partner' ? (
              <PartnerReview item={selected} detail={partnerDetail} onPreview={setLightbox} />
            ) : (
              <ProductReview item={selected} onPreview={setLightbox} />
            )}
          </div>

          <div className="border-t border-cz-line bg-cz-soft/50 p-4 sm:px-6">
            {selected.kind === 'product' && (
              <div className="mb-3">
                <div className="mb-2 flex flex-wrap gap-1.5">
                  {HIDE_REASONS.map(r => (
                    <button
                      key={r}
                      onClick={() => setReason(r)}
                      className={`rounded-full border px-3 py-1 text-[11px] font-bold transition ${
                        reason === r ? 'border-red-400 bg-red-500/10 text-red-700' : 'border-cz-line bg-cz-surface text-cz-muted hover:text-cz-ink'
                      }`}
                    >
                      {r}
                    </button>
                  ))}
                </div>
                <input
                  ref={reasonRef}
                  value={reason}
                  onChange={e => setReason(e.target.value)}
                  onKeyDown={e => {
                    if (e.key === 'Enter') reject();
                    if (e.key === 'Escape') (e.target as HTMLInputElement).blur();
                  }}
                  placeholder="Reason for hiding (the partner sees this)"
                  className="cz-input"
                />
              </div>
            )}
            <div className="flex gap-2">
              <button
                onClick={reject}
                className="flex flex-1 items-center justify-center gap-2 rounded-2xl border border-red-500/30 bg-cz-surface py-3 text-sm font-bold text-red-600 transition hover:bg-red-500/10"
              >
                <X size={16} />
                {selected.kind === 'partner' ? 'Reject' : 'Hide product'}
                <span className="cz-kbd ml-1 hidden sm:inline-flex">R</span>
              </button>
              <button
                onClick={approve}
                className="flex flex-[1.4] items-center justify-center gap-2 rounded-2xl bg-cz-accent py-3 text-sm font-bold text-white shadow-lg shadow-teal-700/25 transition hover:bg-cz-accent-deep"
              >
                <Check size={16} />
                {selected.kind === 'partner' ? 'Approve partner' : 'Make it live'}
                <span className="ml-1 hidden rounded-md bg-white/20 px-1.5 text-[10px] font-black sm:inline">A</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {lightbox && <ImageLightbox src={lightbox.src} title={lightbox.title} onClose={() => setLightbox(null)} />}
    </div>
  );
}

function CheckRow({ ok, label, note }: { ok: boolean; label: string; note?: string }) {
  return (
    <div className="flex items-center gap-3 rounded-2xl bg-cz-soft px-3.5 py-2.5">
      <span className={`flex h-6 w-6 items-center justify-center rounded-full ${ok ? 'bg-emerald-500 text-white' : 'bg-red-500/15 text-red-600'}`}>
        {ok ? <Check size={13} strokeWidth={3} /> : <X size={13} strokeWidth={3} />}
      </span>
      <span className="flex-1 text-sm font-semibold text-cz-ink">{label}</span>
      {note && <span className="text-xs font-semibold text-cz-muted">{note}</span>}
    </div>
  );
}

function DocTile({ src, title, onPreview }: { src: string | null; title: string; onPreview: (p: { src: string; title: string }) => void }) {
  if (!src) {
    return (
      <div className="flex aspect-video flex-col items-center justify-center gap-1 rounded-2xl border-2 border-dashed border-cz-line text-xs font-bold text-cz-muted">
        <FileText size={18} />
        {title} missing
      </div>
    );
  }
  return (
    <button onClick={() => onPreview({ src, title })} className="group relative aspect-video overflow-hidden rounded-2xl border border-cz-line bg-cz-soft">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={src} alt={title} className="h-full w-full object-cover transition group-hover:scale-105" />
      <span className="absolute bottom-2 left-2 rounded-lg bg-black/60 px-2 py-0.5 text-[10px] font-bold text-white">{title}</span>
    </button>
  );
}

function PartnerReview({
  item,
  detail,
  onPreview,
}: {
  item: Extract<InboxItem, { kind: 'partner' }>;
  detail: PartnerDetail | 'error' | undefined;
  onPreview: (p: { src: string; title: string }) => void;
}) {
  if (detail === 'error') return <p className="text-sm font-semibold text-red-600">Could not load this partner&apos;s documents. Refresh and try again.</p>;
  if (!detail)
    return (
      <div className="flex items-center gap-2 text-sm text-cz-muted">
        <Loader2 size={16} className="animate-spin" /> Loading documents…
      </div>
    );

  return (
    <>
      <PanelSection title="Checklist">
        <div className="grid gap-2 sm:grid-cols-2">
          <CheckRow ok={!!detail.aadharCard} label="Aadhaar card" />
          <CheckRow ok={!!detail.panCard} label="PAN card" />
          <CheckRow ok={!!detail.phone} label="Phone number" note={detail.phone} />
          <CheckRow ok={detail.portfolioImages.length > 0} label="Work photos" note={`${detail.portfolioImages.length}`} />
        </div>
        <div className="mt-3 rounded-2xl bg-cz-soft px-3.5 py-3">
          <div className="mb-1.5 flex justify-between text-xs font-bold">
            <span className="text-cz-muted">Profile complete</span>
            <span className="text-cz-ink">{item.profileCompletion}%</span>
          </div>
          <div className="h-2 overflow-hidden rounded-full bg-cz-line">
            <div className="h-full rounded-full bg-cz-accent transition-all" style={{ width: `${Math.min(100, item.profileCompletion)}%` }} />
          </div>
        </div>
      </PanelSection>

      <PanelSection title="KYC documents">
        <div className="grid grid-cols-2 gap-3">
          <DocTile src={detail.aadharCard} title="Aadhaar" onPreview={onPreview} />
          <DocTile src={detail.panCard} title="PAN" onPreview={onPreview} />
        </div>
      </PanelSection>

      <PanelSection title="Business">
        <div className="grid grid-cols-2 gap-2">
          <Field label="Owner" value={detail.ownerName} />
          <Field label="Experience" value={`${detail.experience} years`} />
          <Field label="Phone" value={<span className="flex items-center gap-1.5"><Phone size={13} />{detail.phone}</span>} />
          <Field label="Business type" value={detail.businessType} />
          <Field label="Email" value={<span className="flex items-center gap-1.5"><Mail size={13} />{detail.email}</span>} wide />
          <Field label="Address" value={detail.address ? <span className="flex items-start gap-1.5"><MapPin size={13} className="mt-0.5 shrink-0" />{detail.address}</span> : null} wide />
          <Field label="GST number" value={detail.gstNumber} />
          <Field label="Website" value={detail.website ? <span className="flex items-center gap-1.5"><Globe size={13} />{detail.website}</span> : null} />
          {detail.bio && <Field label="About" value={<span className="font-normal leading-relaxed">{detail.bio}</span>} wide />}
          <Field label="Signed up" value={shortDate(detail.createdAt)} />
          <Field label="Category" value={<span className="flex items-center gap-1.5"><Briefcase size={13} />{detail.category}</span>} />
        </div>
      </PanelSection>

      <PanelSection title={`Work photos (${detail.portfolioImages.length})`}>
        {detail.portfolioImages.length === 0 ? (
          <div className="flex items-center gap-2 rounded-2xl bg-cz-soft px-4 py-3 text-sm text-cz-muted">
            <ImageIcon size={16} /> No work photos uploaded yet
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {detail.portfolioImages.map(img => (
              <DocTile key={img.id} src={img.imageData} title={img.title || 'Work photo'} onPreview={onPreview} />
            ))}
          </div>
        )}
      </PanelSection>

      <div className="flex items-start gap-2 rounded-2xl bg-cz-accent-soft px-4 py-3 text-xs font-semibold text-cz-accent-text">
        <ShieldCheck size={16} className="mt-0.5 shrink-0" />
        Approving sends the partner a welcome email and lets them quote on customer projects.
      </div>
    </>
  );
}

function ProductReview({
  item,
  onPreview,
}: {
  item: Extract<InboxItem, { kind: 'product' }>;
  onPreview: (p: { src: string; title: string }) => void;
}) {
  return (
    <>
      {item.image ? (
        <button onClick={() => onPreview({ src: item.image!, title: item.title })} className="mb-5 block w-full overflow-hidden rounded-3xl border border-cz-line bg-cz-soft">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={item.image} alt={item.title} className="mx-auto max-h-80 object-contain" />
        </button>
      ) : (
        <div className="mb-5 flex h-40 items-center justify-center rounded-3xl border-2 border-dashed border-cz-line text-sm font-bold text-cz-muted">No photo</div>
      )}
      <div className="mb-5 grid grid-cols-2 gap-2 sm:grid-cols-3">
        <Field label="Price" value={<span className="text-cz-accent-text">{inr(item.pricePerUnit)} / {item.unitType}</span>} />
        <Field label="Category" value={item.category} />
        <Field label="Supplier" value={`${item.supplierName}${item.supplierVerified ? ' ✓' : ''}`} />
      </div>
      <PanelSection title="Description">
        <p className="whitespace-pre-line rounded-2xl bg-cz-soft px-4 py-3 text-sm leading-relaxed text-cz-ink">{item.description || 'No description.'}</p>
      </PanelSection>
      {item.rejectedReason && (
        <div className="rounded-2xl bg-amber-500/14 px-4 py-3 text-xs font-semibold text-amber-700">
          Previously hidden because: “{item.rejectedReason}”. The partner edited it and sent it back for review.
        </div>
      )}
    </>
  );
}
