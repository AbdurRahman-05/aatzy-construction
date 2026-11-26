'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { Clock, HardHat, Loader2, MapPin, Search, User } from 'lucide-react';
import SidePanel, { Field, PanelSection } from './SidePanel';
import { StatusPill, type PillTone } from './StatusPill';
import { STAGE_COLUMNS, daysSince, inr, inrCompact, isClosedBucket, shortDate, stageBucket, timeAgo, type StageBucket } from './format';

export interface BoardProject {
  id: string;
  title: string;
  type: string;
  location: string;
  budget: number;
  stage: string;
  client: string;
  clientId: string;
  partner: string | null;
  partnerId: string | null;
  quotes: number;
  tasksDone: number;
  tasksTotal: number;
  createdAt: string;
  lastActivity: string;
}

interface ProjectDetail {
  id: string;
  title: string;
  type: string;
  location: string;
  plotSize: number;
  budget: number;
  timeline: string;
  currentStage: string;
  createdAt: string;
  lastActivity: string;
  user: { id: string; name: string; email: string; phone: string };
  quotes: { id: string; estimatedCost: number; timeline: string; isAccepted: boolean; createdAt: string; provider: { id: string; businessName: string; phone: string; isVerified: boolean } }[];
  tasks: { id: string; stage: string; title: string; status: string; duration: number; taskCost: number | null }[];
  updates: { id: string; title: string; status: string; notes: string | null; createdAt: string }[];
}

const QUIET_DAYS = 14;

const COLUMN_TONE: Record<StageBucket, PillTone> = {
  quotes: 'amber',
  design: 'violet',
  building: 'teal',
  hold: 'red',
  signoff: 'amber',
  done: 'green',
  cancelled: 'gray',
};

