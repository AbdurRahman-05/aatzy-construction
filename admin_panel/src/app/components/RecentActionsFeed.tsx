'use client';

import React, { useState, useMemo } from 'react';
import {
  Building2,
  CheckCircle2,
  Clock,
  DollarSign,
  FileText,
  Filter,
  Layers,
  MessageSquare,
  RefreshCw,
  Search,
  ShieldCheck,
  ShoppingBag,
  Sparkles,
  Star,
  UserCheck,
  Users,
  X,
  Eye,
  Camera,
  IndianRupee,
  Activity,
} from 'lucide-react';
import { RecentAction } from '@/lib/recentActions';

interface RecentActionsFeedProps {
  initialActions: RecentAction[];
}

export default function RecentActionsFeed({ initialActions }: RecentActionsFeedProps) {
  const [actions, setActions] = useState<RecentAction[]>(initialActions);
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<string>('Just now');
  const [selectedAction, setSelectedAction] = useState<RecentAction | null>(null);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      const res = await fetch('/api/admin/recent-actions?limit=50', { cache: 'no-store' });
      if (res.ok) {
        const data = await res.json();
        if (data.actions) {
          setActions(data.actions);
          const now = new Date();
          setLastUpdated(now.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
        }
      }
    } catch (err) {
      console.error('Failed to refresh actions:', err);
    } finally {
      setIsRefreshing(false);
    }
  };

  // Format relative timestamp
  const formatTimeAgo = (isoString: string) => {
    try {
      const date = new Date(isoString);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffSecs = Math.floor(diffMs / 1000);
      const diffMins = Math.floor(diffSecs / 60);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffSecs < 45) return 'Just now';
      if (diffMins < 60) return `${diffMins}m ago`;
      if (diffHours < 24) return `${diffHours}h ago`;
      if (diffDays === 1) return 'Yesterday';
      if (diffDays < 7) return `${diffDays}d ago`;
      return date.toLocaleDateString('en-IN', { month: 'short', day: 'numeric' });
    } catch {
      return 'Recently';
    }
  };

  // Filtered actions list
  const filteredActions = useMemo(() => {
    return actions.filter((act) => {
      // Category filter
      if (filterCategory !== 'all') {
        if (filterCategory === 'projects' && act.category !== 'project' && act.category !== 'task') return false;
        if (filterCategory === 'quotes' && act.category !== 'quote') return false;
        if (filterCategory === 'users' && act.category !== 'user' && act.category !== 'provider') return false;
        if (filterCategory === 'inquiries' && act.category !== 'inquiry') return false;
        if (filterCategory === 'subscriptions' && act.category !== 'subscription') return false;
        if (filterCategory === 'reviews' && act.category !== 'review') return false;
      }

      // Search filter
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesTitle = act.title.toLowerCase().includes(q);
        const matchesDesc = act.description.toLowerCase().includes(q);
        const matchesActor = act.actor.name.toLowerCase().includes(q);
        const matchesEntity = act.entityTitle?.toLowerCase().includes(q);
        const matchesLocation = act.location?.toLowerCase().includes(q);
        return matchesTitle || matchesDesc || matchesActor || matchesEntity || matchesLocation;
      }

      return true;
    });
  }, [actions, filterCategory, searchQuery]);

  // Action badge color styling
  const getBadgeClass = (color: string) => {
    switch (color) {
      case 'emerald':
        return 'bg-emerald-50 text-emerald-700 border-emerald-200';
      case 'blue':
        return 'bg-blue-50 text-blue-700 border-blue-200';
      case 'amber':
        return 'bg-amber-50 text-amber-700 border-amber-200';
      case 'purple':
        return 'bg-purple-50 text-purple-700 border-purple-200';
      case 'rose':
        return 'bg-rose-50 text-rose-700 border-rose-200';
      case 'sky':
        return 'bg-sky-50 text-sky-700 border-sky-200';
      case 'indigo':
        return 'bg-indigo-50 text-indigo-700 border-indigo-200';
      default:
        return 'bg-slate-50 text-slate-700 border-slate-200';
    }
  };

  // Action category icon
  const getCategoryIcon = (category: string, actionType: string) => {
    switch (category) {
      case 'project':
        return <Building2 className="w-5 h-5 text-blue-600" />;
      case 'task':
        return <CheckCircle2 className="w-5 h-5 text-emerald-600" />;
      case 'quote':
        return <IndianRupee className="w-5 h-5 text-indigo-600" />;
      case 'user':
        return <Users className="w-5 h-5 text-blue-600" />;
      case 'provider':
        return <ShieldCheck className="w-5 h-5 text-amber-600" />;
      case 'inquiry':
        return <ShoppingBag className="w-5 h-5 text-purple-600" />;
      case 'subscription':
        return <Sparkles className="w-5 h-5 text-emerald-600" />;
      case 'review':
        return <Star className="w-5 h-5 text-amber-500" fill="currentColor" />;
      case 'ad':
        return <Layers className="w-5 h-5 text-sky-600" />;
      default:
        return <Activity className="w-5 h-5 text-slate-600" />;
    }
  };

  return (
    <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
      {/* Top Banner & Controls */}
      <div className="p-6 sm:p-8 border-b border-gray-100 bg-gradient-to-r from-slate-50 via-blue-50/30 to-indigo-50/20">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2.5">
              <span className="flex h-2.5 w-2.5 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
              </span>
              <span className="text-[11px] font-black uppercase tracking-widest text-emerald-700 bg-emerald-100/80 px-2.5 py-0.5 rounded-full">
                Live Activity Stream
              </span>
            </div>
            <h2 className="text-xl sm:text-2xl font-black text-gray-900 tracking-tight mt-1.5 flex items-center gap-2">
              Recent Application Actions
            </h2>
            <p className="text-xs sm:text-sm text-gray-500 mt-1">
              End-to-end timeline across homeowners, contractors, material suppliers, quotes & subscriptions.
            </p>
          </div>

          {/* Action buttons */}
          <div className="flex items-center gap-2.5 self-start md:self-auto">
            <span className="text-xs text-gray-400 hidden sm:inline">
              Updated: <strong className="text-gray-600">{lastUpdated}</strong>
            </span>
            <button
              onClick={handleRefresh}
              disabled={isRefreshing}
              className="flex items-center gap-2 px-3.5 py-2 bg-white border border-gray-200 hover:border-blue-400 text-gray-700 hover:text-blue-600 rounded-xl text-xs font-bold shadow-sm transition-all active:scale-95 disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-blue-600' : ''}`} />
              <span>{isRefreshing ? 'Refreshing...' : 'Refresh Feed'}</span>
            </button>
          </div>
        </div>

        {/* Filter Pills & Search */}
        <div className="mt-6 flex flex-col lg:flex-row lg:items-center justify-between gap-3">
          {/* Filter Pills */}
          <div className="flex flex-wrap items-center gap-1.5">
            {[
              { id: 'all', label: 'All Actions', count: actions.length },
              { id: 'projects', label: 'Projects & Tasks' },
              { id: 'quotes', label: 'Quotes & Bids' },
              { id: 'inquiries', label: 'B2B Materials' },
              { id: 'users', label: 'Users & Providers' },
              { id: 'subscriptions', label: 'Subscriptions' },
              { id: 'reviews', label: 'Reviews' },
            ].map((tab) => {
              const active = filterCategory === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setFilterCategory(tab.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                    active
                      ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20'
                      : 'bg-white/80 text-gray-600 hover:bg-white hover:text-gray-900 border border-gray-200/80'
                  }`}
                >
                  {tab.label}
                  {tab.count !== undefined && (
                    <span className={`ml-1.5 text-[10px] px-1.5 py-0.2 rounded-full ${active ? 'bg-white/25 text-white' : 'bg-gray-100 text-gray-600'}`}>
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          {/* Search box */}
          <div className="relative min-w-[240px]">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search actions by project, actor..."
              className="w-full pl-9 pr-8 py-2 bg-white border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 rounded-xl text-xs text-gray-800 placeholder-gray-400 outline-none transition-all"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Actions Timeline List */}
      <div className="divide-y divide-gray-100 max-h-[700px] overflow-y-auto">
        {filteredActions.length === 0 ? (
          <div className="py-16 text-center text-gray-400">
            <Activity className="w-12 h-12 mx-auto text-gray-200 mb-3" />
            <p className="text-base font-bold text-gray-600">No recent actions found</p>
            <p className="text-xs text-gray-400 mt-1 max-w-sm mx-auto">
              No activity matches the current category or search criteria. Try selecting another tab or clear your search query.
            </p>
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="mt-3 text-xs font-bold text-blue-600 hover:underline"
              >
                Clear Search Query
              </button>
            )}
          </div>
        ) : (
          filteredActions.map((action) => (
            <div
              key={action.id}
              onClick={() => setSelectedAction(action)}
              className="p-5 sm:p-6 hover:bg-slate-50/70 transition-colors cursor-pointer group flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4"
            >
              {/* Left Column: Icon + Actor + Description */}
              <div className="flex items-start space-x-4 min-w-0">
                {/* Icon wrapper */}
                <div className="w-11 h-11 rounded-2xl bg-white border border-gray-100 shadow-sm flex items-center justify-center flex-shrink-0 group-hover:scale-105 group-hover:border-blue-200 transition-all">
                  {getCategoryIcon(action.category, action.actionType)}
                </div>

                <div className="min-w-0 space-y-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="text-sm font-extrabold text-gray-900 group-hover:text-blue-600 transition-colors">
                      {action.title}
                    </span>
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${getBadgeClass(action.badge.color)}`}>
                      {action.badge.text}
                    </span>
                    {action.hasPhoto && (
                      <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                        <Camera className="w-3 h-3" /> Photo Proof
                      </span>
                    )}
                  </div>

                  <p className="text-xs text-gray-600 line-clamp-2">
                    {action.description}
                  </p>

                  <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-gray-400">
                    <span className="font-semibold text-gray-700 flex items-center gap-1">
                      <span className={`w-2 h-2 rounded-full ${action.actor.avatarColor || 'bg-blue-600'}`} />
                      {action.actor.name}
                    </span>
                    <span>·</span>
                    <span>{action.actor.role}</span>
                    {action.location && (
                      <>
                        <span>·</span>
                        <span>📍 {action.location}</span>
                      </>
                    )}
                  </div>
                </div>
              </div>

              {/* Right Column: Amount & Timestamp */}
              <div className="flex sm:flex-col items-center sm:items-end justify-between w-full sm:w-auto flex-shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-gray-100">
                {action.amount !== undefined ? (
                  <span className="text-sm font-black text-gray-900 tracking-tight">
                    ₹{action.amount.toLocaleString('en-IN')}
                  </span>
                ) : (
                  <span className="text-xs text-gray-400 italic">No monetary value</span>
                )}

                <div className="flex items-center gap-1 text-[11px] text-gray-400 font-medium mt-0.5">
                  <Clock className="w-3 h-3" />
                  <span>{formatTimeAgo(action.timestamp)}</span>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Footer Info */}
      <div className="p-4 bg-gray-50 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
        <span>Showing {filteredActions.length} of {actions.length} recorded actions</span>
        <span className="font-medium text-gray-600">Click any action row to inspect full payload</span>
      </div>

      {/* Action Detail Inspection Modal */}
      {selectedAction && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-view-enter">
          <div className="bg-white rounded-3xl max-w-lg w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-gray-100 p-6 sm:p-8 relative">
            <button
              onClick={() => setSelectedAction(null)}
              className="absolute right-5 top-5 p-2 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-500 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="flex items-center space-x-3 mb-4">
              <div className="w-12 h-12 rounded-2xl bg-blue-50 border border-blue-100 flex items-center justify-center">
                {getCategoryIcon(selectedAction.category, selectedAction.actionType)}
              </div>
              <div>
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${getBadgeClass(selectedAction.badge.color)}`}>
                  {selectedAction.badge.text}
                </span>
                <h3 className="text-lg font-black text-gray-900 mt-1">
                  {selectedAction.title}
                </h3>
              </div>
            </div>

            <p className="text-sm text-gray-700 bg-gray-50 rounded-2xl p-4 border border-gray-100 mb-6 leading-relaxed">
              {selectedAction.description}
            </p>

            {/* Photo Proof preview if present */}
            {selectedAction.hasPhoto && selectedAction.photoUrl && (
              <div className="mb-6">
                <span className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">
                  Uploaded Photo Proof
                </span>
                <div className="rounded-2xl overflow-hidden border border-gray-200 bg-gray-900 max-h-60 flex items-center justify-center">
                  <img
                    src={selectedAction.photoUrl}
                    alt="Task Milestone Proof"
                    className="w-full h-auto max-h-60 object-contain"
                  />
                </div>
              </div>
            )}

            {/* Payload details */}
            <div className="space-y-3 mb-6 text-xs">
              <div className="flex justify-between py-2 border-b border-gray-100">
                <span className="text-gray-400 font-medium">Actor</span>
                <span className="font-bold text-gray-800">{selectedAction.actor.name} ({selectedAction.actor.role})</span>
              </div>

              {selectedAction.entityTitle && (
                <div className="flex justify-between py-2 border-b border-gray-100">
                  <span className="text-gray-400 font-medium">Related Entity</span>
                  <span className="font-bold text-gray-800">{selectedAction.entityTitle}</span>
                </div>
              )}

              {selectedAction.location && (
                <div className="flex justify-between py-2 border-b border-gray-100">
                  <span className="text-gray-400 font-medium">Location</span>
                  <span className="font-bold text-gray-800">{selectedAction.location}</span>
                </div>
              )}

              {selectedAction.amount !== undefined && (
                <div className="flex justify-between py-2 border-b border-gray-100">
                  <span className="text-gray-400 font-medium">Amount</span>
                  <span className="font-extrabold text-blue-600 text-sm">₹{selectedAction.amount.toLocaleString('en-IN')}</span>
                </div>
              )}

              <div className="flex justify-between py-2 border-b border-gray-100">
                <span className="text-gray-400 font-medium">Exact Date & Time</span>
                <span className="font-bold text-gray-800">
                  {new Date(selectedAction.timestamp).toLocaleString('en-IN', {
                    dateStyle: 'medium',
                    timeStyle: 'medium',
                  })}
                </span>
              </div>

              {selectedAction.metadata && Object.keys(selectedAction.metadata).length > 0 && (
                <div className="pt-2">
                  <span className="block text-gray-400 font-medium mb-1.5">Extended Attributes</span>
                  <div className="bg-slate-50 p-3 rounded-xl space-y-1">
                    {Object.entries(selectedAction.metadata).map(([k, v]) => (
                      v !== undefined && v !== null && (
                        <div key={k} className="flex justify-between text-[11px]">
                          <span className="text-gray-500 capitalize">{k.replace(/([A-Z])/g, ' $1')}:</span>
                          <span className="font-semibold text-gray-800">{String(v)}</span>
                        </div>
                      )
                    ))}
                  </div>
                </div>
              )}
            </div>

            <button
              onClick={() => setSelectedAction(null)}
              className="w-full py-3 bg-gray-900 hover:bg-black text-white font-bold rounded-xl text-xs transition-colors"
            >
              Close Details
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
