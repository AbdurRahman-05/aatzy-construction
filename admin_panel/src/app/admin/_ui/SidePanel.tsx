'use client';

import React, { useEffect } from 'react';
import { X } from 'lucide-react';
import Portal from './Portal';

/** Slide-over panel from the right. Keeps the list behind it in place. */
export default function SidePanel({
  open,
  onClose,
  title,
  subtitle,
  header,
  footer,
  width = 520,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title?: React.ReactNode;
  subtitle?: React.ReactNode;
  header?: React.ReactNode;
  footer?: React.ReactNode;
  width?: number;
  children: React.ReactNode;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <Portal>
    <div className="fixed inset-0 z-[60]">
      <div className="cz-fade-in absolute inset-0 bg-black/30 backdrop-blur-[2px]" onClick={onClose} />
      <aside
        className="cz-slide-in absolute right-0 top-0 flex h-full w-full flex-col border-l border-cz-line bg-cz-surface shadow-2xl"
        style={{ maxWidth: width }}
        role="dialog"
        aria-modal="true"
      >
        <div className="flex items-start gap-3 border-b border-cz-line px-6 py-5">
          <div className="min-w-0 flex-1">
            {header}
            {title && <h2 className="truncate text-lg font-black tracking-tight text-cz-ink">{title}</h2>}
            {subtitle && <div className="mt-0.5 line-clamp-2 text-sm text-cz-muted">{subtitle}</div>}
          </div>
          <button
            onClick={onClose}
            className="rounded-xl p-2 text-cz-muted transition hover:bg-cz-soft hover:text-cz-ink"
            aria-label="Close panel"
          >
            <X size={18} />
          </button>
        </div>
        <div className="cz-scroll flex-1 overflow-y-auto px-6 py-5">{children}</div>
        {footer && <div className="border-t border-cz-line bg-cz-surface px-6 py-4">{footer}</div>}
      </aside>
    </div>
    </Portal>
  );
}

export function PanelSection({ title, children, action }: { title: string; children: React.ReactNode; action?: React.ReactNode }) {
  return (
    <section className="mb-6">
      <div className="mb-2.5 flex items-center justify-between">
        <h3 className="text-[11px] font-black uppercase tracking-[0.12em] text-cz-muted">{title}</h3>
        {action}
      </div>
      {children}
    </section>
  );
}

export function Field({ label, value, wide = false }: { label: string; value: React.ReactNode; wide?: boolean }) {
  return (
    <div className={`rounded-2xl bg-cz-soft px-3.5 py-2.5 ${wide ? 'col-span-2' : ''}`}>
      <div className="text-[10px] font-bold uppercase tracking-wider text-cz-muted">{label}</div>
      <div className="mt-0.5 break-words text-sm font-semibold text-cz-ink">{value || <span className="text-cz-muted">—</span>}</div>
    </div>
  );
}

export function ImageLightbox({ src, title, onClose }: { src: string; title: string; onClose: () => void }) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.stopPropagation();
        onClose();
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [onClose]);

  return (
    <Portal>
    <div className="cz-fade-in fixed inset-0 z-[100] flex cursor-zoom-out flex-col items-center justify-center bg-black/85 p-6 backdrop-blur" onClick={onClose}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={src} alt={title} className="max-h-[80vh] max-w-full rounded-2xl object-contain shadow-2xl" onClick={e => e.stopPropagation()} />
      <p className="mt-4 text-sm font-bold text-white">{title}</p>
    </div>
    </Portal>
  );
}