export default function ProjectsBoard({ projects, initialOpen }: { projects: BoardProject[]; initialOpen?: string }) {
  const [query, setQuery] = useState('');
  const [quietOnly, setQuietOnly] = useState(false);
  const [showClosed, setShowClosed] = useState(false);
  const [openId, setOpenId] = useState<string | null>(initialOpen ?? null);
  const [lastInitial, setLastInitial] = useState(initialOpen);
  if (lastInitial !== initialOpen) {
    setLastInitial(initialOpen);
    if (initialOpen) setOpenId(initialOpen);
  }

  const enriched = useMemo(
    () =>
      projects.map(p => {
        const bucket = stageBucket(p.stage, !!p.partner);
        const quietDays = daysSince(p.lastActivity);
        return { ...p, bucket, quietDays, quiet: !isClosedBucket(bucket) && quietDays >= QUIET_DAYS };
      }),
    [projects]
  );

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return enriched.filter(
      p =>
        (!quietOnly || p.quiet) &&
        (!q || `${p.title} ${p.client} ${p.location} ${p.partner ?? ''} ${p.type}`.toLowerCase().includes(q))
    );
  }, [enriched, query, quietOnly]);

  const quietCount = enriched.filter(p => p.quiet).length;
  const columns = STAGE_COLUMNS.filter(c => showClosed || !isClosedBucket(c.id));

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <div className="relative min-w-[220px] flex-1 sm:max-w-sm">
          <Search size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-cz-muted" />
          <input value={query} onChange={e => setQuery(e.target.value)} placeholder="Search project, client, city or partner" className="cz-input pl-10" />
        </div>
        <button
          onClick={() => setQuietOnly(v => !v)}
          className={`flex items-center gap-1.5 rounded-2xl border px-3.5 py-2.5 text-xs font-black transition ${
            quietOnly ? 'border-red-500/40 bg-red-500/10 text-red-700' : 'border-cz-line bg-cz-surface text-cz-muted hover:text-cz-ink'
          }`}
        >
          <Clock size={14} /> Quiet {QUIET_DAYS}+ days
          <span className="rounded-md bg-red-500/15 px-1.5 text-[10px] text-red-700">{quietCount}</span>
        </button>
        <button
          onClick={() => setShowClosed(v => !v)}
          className={`rounded-2xl border px-3.5 py-2.5 text-xs font-black transition ${
            showClosed ? 'border-cz-accent/40 bg-cz-accent-soft text-cz-accent-text' : 'border-cz-line bg-cz-surface text-cz-muted hover:text-cz-ink'
          }`}
        >
          {showClosed ? 'Hide' : 'Show'} completed & cancelled
        </button>
        <span className="ml-auto text-xs font-semibold text-cz-muted">{filtered.length} projects</span>
      </div>

      <div className="cz-scroll -mx-4 overflow-x-auto px-4 pb-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8">
        <div className="flex gap-3" style={{ minWidth: columns.length * 292 }}>
          {columns.map(col => {
            const cards = filtered.filter(p => p.bucket === col.id).sort((a, b) => b.quietDays - a.quietDays);
            const value = cards.reduce((s, p) => s + (p.budget || 0), 0);
            return (
              <div key={col.id} className="flex w-[280px] shrink-0 flex-col rounded-3xl bg-cz-soft/70 p-2 ring-1 ring-cz-line">
                <div className="px-2.5 pb-2.5 pt-2">
                  <div className="flex items-center gap-2">
                    <StatusPill tone={COLUMN_TONE[col.id]}>{col.label}</StatusPill>
                    <span className="ml-auto text-xs font-black text-cz-ink">{cards.length}</span>
                  </div>
                  <div className="mt-1.5 flex justify-between text-[11px] font-semibold text-cz-muted">
                    <span>{col.hint}</span>
                    {value > 0 && <span>{inrCompact(value)}</span>}
                  </div>
                </div>
                <div className="cz-scroll flex max-h-[calc(100vh-17rem)] flex-col gap-2 overflow-y-auto">
                  {cards.length === 0 && <div className="rounded-2xl border-2 border-dashed border-cz-line px-3 py-6 text-center text-xs font-semibold text-cz-muted">Empty</div>}
                  {cards.map(p => (
                    <button
                      key={p.id}
                      onClick={() => setOpenId(p.id)}
                      className={`rounded-2xl border bg-cz-surface p-3.5 text-left shadow-sm transition hover:-translate-y-0.5 hover:shadow-md ${
                        p.quiet ? 'border-red-500/40' : 'border-cz-line'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <span className="line-clamp-2 text-sm font-bold leading-snug text-cz-ink">{p.title}</span>
                        <span className="shrink-0 text-xs font-black text-cz-accent-text">{inrCompact(p.budget)}</span>
                      </div>
                      <div className="mt-1.5 flex items-center gap-1 truncate text-xs text-cz-muted">
                        <User size={12} className="shrink-0" /> <span className="truncate">{p.client}</span>
                        {p.location && (
                          <>
                            <span className="opacity-40">·</span>
                            <MapPin size={12} className="shrink-0" /> <span className="truncate">{p.location}</span>
                          </>
                        )}
                      </div>
                      <div className="mt-2 flex items-center gap-1.5 truncate text-xs font-semibold">
                        <HardHat size={12} className="shrink-0 text-cz-muted" />
                        {p.partner ? (
                          <span className="truncate text-cz-ink">{p.partner}</span>
                        ) : (
                          <span className="text-amber-700">{p.quotes} quote{p.quotes === 1 ? '' : 's'} so far</span>
                        )}
                      </div>
                      {p.tasksTotal > 0 && (
                        <div className="mt-2.5">
                          <div className="h-1.5 overflow-hidden rounded-full bg-cz-soft">
                            <div className="h-full rounded-full bg-cz-accent" style={{ width: `${Math.round((p.tasksDone / p.tasksTotal) * 100)}%` }} />
                          </div>
                          <div className="mt-1 text-[10px] font-semibold text-cz-muted">
                            {p.tasksDone}/{p.tasksTotal} tasks done
                          </div>
                        </div>
                      )}
                      <div className={`mt-2 flex items-center gap-1 text-[10px] font-bold ${p.quiet ? 'text-red-600' : 'text-cz-muted'}`}>
                        <Clock size={11} />
                        {p.quiet ? `No activity for ${p.quietDays} days` : `Active ${timeAgo(p.lastActivity)}`}
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <ProjectPanel id={openId} onClose={() => setOpenId(null)} />
    </div>
  );
}

function ProjectPanel({ id, onClose }: { id: string | null; onClose: () => void }) {
  // Result is tagged with the id it belongs to, so switching projects never shows stale data
  const [result, setResult] = useState<{ id: string; data?: ProjectDetail; error?: string } | null>(null);
  const data = result && result.id === id ? result.data ?? null : null;
  const error = result && result.id === id ? result.error ?? '' : '';

  useEffect(() => {
    if (!id) return;
    let alive = true;
    fetch(`/api/admin/projects/${id}`)
      .then(r => r.json().then(d => ({ ok: r.ok, d })))
      .then(({ ok, d }) => {
        if (!alive) return;
        setResult(ok ? { id, data: d } : { id, error: d.error || 'Could not load the project.' });
      })
      .catch(() => alive && setResult({ id, error: 'Could not load the project.' }));
    return () => {
      alive = false;
    };
  }, [id]);

  const accepted = data?.quotes.find(q => q.isAccepted);
  const done = data?.tasks.filter(t => (t.status || '').toLowerCase() === 'completed').length ?? 0;

  return (
    <SidePanel
      open={!!id}
      onClose={onClose}
      width={560}
      title={data?.title ?? (error ? 'Project' : 'Loading…')}
      subtitle={data ? <span title={data.type}>{data.location} · {data.type}</span> : undefined}
      header={data ? <div className="mb-1.5"><StatusPill tone={COLUMN_TONE[stageBucket(data.currentStage, !!accepted)]}>{data.currentStage}</StatusPill></div> : undefined}
    >
      {!data && !error && (
        <div className="flex items-center gap-2 text-sm text-cz-muted">
          <Loader2 size={16} className="animate-spin" /> Loading project…
        </div>
      )}
      {error && <p className="text-sm font-semibold text-red-600">{error}</p>}
      {data && (
        <>
          <div className="mb-6 grid grid-cols-2 gap-2 sm:grid-cols-3">
            <Field label="Budget" value={inr(data.budget)} />
            <Field label="Plot size" value={data.plotSize ? `${data.plotSize.toLocaleString('en-IN')} sq ft` : null} />
            <Field label="Timeline" value={data.timeline} />
            <Field label="Created" value={shortDate(data.createdAt)} />
            <Field label="Last activity" value={timeAgo(data.lastActivity)} />
            <Field label="Tasks" value={data.tasks.length ? `${done}/${data.tasks.length} done` : 'None yet'} />
          </div>

          <PanelSection title="People">
            <div className="space-y-2">
              <Link href={`/admin?view=users&open=${data.user.id}`} className="flex items-center gap-3 rounded-2xl bg-cz-soft px-4 py-3 transition hover:ring-1 hover:ring-cz-accent/40">
                <User size={16} className="text-cz-muted" />
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-bold text-cz-ink">{data.user.name}</div>
                  <div className="truncate text-xs text-cz-muted">Customer · {data.user.phone || data.user.email}</div>
                </div>
              </Link>
              {accepted ? (
                <Link href={`/admin?view=providers&open=${accepted.provider.id}`} className="flex items-center gap-3 rounded-2xl bg-cz-soft px-4 py-3 transition hover:ring-1 hover:ring-cz-accent/40">
                  <HardHat size={16} className="text-cz-muted" />
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-bold text-cz-ink">{accepted.provider.businessName}{accepted.provider.isVerified ? ' ✓' : ''}</div>
                    <div className="truncate text-xs text-cz-muted">Hired partner · {inr(accepted.estimatedCost)} · {accepted.timeline}</div>
                  </div>
                </Link>
              ) : (
                <div className="rounded-2xl border-2 border-dashed border-cz-line px-4 py-3 text-sm font-semibold text-cz-muted">No partner hired yet</div>
              )}
            </div>
          </PanelSection>

          <PanelSection title={`Quotes (${data.quotes.length})`}>
            {data.quotes.length === 0 ? (
              <p className="text-sm text-cz-muted">No quotes yet.</p>
            ) : (
              <div className="overflow-hidden rounded-2xl border border-cz-line">
                {data.quotes.map(q => (
                  <div key={q.id} className="flex items-center gap-3 border-b border-cz-line px-4 py-2.5 last:border-b-0">
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-semibold text-cz-ink">{q.provider.businessName}</div>
                      <div className="text-xs text-cz-muted">{q.timeline} · {timeAgo(q.createdAt)}</div>
                    </div>
                    <span className="text-sm font-black text-cz-ink">{inr(q.estimatedCost)}</span>
                    {q.isAccepted && <StatusPill tone="green">Hired</StatusPill>}
                  </div>
                ))}
              </div>
            )}
          </PanelSection>

          {data.tasks.length > 0 && (
            <PanelSection title="Tasks">
              <div className="space-y-1.5">
                {data.tasks.map(t => {
                  const s = (t.status || '').toLowerCase();
                  return (
                    <div key={t.id} className="flex items-center gap-3 rounded-2xl bg-cz-soft px-3.5 py-2">
                      <span className={`h-2 w-2 shrink-0 rounded-full ${s === 'completed' ? 'bg-emerald-500' : s === 'in progress' ? 'bg-amber-500' : 'bg-cz-line'}`} />
                      <span className="min-w-0 flex-1 truncate text-sm text-cz-ink">{t.title}</span>
                      <span className="shrink-0 text-[11px] font-semibold text-cz-muted">{t.stage}</span>
                    </div>
                  );
                })}
              </div>
            </PanelSection>
          )}

          <PanelSection title="Timeline">
            {data.updates.length === 0 ? (
              <p className="text-sm text-cz-muted">No updates posted yet.</p>
            ) : (
              <ol className="relative ml-2 border-l-2 border-cz-line">
                {data.updates.map(u => (
                  <li key={u.id} className="mb-4 ml-4">
                    <span className="absolute -left-[7px] mt-1.5 h-3 w-3 rounded-full border-2 border-cz-surface bg-cz-accent" />
                    <div className="text-sm font-bold text-cz-ink">{u.title}</div>
                    <div className="text-xs text-cz-muted">{u.status} · {timeAgo(u.createdAt)}</div>
                    {u.notes && <p className="mt-1 text-sm text-cz-ink/80">{u.notes}</p>}
                  </li>
                ))}
              </ol>
            )}
          </PanelSection>
        </>
      )}
    </SidePanel>
  );
}
