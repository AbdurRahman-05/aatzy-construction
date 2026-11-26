'use client';

import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { CheckCircle2, AlertTriangle, Info, X } from 'lucide-react';

type Tone = 'success' | 'error' | 'info';

interface ToastItem {
  id: number;
  message: string;
  tone: Tone;
  actionLabel?: string;
  onAction?: () => void;
  duration: number;
}

interface ToastApi {
  show: (message: string, opts?: { tone?: Tone; actionLabel?: string; onAction?: () => void; duration?: number }) => void;
  /**
   * Gmail-style "do it after a few seconds unless undone".
   * The change is applied locally right away (optimistic), the server request only goes out
   * once the toast expires, so an Undo never sends a notification to the partner/customer.
   */
  deferred: (opts: {
    message: string;
    commit: () => Promise<boolean>;
    undo: () => void;
    failMessage?: string;
    delayMs?: number;
  }) => void;
}

const ToastContext = createContext<ToastApi | null>(null);

export function useToast(): ToastApi {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside <ToastProvider>');
  return ctx;
}

let nextId = 1;

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  // Deferred commits that have not been sent yet - flushed if the page is left.
  const pending = useRef(new Map<number, { timer: ReturnType<typeof setTimeout>; run: () => void }>());

  const dismiss = useCallback((id: number) => {
    setItems(prev => prev.filter(t => t.id !== id));
  }, []);

  const show = useCallback<ToastApi['show']>((message, opts = {}) => {
    const id = nextId++;
    const duration = opts.duration ?? (opts.tone === 'error' ? 6000 : 3500);
    setItems(prev => [...prev.slice(-3), { id, message, tone: opts.tone ?? 'success', actionLabel: opts.actionLabel, onAction: opts.onAction, duration }]);
    setTimeout(() => dismiss(id), duration);
  }, [dismiss]);

  const deferred = useCallback<ToastApi['deferred']>(({ message, commit, undo, failMessage, delayMs = 5000 }) => {
    const id = nextId++;
    const run = () => {
      pending.current.delete(id);
      commit()
        .then(ok => {
          if (!ok) {
            undo();
            show(failMessage || 'That did not go through. Nothing was changed.', { tone: 'error' });
          }
        })
        .catch(() => {
          undo();
          show(failMessage || 'Network error. Nothing was changed.', { tone: 'error' });
        });
    };
    const timer = setTimeout(() => {
      dismiss(id);
      run();
    }, delayMs);
    pending.current.set(id, { timer, run });

    setItems(prev => [
      ...prev.slice(-3),
      {
        id,
        message,
        tone: 'success',
        duration: delayMs,
        actionLabel: 'Undo',
        onAction: () => {
          const p = pending.current.get(id);
          if (p) clearTimeout(p.timer);
          pending.current.delete(id);
          undo();
        },
      },
    ]);
  }, [dismiss, show]);

  // Leaving the admin (or closing the tab) sends any change that is still waiting.
  useEffect(() => {
    const map = pending.current;
    const flush = () => {
      map.forEach(p => {
        clearTimeout(p.timer);
        p.run();
      });
      map.clear();
    };
    window.addEventListener('pagehide', flush);
    return () => {
      window.removeEventListener('pagehide', flush);
      flush();
    };
  }, []);

  return (
    <ToastContext.Provider value={{ show, deferred }}>
      {children}
      <div className="pointer-events-none fixed bottom-5 left-1/2 z-[90] flex w-full max-w-md -translate-x-1/2 flex-col gap-2 px-4">
        {items.map(t => (
          <div
            key={t.id}
            className="cz-pop pointer-events-auto relative flex items-center gap-3 overflow-hidden rounded-2xl bg-cz-hero px-4 py-3 text-sm text-white shadow-2xl ring-1 ring-white/10"
          >
            {t.tone === 'success' && <CheckCircle2 className="h-4.5 w-4.5 shrink-0 text-teal-300" size={18} />}
            {t.tone === 'error' && <AlertTriangle className="shrink-0 text-red-300" size={18} />}
            {t.tone === 'info' && <Info className="shrink-0 text-teal-300" size={18} />}
            <span className="flex-1 font-medium leading-snug">{t.message}</span>
            {t.actionLabel && t.onAction && (
              <button
                onClick={() => {
                  t.onAction?.();
                  dismiss(t.id);
                }}
                className="rounded-lg bg-white/10 px-3 py-1.5 text-xs font-black text-teal-200 hover:bg-white/20"
              >
                {t.actionLabel}
              </button>
            )}
            <button onClick={() => dismiss(t.id)} className="text-white/40 hover:text-white" aria-label="Dismiss">
              <X size={16} />
            </button>
            <span
              className="absolute bottom-0 left-0 h-0.5 bg-teal-400/70"
              style={{ animation: `czToastBar ${t.duration}ms linear forwards` }}
            />
          </div>
        ))}
      </div>
      <style>{`@keyframes czToastBar { from { width: 100%; } to { width: 0%; } }`}</style>
    </ToastContext.Provider>
  );
}
