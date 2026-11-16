'use client';

import { useState, useMemo } from 'react';
import RecentActionsFeed from './RecentActionsFeed';
import { RecentAction } from '@/lib/recentActions';

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
    ownerName?: string;
  } | null;
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

export interface MaterialOrder {
  id: string;
  title: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  totalRevenue: number;
  unitCost: number;
  totalCost: number;
  netProfit: number;
  status: string;
  deliveryStatus: string;
  gstPercent: number;
  createdAt: string;
  updatedAt: string;
  provider: {
    id: string;
    businessName: string;
    ownerName: string;
    email?: string;
    phone?: string;
    category?: string;
  } | null;
  buyer: {
    id: string;
    name: string;
    email?: string;
  } | null;
  product: {
    id: string;
    name: string;
    category?: string | null;
  } | null;
}

interface DashboardAnalyticsProps {
  projects: Project[];
  acceptedQuotes: Quote[];
  providers: Provider[];
  recentActions?: RecentAction[];
  materialOrders?: MaterialOrder[];
}

export default function DashboardAnalytics({
  projects,
  acceptedQuotes,
  providers,
  recentActions = [],
  materialOrders = []
}: DashboardAnalyticsProps) {
  const [activeTab, setActiveTab] = useState<'recent' | 'ongoing' | 'profits'>('recent');
  
  // Ongoing projects search query
  const [searchQuery, setSearchQuery] = useState('');
  
  // Profits state
  const [profitSubTab, setProfitSubTab] = useState<'services' | 'materials'>('services');
  const [selectedProviderId, setSelectedProviderId] = useState<string>('all');
  const [timeFilter, setTimeFilter] = useState<'day' | 'month' | 'year'>('month');

  // Material profits state
  const [selectedSupplierId, setSelectedSupplierId] = useState<string>('all');
  const [materialTimeFilter, setMaterialTimeFilter] = useState<'day' | 'month' | 'year'>('month');

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

  // 3. Provider Profit breakdown (Revenues per contractor provider)
  const providerProfits = useMemo(() => {
    const map: Record<string, { providerName: string; ownerName: string; totalEarnings: number; projectCount: number }> = {};
    
    providers.forEach(p => {
      map[p.id] = {
        providerName: p.businessName,
        ownerName: p.ownerName,
        totalEarnings: 0,
        projectCount: 0
      };
    });

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

    return Object.values(grouping).sort((a, b) => b.period.localeCompare(a.period));
  }, [selectedProviderId, acceptedQuotes, timeFilter]);

  // 5. Material Orders Summary Stats
  const materialStats = useMemo(() => {
    let totalSales = 0;
    let totalProfit = 0;
    let totalCost = 0;
    let completedOrders = 0;
    const activeSuppliersSet = new Set<string>();

    materialOrders.forEach(o => {
      totalSales += o.totalRevenue;
      totalProfit += o.netProfit;
      totalCost += o.totalCost;
      completedOrders += 1;
      if (o.provider?.id) {
        activeSuppliersSet.add(o.provider.id);
      }
    });

    return {
      totalSales,
      totalProfit,
      totalCost,
      completedOrders,
      activeSuppliersCount: activeSuppliersSet.size
    };
  }, [materialOrders]);

  // 6. Supplier Account Material Profits Breakdown (Grouped by Supplier Account)
  const supplierProfits = useMemo(() => {
    const map: Record<string, {
      supplierId: string;
      businessName: string;
      ownerName: string;
      email?: string;
      phone?: string;
      category?: string;
      orderCount: number;
      totalRevenue: number;
      totalCost: number;
      netProfit: number;
    }> = {};

    materialOrders.forEach(o => {
      const pId = o.provider?.id || 'unknown';
      if (!map[pId]) {
        map[pId] = {
          supplierId: pId,
          businessName: o.provider?.businessName || 'Independent Supplier',
          ownerName: o.provider?.ownerName || 'Verified Supplier',
          email: o.provider?.email,
          phone: o.provider?.phone,
          category: o.provider?.category || 'Materials & Supply',
          orderCount: 0,
          totalRevenue: 0,
          totalCost: 0,
          netProfit: 0,
        };
      }
      map[pId].orderCount += 1;
      map[pId].totalRevenue += o.totalRevenue;
      map[pId].totalCost += o.totalCost;
      map[pId].netProfit += o.netProfit;
    });

    return Object.values(map).sort((a, b) => b.totalRevenue - a.totalRevenue);
  }, [materialOrders]);

  // 7. Filtered Material Orders & Time Grouping by Supplier Account
  const filteredMaterialOrders = useMemo(() => {
    if (selectedSupplierId === 'all') return materialOrders;
    return materialOrders.filter(o => o.provider?.id === selectedSupplierId);
  }, [materialOrders, selectedSupplierId]);

  const groupedMaterialProfits = useMemo(() => {
    const grouping: Record<string, { period: string; revenue: number; profit: number; count: number }> = {};

    filteredMaterialOrders.forEach(o => {
      const date = new Date(o.updatedAt || o.createdAt);
      if (isNaN(date.getTime())) return;

      let key = '';
      if (materialTimeFilter === 'day') {
        key = date.toLocaleDateString('en-IN', { year: 'numeric', month: '2-digit', day: '2-digit' });
      } else if (materialTimeFilter === 'month') {
        key = date.toLocaleDateString('en-IN', { year: 'numeric', month: 'long' });
      } else {
        key = date.getFullYear().toString();
      }

      if (!grouping[key]) {
        grouping[key] = { period: key, revenue: 0, profit: 0, count: 0 };
      }
      grouping[key].revenue += o.totalRevenue;
      grouping[key].profit += o.netProfit;
      grouping[key].count += 1;
    });

    return Object.values(grouping).sort((a, b) => b.period.localeCompare(a.period));
  }, [filteredMaterialOrders, materialTimeFilter]);

  const activeSupplier = useMemo(() => {
    if (selectedSupplierId === 'all') return null;
    return supplierProfits.find(s => s.supplierId === selectedSupplierId);
  }, [selectedSupplierId, supplierProfits]);

  return (
    <div className="space-y-6">
      {/* Dynamic Main Tabs */}
      <div className="flex flex-wrap items-center bg-gray-100 p-1.5 rounded-2xl w-fit border border-gray-200 gap-1">
        <button
          onClick={() => setActiveTab('recent')}
          className={`flex items-center space-x-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all duration-200 ${
            activeTab === 'recent'
              ? 'bg-white text-blue-600 shadow-md shadow-gray-200/50'
              : 'text-gray-600 hover:text-gray-800'
          }`}
        >
          <span className="flex h-2 w-2 relative">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <span>Recent Actions</span>
          {recentActions.length > 0 && (
            <span className={`text-[10px] px-2 py-0.5 rounded-full font-black ${
              activeTab === 'recent' ? 'bg-blue-50 text-blue-600' : 'bg-gray-200 text-gray-700'
            }`}>
              {recentActions.length}
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveTab('ongoing')}
          className={`flex items-center space-x-2.5 px-5 py-2.5 rounded-xl font-bold text-sm transition-all duration-200 ${
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
          {materialOrders.length > 0 && (
            <span className="text-[10px] px-2 py-0.5 rounded-full font-black bg-emerald-100 text-emerald-700">
              New: Materials
            </span>
          )}
        </button>
      </div>

      {/* Tab: Recent Actions Feed */}
      {activeTab === 'recent' && (
        <RecentActionsFeed initialActions={recentActions} />
      )}

      {/* Card Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
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
          <p className="text-xs font-bold text-purple-700 uppercase tracking-widest">Project Billings</p>
          <p className="text-2xl font-black text-purple-950 mt-1">₹{stats.totalAcceptedRevenue.toLocaleString('en-IN')}</p>
        </div>
        <div className="bg-gradient-to-br from-emerald-50 to-teal-50 rounded-2xl border border-emerald-100 p-5">
          <p className="text-xs font-bold text-emerald-700 uppercase tracking-widest">Material Sales Volume</p>
          <p className="text-2xl font-black text-emerald-950 mt-1">₹{materialStats.totalSales.toLocaleString('en-IN')}</p>
          <p className="text-[11px] font-bold text-emerald-600 mt-0.5">₹{materialStats.totalProfit.toLocaleString('en-IN')} Est. Profit</p>
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

                    const totalCount = project.tasks.length;
                    const completedCount = project.tasks.filter(t => t.status === 'Completed').length;
                    const stage = (project.currentStage || 'Planning').toLowerCase();
                    let progress = 0.25;
                    if (stage === 'completed' || stage === 'finished') {
                      progress = 1.0;
                    } else if (stage.includes('pending approval')) {
                      progress = 0.95;
                    } else if (stage.includes('track') || stage.includes('execut') || stage === 'on hold') {
                      progress = totalCount > 0 ? 0.50 + 0.40 * (completedCount / totalCount) : 0.50;
                    } else if (stage.includes('design')) {
                      progress = totalCount > 0 ? 0.25 + 0.20 * (completedCount / totalCount) : (project.quotes.length > 0 ? 0.35 : 0.25);
                    } else if (stage === 'planning') {
                      progress = 0.15;
                    } else if (stage === 'cancelled') {
                      progress = 0.15;
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

      {/* Tab: Provider & Material Profits Analytics */}
      {activeTab === 'profits' && (
        <div className="space-y-6">
          {/* Sub-Tab Selector: Service Projects vs Material Orders */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
            <div className="flex items-center space-x-2">
              <button
                onClick={() => setProfitSubTab('services')}
                className={`flex items-center space-x-2 px-5 py-2.5 rounded-xl font-extrabold text-xs uppercase tracking-wider transition-all duration-200 ${
                  profitSubTab === 'services'
                    ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20'
                    : 'text-gray-600 hover:text-gray-900 bg-gray-50'
                }`}
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
                <span>Service Project Profits</span>
              </button>

              <button
                onClick={() => setProfitSubTab('materials')}
                className={`flex items-center space-x-2 px-5 py-2.5 rounded-xl font-extrabold text-xs uppercase tracking-wider transition-all duration-200 ${
                  profitSubTab === 'materials'
                    ? 'bg-emerald-600 text-white shadow-md shadow-emerald-500/20'
                    : 'text-gray-600 hover:text-gray-900 bg-gray-50'
                }`}
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                </svg>
                <span>Material Profits (By Account)</span>
                {materialOrders.length > 0 && (
                  <span className={`text-[10px] px-2 py-0.5 rounded-full font-black ${
                    profitSubTab === 'materials' ? 'bg-emerald-800 text-white' : 'bg-emerald-100 text-emerald-700'
                  }`}>
                    {materialOrders.length} Deals
                  </span>
                )}
              </button>
            </div>

            <div className="text-xs text-gray-500 font-semibold px-2">
              {profitSubTab === 'services'
                ? `Tracking ${providerProfits.length} contractor accounts`
                : `Tracking ${supplierProfits.length} supplier accounts • ₹${materialStats.totalProfit.toLocaleString('en-IN')} net material profit`}
            </div>
          </div>

          {/* VIEW A: Service Project Profits */}
          {profitSubTab === 'services' && (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Contractor Leaderboard */}
              <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden lg:col-span-1 flex flex-col">
                <div className="px-6 py-5 border-b border-gray-100 bg-gray-50/50">
                  <h3 className="text-base font-extrabold text-gray-900">Contractor Accounts</h3>
                  <p className="text-xs text-gray-500 mt-0.5">Sum of accepted project quotes per provider</p>
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
                        ? 'All Contractor Revenue Analytics' 
                        : `${providerProfits.find(p => p.id === selectedProviderId)?.providerName || 'Provider'} Detailed Profits`}
                    </h3>
                    <p className="text-xs text-gray-500 mt-0.5">Filter revenues by Day, Month, or Year</p>
                  </div>

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

                {selectedProviderId !== 'all' && (
                  <div className="p-4 bg-gray-50 border-t border-gray-100 flex justify-end">
                    <button
                      onClick={() => setSelectedProviderId('all')}
                      className="text-xs font-extrabold text-blue-600 hover:text-blue-800 hover:underline transition-colors"
                    >
                      Clear Contractor Selection & View All Network Stats
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* VIEW B: Material Profits Based on Supplier Account */}
          {profitSubTab === 'materials' && (
            <div className="space-y-6">
              {/* Material Profit Metric Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Total Material Sales</p>
                  <p className="text-2xl font-black text-gray-900 mt-1">₹{materialStats.totalSales.toLocaleString('en-IN')}</p>
                  <p className="text-xs text-gray-500 mt-0.5">Gross volume of completed orders</p>
                </div>
                <div className="bg-emerald-50 rounded-2xl border border-emerald-100 p-5">
                  <p className="text-xs font-bold text-emerald-700 uppercase tracking-widest">Material Net Profit</p>
                  <p className="text-2xl font-black text-emerald-950 mt-1">₹{materialStats.totalProfit.toLocaleString('en-IN')}</p>
                  <p className="text-xs text-emerald-700 mt-0.5">Calculated margin & platform profit</p>
                </div>
                <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Delivered Orders</p>
                  <p className="text-2xl font-black text-blue-600 mt-1">{materialStats.completedOrders}</p>
                  <p className="text-xs text-gray-500 mt-0.5">Completed supplier deals</p>
                </div>
                <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Supplier Accounts</p>
                  <p className="text-2xl font-black text-purple-600 mt-1">{supplierProfits.length}</p>
                  <p className="text-xs text-gray-500 mt-0.5">Accounts with closed transactions</p>
                </div>
              </div>

              {/* Supplier Accounts Breakdown & Detailed Ledger */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Left: Supplier Accounts List */}
                <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden lg:col-span-1 flex flex-col">
                  <div className="px-6 py-5 border-b border-gray-100 bg-gray-50/50 flex justify-between items-center">
                    <div>
                      <h3 className="text-base font-extrabold text-gray-900">Supplier Accounts</h3>
                      <p className="text-xs text-gray-500 mt-0.5">Material profits grouped by account</p>
                    </div>
                    <span className="text-xs font-black bg-emerald-100 text-emerald-800 px-2.5 py-1 rounded-full">
                      {supplierProfits.length}
                    </span>
                  </div>

                  <div className="divide-y divide-gray-50 overflow-y-auto flex-1 max-h-[550px]">
                    {supplierProfits.length === 0 ? (
                      <div className="p-8 text-center text-gray-400 font-medium">
                        No completed material sales recorded yet.
                      </div>
                    ) : (
                      supplierProfits.map(s => {
                        const isSelected = selectedSupplierId === s.supplierId;
                        return (
                          <div
                            key={s.supplierId}
                            onClick={() => setSelectedSupplierId(s.supplierId)}
                            className={`p-4 flex items-center justify-between cursor-pointer transition-all duration-200 ${
                              isSelected 
                                ? 'bg-emerald-50/80 border-l-4 border-emerald-600' 
                                : 'hover:bg-gray-50/50'
                            }`}
                          >
                            <div className="max-w-[65%]">
                              <h4 className="font-bold text-gray-900 text-sm truncate">{s.businessName}</h4>
                              <p className="text-xs text-gray-400 mt-0.5 truncate">{s.ownerName} • {s.orderCount} Deals</p>
                              {s.category && (
                                <span className="inline-block text-[10px] font-bold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full mt-1">
                                  {s.category}
                                </span>
                              )}
                            </div>
                            <div className="text-right">
                              <p className="font-extrabold text-emerald-700 text-sm">₹{s.netProfit.toLocaleString('en-IN')}</p>
                              <span className="text-[10px] text-gray-400 font-medium block">
                                Vol: ₹{s.totalRevenue.toLocaleString('en-IN')}
                              </span>
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>

                {/* Right: Detailed Account Profits & Order History */}
                <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden lg:col-span-2 flex flex-col">
                  {/* Account Header with Time Controls */}
                  <div className="px-8 py-5 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-gray-50/50">
                    <div>
                      <h3 className="text-base font-extrabold text-gray-900">
                        {activeSupplier 
                          ? `${activeSupplier.businessName} — Account Profits` 
                          : 'All Supplier Accounts — Consolidated Profits'}
                      </h3>
                      <p className="text-xs text-gray-500 mt-0.5">
                        {activeSupplier 
                          ? `Owner: ${activeSupplier.ownerName} • Total Deals: ${activeSupplier.orderCount} • Margin: ₹${activeSupplier.netProfit.toLocaleString('en-IN')}` 
                          : 'Material sales, gross volume, and margins across all registered supplier accounts'}
                      </p>
                    </div>

                    <div className="flex bg-gray-100 p-1 rounded-xl border border-gray-200">
                      {(['day', 'month', 'year'] as const).map(mode => (
                        <button
                          key={mode}
                          onClick={() => setMaterialTimeFilter(mode)}
                          className={`px-4 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider transition-all duration-200 ${
                            materialTimeFilter === mode
                              ? 'bg-white text-emerald-700 shadow-sm'
                              : 'text-gray-500 hover:text-gray-800'
                          }`}
                        >
                          {mode}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Summary Time-Series Table */}
                  <div className="overflow-x-auto border-b border-gray-100 max-h-[220px]">
                    <table className="w-full text-left border-collapse">
                      <thead>
                        <tr className="bg-gray-50/75 border-b border-gray-100 text-xs font-bold text-gray-400 uppercase tracking-widest">
                          <th className="p-4">Time Period ({materialTimeFilter})</th>
                          <th className="p-4 text-center">Deals Closed</th>
                          <th className="p-4 text-right">Gross Sales Volume</th>
                          <th className="p-4 text-right text-emerald-800">Net Profit / Margin</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-50 text-sm">
                        {groupedMaterialProfits.length === 0 ? (
                          <tr>
                            <td colSpan={4} className="p-6 text-center text-gray-400 font-medium">
                              No material transactions found for this period.
                            </td>
                          </tr>
                        ) : (
                          groupedMaterialProfits.map(item => (
                            <tr key={item.period} className="hover:bg-gray-50/50">
                              <td className="p-4 font-bold text-gray-900">{item.period}</td>
                              <td className="p-4 text-center font-semibold text-gray-600">{item.count}</td>
                              <td className="p-4 text-right font-extrabold text-gray-900">₹{item.revenue.toLocaleString('en-IN')}</td>
                              <td className="p-4 text-right font-black text-emerald-700">₹{item.profit.toLocaleString('en-IN')}</td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>

                  {/* Itemized Material Order Transactions */}
                  <div className="p-6">
                    <h4 className="font-bold text-sm text-gray-900 mb-3 flex items-center justify-between">
                      <span>Itemized Material Transactions ({filteredMaterialOrders.length})</span>
                      {selectedSupplierId !== 'all' && (
                        <button
                          onClick={() => setSelectedSupplierId('all')}
                          className="text-xs font-bold text-emerald-700 hover:underline"
                        >
                          View All Suppliers
                        </button>
                      )}
                    </h4>

                    <div className="overflow-x-auto max-h-[300px]">
                      <table className="w-full text-left border-collapse text-xs">
                        <thead>
                          <tr className="bg-gray-50 border-b border-gray-100 text-gray-400 font-bold uppercase tracking-wider">
                            <th className="p-3">Material / Product</th>
                            <th className="p-3">Supplier Account</th>
                            <th className="p-3">Buyer / Client</th>
                            <th className="p-3 text-center">Qty</th>
                            <th className="p-3 text-right">Order Total</th>
                            <th className="p-3 text-right text-emerald-800">Net Profit</th>
                            <th className="p-3 text-center">Status</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-50">
                          {filteredMaterialOrders.length === 0 ? (
                            <tr>
                              <td colSpan={7} className="p-8 text-center text-gray-400 font-medium">
                                No material order records found.
                              </td>
                            </tr>
                          ) : (
                            filteredMaterialOrders.map(order => (
                              <tr key={order.id} className="hover:bg-gray-50/50">
                                <td className="p-3">
                                  <p className="font-bold text-gray-900">{order.title}</p>
                                  {order.product?.name && (
                                    <p className="text-[10px] text-gray-400">{order.product.name}</p>
                                  )}
                                </td>
                                <td className="p-3 font-semibold text-gray-800">
                                  {order.provider?.businessName || 'Supplier'}
                                </td>
                                <td className="p-3 text-gray-600">
                                  {order.buyer?.name || 'Customer'}
                                </td>
                                <td className="p-3 text-center font-bold text-gray-700">
                                  {order.quantity} {order.unit}
                                </td>
                                <td className="p-3 text-right font-extrabold text-gray-900">
                                  ₹{order.totalRevenue.toLocaleString('en-IN')}
                                </td>
                                <td className="p-3 text-right font-black text-emerald-700">
                                  ₹{order.netProfit.toLocaleString('en-IN')}
                                </td>
                                <td className="p-3 text-center">
                                  <span className="bg-emerald-50 text-emerald-800 border border-emerald-200 px-2 py-0.5 rounded-full font-bold text-[10px]">
                                    {order.deliveryStatus || order.status}
                                  </span>
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {selectedSupplierId !== 'all' && (
                    <div className="p-4 bg-gray-50 border-t border-gray-100 flex justify-end">
                      <button
                        onClick={() => setSelectedSupplierId('all')}
                        className="text-xs font-extrabold text-emerald-700 hover:text-emerald-900 hover:underline transition-colors"
                      >
                        Clear Account Selection & View Network-Wide Stats
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
