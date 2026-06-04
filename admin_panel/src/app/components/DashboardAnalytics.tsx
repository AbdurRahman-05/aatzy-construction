'use client';

import { useState, useMemo } from 'react';

interface Task {
  id: string;
  status: string;
}

interface Quote {
  id: string;
  estimatedCost: number;
  isAccepted: boolean;
  createdAt: string;
  updatedAt: string;
  provider: {
    id: string;
    businessName: string;
  };
}

interface Project {
  id: string;
  title: string;
  type: string;
  location: string;
  budget: number;
  timeline: string;
  currentStage: string;
  createdAt: string;
  user: {
    name: string;
  };
  quotes: Quote[];
  tasks: Task[];
}

interface Provider {
  id: string;
  businessName: string;
  ownerName: string;
}

interface DashboardAnalyticsProps {
  projects: Project[];
  acceptedQuotes: Quote[];
  providers: Provider[];
}

export default function DashboardAnalytics({ projects, acceptedQuotes, providers }: DashboardAnalyticsProps) {
  const [activeTab, setActiveTab] = useState<'ongoing' | 'profits'>('ongoing');
  
  // Ongoing projects search query
  const [searchQuery, setSearchQuery] = useState('');
  
  // Profits state
  const [selectedProviderId, setSelectedProviderId] = useState<string>('all');
  const [timeFilter, setTimeFilter] = useState<'day' | 'month' | 'year'>('month');

  // 1. Filter ongoing projects
  const ongoingProjects = useMemo(() => {
    return projects.filter(p => {
      const stage = p.currentStage.toLowerCase();
      const isOngoing = stage !== 'completed' && stage !== 'finished' && stage !== 'cancelled';
      if (!isOngoing) return false;
      
      const query = searchQuery.toLowerCase();
      return (
        p.title.toLowerCase().includes(query) ||
        p.user.name.toLowerCase().includes(query) ||
        p.type.toLowerCase().includes(query)
      );
    });
  }, [projects, searchQuery]);

  // 2. Compute completed and cancelled projects counts
  const stats = useMemo(() => {
    let completed = 0;
    let cancelled = 0;
    let ongoing = 0;
    let totalBudget = 0;

    projects.forEach(p => {
      const stage = p.currentStage.toLowerCase();
      if (stage === 'completed' || stage === 'finished') {
        completed++;
      } else if (stage === 'cancelled') {
        cancelled++;
      } else {
        ongoing++;
      }
      totalBudget += p.budget;
    });

    const totalAcceptedRevenue = acceptedQuotes.reduce((acc, q) => acc + q.estimatedCost, 0);

    return { completed, cancelled, ongoing, totalBudget, totalAcceptedRevenue };
  }, [projects, acceptedQuotes]);

  // 3. Provider Profit breakdown (Revenues per provider)
  const providerProfits = useMemo(() => {
    const map: Record<string, { providerName: string; ownerName: string; totalEarnings: number; projectCount: number }> = {};
    
    // Initialize map
    providers.forEach(p => {
      map[p.id] = {
        providerName: p.businessName,
        ownerName: p.ownerName,
        totalEarnings: 0,
        projectCount: 0
      };
    });

    // Populate accepted quotes earnings
    acceptedQuotes.forEach(q => {
      const providerId = q.provider?.id;
      if (providerId && map[providerId]) {
        map[providerId].totalEarnings += q.estimatedCost;
        map[providerId].projectCount += 1;
      }
    });

    return Object.entries(map).map(([id, val]) => ({
      id,
      ...val
    })).sort((a, b) => b.totalEarnings - a.totalEarnings);
  }, [providers, acceptedQuotes]);

  // 4. Detailed Single Provider Profits filtered/grouped by Day, Month, Year
  const singleProviderProfits = useMemo(() => {
    const quotes = selectedProviderId === 'all' 
      ? acceptedQuotes 
      : acceptedQuotes.filter(q => q.provider?.id === selectedProviderId);

    const grouping: Record<string, { period: string; earnings: number; count: number }> = {};

    quotes.forEach(q => {
      // Parse the date (using updated or created date)
      const date = new Date(q.updatedAt || q.createdAt);
      if (isNaN(date.getTime())) return;

      let key = '';
      if (timeFilter === 'day') {
        key = date.toLocaleDateString('en-IN', { year: 'numeric', month: '2-digit', day: '2-digit' });
      } else if (timeFilter === 'month') {
        key = date.toLocaleDateString('en-IN', { year: 'numeric', month: 'long' });
      } else {
        key = date.getFullYear().toString();
      }

      if (!grouping[key]) {
        grouping[key] = { period: key, earnings: 0, count: 0 };
      }
      grouping[key].earnings += q.estimatedCost;
      grouping[key].count += 1;
    });

    // Sort periods chronologically
    return Object.values(grouping).sort((a, b) => {
      if (timeFilter === 'year') {
        return b.period.localeCompare(a.period);
      }
      // For month/day, parse back or just reverse sort the string key
      return b.period.localeCompare(a.period);
    });
  }, [selectedProviderId, acceptedQuotes, timeFilter]);

  return (
    <div className="space-y-6">
      {/* Dynamic Mini-Tabs */}
      <div className="flex bg-gray-100 p-1.5 rounded-2xl w-fit border border-gray-200">
        <button
          onClick={() => setActiveTab('ongoing')}
          className={`flex items-center space-x-2.5 px-6 py-2.5 rounded-xl font-bold text-sm transition-all duration-200 ${
            activeTab === 'ongoing'
              ? 'bg-white text-blue-600 shadow-md shadow-gray-200/50'
              : 'text-gray-600 hover:text-gray-800'
          }`}
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>Ongoing Projects</span>
        </button>
        <button
          onClick={() => setActiveTab('profits')}
          className={`flex items-center space-x-2.5 px-6 py-2.5 rounded-xl font-bold text-sm transition-all duration-200 ${
            activeTab === 'profits'
              ? 'bg-white text-blue-600 shadow-md shadow-gray-200/50'
              : 'text-gray-600 hover:text-gray-800'
          }`}
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>Earnings & Profits</span>
        </button>
      </div>

      {/* Card Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl border border-blue-100 p-5">
          <p className="text-xs font-bold text-blue-700 uppercase tracking-widest">Active Ongoing Jobs</p>
          <p className="text-2xl font-black text-blue-950 mt-1">{stats.ongoing}</p>
        </div>
        <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-2xl border border-green-100 p-5">
          <p className="text-xs font-bold text-green-700 uppercase tracking-widest">Completed Jobs</p>
          <p className="text-2xl font-black text-green-950 mt-1">{stats.completed}</p>
        </div>
        <div className="bg-gradient-to-br from-red-50 to-orange-50 rounded-2xl border border-red-100 p-5">
          <p className="text-xs font-bold text-red-700 uppercase tracking-widest">Cancelled Projects</p>
          <p className="text-2xl font-black text-red-950 mt-1">{stats.cancelled}</p>
        </div>
        <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-2xl border border-purple-100 p-5">
          <p className="text-xs font-bold text-purple-700 uppercase tracking-widest">Total Active Billing</p>
          <p className="text-2xl font-black text-purple-950 mt-1">₹{stats.totalAcceptedRevenue.toLocaleString('en-IN')}</p>
        </div>
      </div>

      {/* Tab: Ongoing Projects Details */}
      {activeTab === 'ongoing' && (
        <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
          <div className="px-8 py-6 border-b border-gray-100 flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gray-50/50">
            <div>
              <h2 className="text-lg font-bold text-gray-900">Ongoing Project Tracker</h2>
              <p className="text-xs text-gray-500 mt-0.5">Real-time status, providers, and task progress indicators</p>
            </div>
            
            {/* Search filter */}
            <div className="relative max-w-sm w-full">
              <input
                type="text"
                placeholder="Search by title, client, or category..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full text-sm pl-10 pr-4 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
              />
              <svg className="w-4 h-4 text-gray-400 absolute left-3.5 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50/75 border-b border-gray-100">
                  <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest">Project / Client</th>
                  <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest">Services Needed</th>
                  <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest">Budget / Cost</th>
                  <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest">Assigned Provider</th>
                  <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest">Timeline</th>
                  <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest text-center">Stage & Progress</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {ongoingProjects.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-12 text-center text-gray-400 font-medium">
                      No ongoing projects match the search filter.
                    </td>
                  </tr>
                ) : (
                  ongoingProjects.map(project => {
                    const acceptedQuote = project.quotes.find(q => q.isAccepted);
                    const providerName = acceptedQuote?.provider?.businessName || 'Not Assigned';
                    const isQuoteAccepted = !!acceptedQuote;
                    const costVal = isQuoteAccepted ? acceptedQuote.estimatedCost : project.budget;

                    // Progress calculations
                    const totalCount = project.tasks.length;
                    const completedCount = project.tasks.filter(t => t.status === 'Completed').length;
                    let progress = 0.0;
                    if (totalCount > 0) {
                      progress = completedCount / totalCount;
                    } else {
                      if (project.currentStage === 'Design & Planning') {
                        progress = project.quotes.length > 0 ? 0.25 : 0.05;
                      } else {
                        progress = 0.5;
                      }
                    }

                    return (
                      <tr key={project.id} className="hover:bg-gray-50/50 transition-colors">
                        <td className="p-5">
                          <p className="font-bold text-gray-900 leading-tight">{project.title}</p>
                          <p className="text-xs text-gray-400 mt-1 flex items-center">
                            <span className="w-1.5 h-1.5 rounded-full bg-blue-400 mr-1.5 inline-block"></span>
                            Client: {project.user.name}
                          </p>
                        </td>
                        <td className="p-5 text-sm text-gray-600 font-medium">
                          <span className="inline-block max-w-[200px] truncate" title={project.type}>
                            {project.type}
                          </span>
                        </td>
                        <td className="p-5">
                          <p className="font-extrabold text-gray-900">₹{costVal.toLocaleString('en-IN')}</p>
                          <span className={`text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full inline-block mt-0.5 ${
                            isQuoteAccepted 
                              ? 'bg-green-50 text-green-700 border border-green-200' 
                              : 'bg-amber-50 text-amber-700 border border-amber-200'
                          }`}>
                            {isQuoteAccepted ? 'Quote Price' : 'Est. Budget'}
                          </span>
                        </td>
                        <td className="p-5">
                          <p className="text-sm font-bold text-gray-800">{providerName}</p>
                          {isQuoteAccepted && (
                            <span className="text-[10px] text-gray-400 font-medium">Agreement Finalized</span>
                          )}
                        </td>
                        <td className="p-5 text-sm text-gray-500 font-medium">
                          {project.timeline}
                        </td>
                        <td className="p-5">
                          <div className="flex flex-col items-center">
                            <div className="w-full max-w-[120px] mb-1.5 flex justify-between items-center text-[10px] font-bold text-gray-500">
                              <span className="truncate max-w-[80px]">{project.currentStage}</span>
                              <span>{(progress * 100).toFixed(0)}%</span>
                            </div>
                            <div className="w-full max-w-[120px] h-2 bg-gray-100 rounded-full overflow-hidden">
                              <div 
                                className="h-full bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full"
                                style={{ width: `${progress * 100}%` }}
                              ></div>
                            </div>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab: Provider Profits & Revenue Analytics */}
      {activeTab === 'profits' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Provider Leaderboard / Earnings overview */}
          <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden lg:col-span-1 flex flex-col">
            <div className="px-6 py-5 border-b border-gray-100 bg-gray-50/50">
              <h3 className="text-base font-extrabold text-gray-900">Provider Earnings</h3>
              <p className="text-xs text-gray-500 mt-0.5">Sum of accepted quotes per provider</p>
            </div>
            
            <div className="divide-y divide-gray-50 overflow-y-auto flex-1 max-h-[500px]">
              {providerProfits.map(p => (
                <div
                  key={p.id}
                  onClick={() => setSelectedProviderId(p.id)}
                  className={`p-4 flex items-center justify-between cursor-pointer transition-all duration-200 ${
                    selectedProviderId === p.id 
                      ? 'bg-blue-50/70 border-l-4 border-blue-600' 
                      : 'hover:bg-gray-50/50'
                  }`}
                >
                  <div>
                    <h4 className="font-bold text-gray-900 text-sm">{p.providerName}</h4>
                    <p className="text-xs text-gray-400 mt-0.5">{p.ownerName} • {p.projectCount} Jobs</p>
                  </div>
                  <div className="text-right">
                    <p className="font-extrabold text-gray-950 text-sm">₹{p.totalEarnings.toLocaleString('en-IN')}</p>
                    <span className="text-[10px] text-gray-400 font-medium">Total Volume</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Time Series / Single User Earnings Filter */}
          <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden lg:col-span-2 flex flex-col">
            <div className="px-8 py-5 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-gray-50/50">
              <div>
                <h3 className="text-base font-extrabold text-gray-900">
                  {selectedProviderId === 'all' 
                    ? 'All Network Revenue Analytics' 
                    : `${providerProfits.find(p => p.id === selectedProviderId)?.providerName || 'Provider'} Detailed Profits`}
                </h3>
                <p className="text-xs text-gray-500 mt-0.5">Filter revenues by Day, Month, or Year</p>
              </div>

              {/* Time grouping selectors */}
              <div className="flex bg-gray-100 p-1 rounded-xl border border-gray-200">
                {(['day', 'month', 'year'] as const).map(mode => (
                  <button
                    key={mode}
                    onClick={() => setTimeFilter(mode)}
                    className={`px-4 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider transition-all duration-200 ${
                      timeFilter === mode
                        ? 'bg-white text-blue-600 shadow-sm'
                        : 'text-gray-500 hover:text-gray-800'
                    }`}
                  >
                    {mode}
                  </button>
                ))}
              </div>
            </div>

            {/* Profits Table */}
            <div className="overflow-y-auto flex-1 min-h-[400px]">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50/50 border-b border-gray-100">
                    <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest">Time Period ({timeFilter})</th>
                    <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest text-center">Projects Accepted</th>
                    <th className="p-5 text-xs font-bold text-gray-400 uppercase tracking-widest text-right">Revenue / Profits</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {singleProviderProfits.length === 0 ? (
                    <tr>
                      <td colSpan={3} className="p-12 text-center text-gray-400 font-medium">
                        No accepted quote earnings found for this filter selection.
                      </td>
                    </tr>
                  ) : (
                    singleProviderProfits.map(item => (
                      <tr key={item.period} className="hover:bg-gray-50/50 transition-all duration-150">
                        <td className="p-5 font-bold text-gray-900">
                          {item.period}
                        </td>
                        <td className="p-5 text-center font-semibold text-gray-600">
                          {item.count}
                        </td>
                        <td className="p-5 text-right">
                          <p className="font-extrabold text-blue-950">₹{item.earnings.toLocaleString('en-IN')}</p>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* Quick reset toggle */}
            {selectedProviderId !== 'all' && (
              <div className="p-4 bg-gray-50 border-t border-gray-100 flex justify-end">
                <button
                  onClick={() => setSelectedProviderId('all')}
                  className="text-xs font-extrabold text-blue-600 hover:text-blue-800 hover:underline transition-colors"
                >
                  Clear Provider Selection & View Network-Wide Stats
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
