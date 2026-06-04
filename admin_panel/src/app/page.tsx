import Link from 'next/link';
import prisma from '@/lib/prisma';
import ProviderReviewModal from './components/ProviderReviewModal';
import StatusToggle from './components/StatusToggle';
import DeleteButton from './components/DeleteButton';
import ViewDetailsModal from './components/ViewDetailsModal';
import DashboardAnalytics from './components/DashboardAnalytics';

export const dynamic = 'force-dynamic';

export default async function AdminDashboard({
  searchParams,
}: {
  searchParams: Promise<{ view?: string }>;
}) {
  const { view = 'dashboard' } = await searchParams;

  const unapprovedProviders = await prisma.provider.findMany({
    where: { isVerified: false, isRejected: false },
    include: { portfolioImages: true },
    orderBy: { createdAt: 'desc' }
  });

  const allUsers = await prisma.user.findMany({
    where: { role: 'CONSUMER' },
    orderBy: { createdAt: 'desc' }
  });

  const allProviders = await prisma.provider.findMany({
    include: { portfolioImages: true },
    orderBy: { createdAt: 'desc' }
  });

  const totalUsers = await prisma.user.count();
  const totalProviders = await prisma.provider.count();
  const activeProjects = await prisma.project.count();
  const totalQuotes = await prisma.quote.count();

  // Fetch projects data for the analytics dashboard
  const allProjectsRaw = await prisma.project.findMany({
    include: {
      user: { select: { name: true } },
      quotes: {
        include: {
          provider: { select: { id: true, businessName: true } }
        }
      },
      tasks: true
    },
    orderBy: { createdAt: 'desc' }
  });

  const projectsJson = allProjectsRaw.map(p => ({
    id: p.id,
    title: p.title,
    type: p.type,
    location: p.location,
    budget: p.budget,
    timeline: p.timeline,
    currentStage: p.currentStage,
    createdAt: p.createdAt.toISOString(),
    user: { name: p.user.name },
    quotes: p.quotes.map(q => ({
      id: q.id,
      estimatedCost: q.estimatedCost,
      isAccepted: q.isAccepted,
      createdAt: q.createdAt.toISOString(),
      updatedAt: q.updatedAt.toISOString(),
      provider: q.provider ? {
        id: q.provider.id,
        businessName: q.provider.businessName
      } : null
    })),
    tasks: p.tasks.map(t => ({
      id: t.id,
      status: t.status
    }))
  }));

  // Fetch accepted quotes data for profit analytics breakdown
  const acceptedQuotesRaw = await prisma.quote.findMany({
    where: { isAccepted: true },
    include: {
      provider: { select: { id: true, businessName: true, ownerName: true } },
      project: true
    },
    orderBy: { updatedAt: 'desc' }
  });

  const acceptedQuotesJson = acceptedQuotesRaw.map(q => ({
    id: q.id,
    estimatedCost: q.estimatedCost,
    isAccepted: q.isAccepted,
    createdAt: q.createdAt.toISOString(),
    updatedAt: q.updatedAt.toISOString(),
    provider: {
      id: q.provider.id,
      businessName: q.provider.businessName,
      ownerName: q.provider.ownerName
    }
  }));

  const providersJson = allProviders.map(p => ({
    id: p.id,
    businessName: p.businessName,
    ownerName: p.ownerName
  }));

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col font-sans">
      <header className="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between shadow-sm sticky top-0 z-40">
        <div className="flex items-center space-x-4">
          <div className="bg-blue-600 p-2 rounded-lg">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <h1 className="text-xl font-bold text-gray-900 tracking-tight">BuildConnect Admin</h1>
        </div>
        <div className="flex items-center space-x-3">
          <span className="text-sm font-medium text-gray-500">Administrator</span>
          <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-xs">
            AD
          </div>
        </div>
      </header>
      
      <div className="flex flex-1">
        <aside className="w-64 bg-white border-r border-gray-200 py-8 flex flex-col shadow-sm sticky top-[73px] h-[calc(100vh-73px)]">
          <nav className="flex-1 px-4 space-y-1">
            <Link 
              href="/?view=dashboard" 
              className={`flex items-center space-x-3 px-4 py-3 rounded-xl font-medium transition-all ${view === 'dashboard' ? 'bg-blue-600 text-white shadow-lg shadow-blue-200' : 'text-gray-600 hover:bg-gray-100'}`}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 002 2h2a2 2 0 002-2z" />
              </svg>
              <span>Project Dashboard</span>
            </Link>
            <Link 
              href="/?view=pending" 
              className={`flex items-center space-x-3 px-4 py-3 rounded-xl font-medium transition-all ${view === 'pending' ? 'bg-blue-600 text-white shadow-lg shadow-blue-200' : 'text-gray-600 hover:bg-gray-100'}`}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>Pending Approvals</span>
            </Link>
            <Link 
              href="/?view=users" 
              className={`flex items-center space-x-3 px-4 py-3 rounded-xl font-medium transition-all ${view === 'users' ? 'bg-blue-600 text-white shadow-lg shadow-blue-200' : 'text-gray-600 hover:bg-gray-100'}`}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              <span>User Management</span>
            </Link>
            <Link 
              href="/?view=providers" 
              className={`flex items-center space-x-3 px-4 py-3 rounded-xl font-medium transition-all ${view === 'providers' ? 'bg-blue-600 text-white shadow-lg shadow-blue-200' : 'text-gray-600 hover:bg-gray-100'}`}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              <span>Provider Directory</span>
            </Link>
          </nav>
        </aside>

        <main className="flex-1 p-8 overflow-y-auto bg-gray-50">
          <div className="max-w-6xl mx-auto">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center text-center">
                <div className="bg-blue-50 p-3 rounded-xl mb-4">
                  <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <h3 className="text-gray-500 text-xs font-bold uppercase tracking-wider">Total Users</h3>
                <p className="text-3xl font-black text-gray-900 mt-1">{totalUsers}</p>
              </div>
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center text-center">
                <div className="bg-indigo-50 p-3 rounded-xl mb-4">
                  <svg className="w-6 h-6 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 className="text-gray-500 text-xs font-bold uppercase tracking-wider">Total Providers</h3>
                <p className="text-3xl font-black text-gray-900 mt-1">{totalProviders}</p>
              </div>
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center text-center">
                <div className="bg-emerald-50 p-3 rounded-xl mb-4">
                  <svg className="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                  </svg>
                </div>
                <h3 className="text-gray-500 text-xs font-bold uppercase tracking-wider">Active Projects</h3>
                <p className="text-3xl font-black text-gray-900 mt-1">{activeProjects}</p>
              </div>
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center text-center">
                <div className="bg-amber-50 p-3 rounded-xl mb-4">
                  <svg className="w-6 h-6 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 className="text-gray-500 text-xs font-bold uppercase tracking-wider">Total Quotes</h3>
                <p className="text-3xl font-black text-gray-900 mt-1">{totalQuotes}</p>
              </div>
            </div>

            {view === 'dashboard' && (
              <DashboardAnalytics 
                projects={projectsJson} 
                acceptedQuotes={acceptedQuotesJson} 
                providers={providersJson} 
              />
            )}

            {view === 'pending' && (
              <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
                <div className="px-8 py-6 border-b border-gray-100 flex justify-between items-center bg-blue-50/50">
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-blue-600 rounded-full animate-pulse"></div>
                    <h2 className="text-lg font-bold text-blue-900">Provider Approvals Pending</h2>
                  </div>
                  <span className="bg-blue-100 text-blue-800 text-xs font-black px-4 py-1.5 rounded-full uppercase tracking-widest">{unapprovedProviders.length} Applications</span>
                </div>
                
                {unapprovedProviders.length === 0 ? (
                  <div className="p-12 text-center text-gray-400">
                    <svg className="w-16 h-16 mx-auto text-gray-200 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <p className="text-lg font-medium">All caught up! No pending reviews.</p>
                  </div>
                ) : (
                  <ul className="divide-y divide-gray-50">
                    {unapprovedProviders.map(provider => (
                      <li key={provider.id} className="p-8 flex items-center justify-between hover:bg-gray-50 transition-all group">
                        <div className="flex items-center space-x-6">
                          <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center text-white font-bold text-xl shadow-lg shadow-blue-100">
                            {provider.businessName[0].toUpperCase()}
                          </div>
                          <div>
                            <p className="text-base font-bold text-gray-900 group-hover:text-blue-600 transition-colors">{provider.businessName}</p>
                            <p className="text-sm text-gray-500 mt-0.5">{provider.ownerName} • {provider.category}</p>
                          </div>
                        </div>
                        <ProviderReviewModal provider={provider} />
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            )}

            {view === 'users' && (
              <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
                <div className="px-8 py-6 border-b border-gray-100 bg-gray-50/50">
                  <h2 className="text-lg font-bold text-gray-900">User Management</h2>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-gray-50">
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest">User Name</th>
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest">Email</th>
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest text-center">Status</th>
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {allUsers.map(user => (
                        <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                          <td className="p-6 font-bold text-gray-900">{user.name}</td>
                          <td className="p-6 text-gray-500">{user.email}</td>
                          <td className="p-6 text-center">
                            <StatusToggle id={user.id} initialStatus={user.isApproved} type="user" />
                          </td>
                          <td className="p-6 text-right">
                            <div className="flex items-center justify-end space-x-2">
                              <ViewDetailsModal
                                type="user"
                                data={{
                                  id: user.id,
                                  name: user.name,
                                  email: user.email,
                                  role: user.role,
                                  isApproved: user.isApproved,
                                  createdAt: user.createdAt.toISOString(),
                                }}
                              />
                              <DeleteButton id={user.id} type="user" name={user.name} />
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {view === 'providers' && (
              <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
                <div className="px-8 py-6 border-b border-gray-100 bg-gray-50/50">
                  <h2 className="text-lg font-bold text-gray-900">Provider Directory</h2>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-gray-50">
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest">Business</th>
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest">Category</th>
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest text-center">Status</th>
                        <th className="p-6 text-xs font-bold text-gray-400 uppercase tracking-widest text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {allProviders.map(provider => (
                        <tr key={provider.id} className="hover:bg-gray-50 transition-colors">
                          <td className="p-6">
                            <p className="font-bold text-gray-900">{provider.businessName}</p>
                            <p className="text-xs text-gray-400">{provider.ownerName}</p>
                          </td>
                          <td className="p-6 text-gray-500">{provider.category}</td>
                          <td className="p-6 text-center">
                            <StatusToggle id={provider.id} initialStatus={provider.isVerified} type="provider" />
                          </td>
                          <td className="p-6 text-right">
                            <div className="flex items-center justify-end space-x-2">
                              <ViewDetailsModal
                                type="provider"
                                data={{
                                  id: provider.id,
                                  businessName: provider.businessName,
                                  ownerName: provider.ownerName,
                                  email: provider.email,
                                  phone: provider.phone,
                                  category: provider.category,
                                  experience: provider.experience,
                                  isVerified: provider.isVerified,
                                  isRejected: provider.isRejected,
                                  bio: provider.bio,
                                  address: provider.address,
                                  aadharCard: provider.aadharCard,
                                  panCard: provider.panCard,
                                  profileCompletion: provider.profileCompletion,
                                  createdAt: provider.createdAt.toISOString(),
                                }}
                              />
                              <DeleteButton id={provider.id} type="provider" name={provider.businessName} />
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
