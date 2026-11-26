'use client';

import { useEffect, useState } from 'react';
import { AlertTriangle, Loader2, Trash2, X } from 'lucide-react';
import Portal from './Portal';

interface ImpactLine {
  label: string;
  count: number;
  kind: 'removed' | 'changed';
}

/**
 * Delete with real consequences listed first and the name typed to confirm.
 * Deleting a partner or customer cascades (quotes, products, projects...), so a plain
 * "Are you sure?" is not enough.
 */
export default function DeleteDialog({
  kind,
  id,
  name,
  onClose,
  onDeleted,
}: {
  kind: 'user' | 'provider';
  id: string;
  name: string;
  onClose: () => void;
  onDeleted: () => void;
}) {
  const [impact, setImpact] = useState<ImpactLine[] | null>(null);
  const [loadError, setLoadError] = useState('');
  const [typed, setTyped] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const noun = kind === 'provider' ? 'partner' : 'customer';
  const confirmText = name.trim();
  const matches = typed.trim().toLowerCase() === confirmText.toLowerCase();

  useEffect(() => {
    let alive = true;
    fetch(`/api/admin/${kind === 'provider' ? 'providers' : 'users'}/${id}?impact=1`)
      .then(r => r.json().then(d => ({ ok: r.ok, d })))
      .then(({ ok, d }) => {
        if (!alive) return;
        if (!ok) setLoadError(d.error || 'Could not check what will be removed.');
        else setImpact(d.impact);
      })
      .catch(() => alive && setLoadError('Could not check what will be removed.'));
    return () => {
      alive = false;
    };
  }, [kind, id]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !busy) {
        e.stopPropagation();
        onClose();
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [busy, onClose]);

  const doDelete = async () => {
    if (!matches || busy) return;
    setBusy(true);
    setError('');
    try {
      const res = await fetch(kind === 'provider' ? `/api/providers/${id}` : `/api/users/${id}`, { method: 'DELETE' });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(data.error || `Could not delete this ${noun}.`);
        setBusy(false);
        return;
      }
      onDeleted();
    } catch {
      setError('Network error. Nothing was deleted.');
      setBusy(false);
    }
  };

  const lines = (impact || []).filter(l => l.count > 0);

  return (
    <Portal>
    <div className="fixed inset-0 z-[80] flex items-center justify-center p-4">
      <div className="cz-fade-in absolute inset-0 bg-black/45 backdrop-blur-sm" onClick={() => !busy && onClose()} />
      <div className="cz-pop relative w-full max-w-md overflow-hidden rounded-3xl border border-cz-line bg-cz-surface shadow-2xl" role="alertdialog" aria-modal="true">
        <div className="flex items-start gap-3 px-6 pt-6">
          <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-red-500/12 text-red-600">
            <AlertTriangle size={20} />
          </span>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-black text-cz-ink">Delete {noun}?</h2>
            <p className="mt-0.5 truncate text-sm text-cz-muted">{name}</p>
          </div>
          <button onClick={onClose} disabled={busy} className="rounded-xl p-1.5 text-cz-muted hover:bg-cz-soft" aria-label="Close">
            <X size={18} />
          </button>
        </div>

        <div className="px-6 py-5">
          <p className="mb-3 text-sm font-semibold text-cz-ink">This cannot be undone. It will also:</p>
          {!impact && !loadError && (
            <div className="flex items-center gap-2 rounded-2xl bg-cz-soft px-4 py-3 text-sm text-cz-muted">
              <Loader2 size={16} className="animate-spin" /> Checking linked records…
            </div>
          )}
          {loadError && <div className="rounded-2xl bg-amber-500/14 px-4 py-3 text-sm font-semibold text-amber-700">{loadError}</div>}
          {impact && (
            <ul className="space-y-1.5">
              <li className="flex items-center gap-3 rounded-2xl bg-cz-soft px-4 py-2.5 text-sm">
                <span className="w-8 text-right font-black text-red-600">1</span>
                <span className="text-cz-ink">{noun} account and login removed</span>
              </li>
              {lines.map(l => (
                <li key={l.label} className="flex items-center gap-3 rounded-2xl bg-cz-soft px-4 py-2.5 text-sm">
                  <span className={`w-8 text-right font-black ${l.kind === 'changed' ? 'text-amber-600' : 'text-red-600'}`}>{l.count}</span>
                  <span className="text-cz-ink">{l.label}</span>
                </li>
              ))}
              {lines.length === 0 && <li className="px-1 text-xs text-cz-muted">No projects, quotes, products or orders are linked.</li>}
            </ul>
          )}

          <label className="mt-5 block text-xs font-bold text-cz-muted">
            Type <span className="font-black text-cz-ink">{confirmText}</span> to confirm
          </label>
          <input
            autoFocus
            value={typed}
            onChange={e => setTyped(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && doDelete()}
            className="cz-input mt-1.5"
            placeholder={confirmText}
            disabled={busy}
          />
          {error && <p className="mt-3 text-sm font-semibold text-red-600">{error}</p>}
        </div>

        <div className="flex gap-2 border-t border-cz-line bg-cz-soft/60 px-6 py-4">
          <button onClick={onClose} disabled={busy} className="flex-1 rounded-2xl border border-cz-line bg-cz-surface py-2.5 text-sm font-bold text-cz-ink hover:bg-cz-soft">
            Cancel
          </button>
          <button
            onClick={doDelete}
            disabled={!matches || busy}
            className="flex flex-1 items-center justify-center gap-2 rounded-2xl bg-red-600 py-2.5 text-sm font-bold text-white transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-40"
          >
            {busy ? <Loader2 size={16} className="animate-spin" /> : <Trash2 size={16} />}
            Delete {noun}
          </button>
        </div>
      </div>
    </div>
    </Portal>
  );
}
