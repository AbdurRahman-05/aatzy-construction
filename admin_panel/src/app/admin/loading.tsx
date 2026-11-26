import { cookies } from 'next/headers';
import { SIDEBAR_COOKIE, THEME_COOKIE } from './_ui/nav';

/** Skeleton shown while an admin view loads - same layout as AdminShell so nothing jumps. */
export default async function AdminLoading() {
  const store = await cookies();
  const theme = store.get(THEME_COOKIE)?.value === 'dark' ? 'dark' : 'light';
  const collapsed = store.get(SIDEBAR_COOKIE)?.value === '1';
  const pulse = 'animate-pulse rounded-2xl bg-cz-soft';

  return (
    <div className="admin-root min-h-screen" data-theme={theme}>
      <div className="flex min-h-screen">
        <aside className={`hidden shrink-0 border-r border-cz-line bg-cz-surface p-4 md:block ${collapsed ? 'w-[76px]' : 'w-64'}`}>
          <div className="mb-6 flex items-center gap-3">
            <div className="h-10 w-10 animate-pulse rounded-2xl bg-cz-accent/40" />
            {!collapsed && <div className={`h-4 w-28 ${pulse}`} />}
          </div>
          <div className="space-y-2">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className={`h-10 ${pulse}`} style={{ animationDelay: `${i * 60}ms` }} />
            ))}
          </div>
        </aside>
        <div className="flex-1">
          <div className="flex items-center gap-3 border-b border-cz-line px-4 py-4 sm:px-6 lg:px-8">
            <div className="flex-1 space-y-1.5">
              <div className={`h-5 w-44 ${pulse}`} />
              <div className={`h-3 w-64 ${pulse}`} />
            </div>
            <div className={`hidden h-10 w-80 lg:block ${pulse}`} />
            <div className={`h-10 w-10 ${pulse}`} />
          </div>
          <div className="mx-auto max-w-[1400px] px-4 py-8 sm:px-6 lg:px-8">
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
              <div className="h-72 animate-pulse rounded-3xl bg-cz-hero/80 sm:col-span-2 xl:row-span-2" />
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="h-[136px] animate-pulse rounded-3xl border border-cz-line bg-cz-surface" style={{ animationDelay: `${i * 80}ms` }} />
              ))}
            </div>
            <div className="mt-6 h-64 animate-pulse rounded-3xl border border-cz-line bg-cz-surface" />
          </div>
        </div>
      </div>
    </div>
  );
}
