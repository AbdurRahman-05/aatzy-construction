import prisma from '@/lib/prisma';
import { cookies } from 'next/headers';
import { ADMIN_COOKIE_NAME, isValidAdminToken } from '@/lib/auth';
import { getRecentActions } from '@/lib/recentActions';
import { categoryNameFor, orderProfit } from '@/lib/materials';
import LoginForm from './LoginForm';
import AdminShell from './_ui/AdminShell';
import OverviewTiles, { type OverviewData } from './_ui/OverviewTiles';
import ApprovalsInbox, { type InboxItem } from './_ui/ApprovalsInbox';
import ProjectsBoard, { type BoardProject } from './_ui/ProjectsBoard';
import { CustomersView, PartnersView, type CustomerRow, type PartnerRow } from './_ui/PeopleViews';
import { SIDEBAR_COOKIE, THEME_COOKIE, type SearchIndex } from './_ui/nav';
import DashboardAnalytics from '../components/DashboardAnalytics';
import RecentActionsFeed from '../components/RecentActionsFeed';
import AdsManager from '../components/AdsManager';
import ProductsModeration, { type ModerationProduct } from '../components/ProductsModeration';
import ViewTransitionContainer from '../components/ViewTransitionContainer';

export const dynamic = 'force-dynamic';

const VIEWS = ['dashboard', 'pending', 'projects', 'users', 'providers', 'products', 'ads', 'recent-actions'];
const CLOSED_STAGES = ['Completed', 'Finished', 'Cancelled', 'completed', 'finished', 'cancelled'];
const QUIET_DAYS = 14;
const DAY = 86_400_000;

/** Server components render once per request, so one timestamp per request is fine. */
const requestTime = () => Date.now();

function latest(...dates: (Date | null | undefined)[]): Date {
  return dates.filter((d): d is Date => !!d).reduce((a, b) => (b > a ? b : a), new Date(0));
}

export default async function AdminDashboard({
  searchParams,
}: {
  searchParams: Promise<{ view?: string; open?: string }>;
}) {
  const params = await searchParams;
  const now = requestTime();
  const view = VIEWS.includes(params.view || '') ? params.view! : 'dashboard';
  const openId = params.open || undefined;

  const cookieStore = await cookies();
  if (!isValidAdminToken(cookieStore.get(ADMIN_COOKIE_NAME)?.value)) {
    return <LoginForm />;
  }
  const theme = cookieStore.get(THEME_COOKIE)?.value === 'dark' ? 'dark' : 'light';
  const collapsed = cookieStore.get(SIDEBAR_COOKIE)?.value === '1';

  // ---- Always: badge counts + search index (small selects only)
  const [pendingPartners, pendingProducts, idxUsers, idxProviders, idxProjects] = await Promise.all([
    prisma.provider.count({ where: { isVerified: false, isRejected: false } }),
    prisma.product.count({ where: { status: 'Pending', deletedAt: null } }),
    prisma.user.findMany({ where: { role: 'CONSUMER' }, select: { id: true, name: true, email: true, phone: true }, orderBy: { createdAt: 'desc' } }),
    prisma.provider.findMany({
      select: { id: true, businessName: true, ownerName: true, phone: true, email: true, category: true, isVerified: true },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.project.findMany({
      select: { id: true, title: true, location: true, currentStage: true, user: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    }),
  ]);

  const searchIndex: SearchIndex = {
    users: idxUsers.map(u => ({ id: u.id, name: u.name, email: u.email, phone: u.phone })),
    providers: idxProviders.map(p => ({
      id: p.id, name: p.businessName, owner: p.ownerName, phone: p.phone, email: p.email, category: p.category, verified: p.isVerified,
    })),
    projects: idxProjects.map(p => ({ id: p.id, title: p.title, location: p.location, client: p.user.name, stage: p.currentStage })),
  };

  let content: React.ReactNode = null;

  // ---------------------------------------------------------------- Overview
  if (view === 'dashboard') {
    const since = new Date(now - 180 * DAY);
    const [
      evCustomers, evPartners, evProjects, evOrders, evDeals,
      oldestPartner, oldestProduct, activeProjectsRaw, openOrders, totalCustomers, verifiedPartners, liveProducts,
      allProjectsRaw, acceptedQuotesRaw, completedInquiriesRaw, recentActions,
    ] = await Promise.all([
      prisma.user.findMany({ where: { role: 'CONSUMER', createdAt: { gte: since } }, select: { createdAt: true } }),
      prisma.provider.findMany({ where: { createdAt: { gte: since } }, select: { createdAt: true } }),
      prisma.project.findMany({ where: { createdAt: { gte: since } }, select: { createdAt: true } }),
      prisma.inquiry.findMany({ where: { createdAt: { gte: since } }, select: { createdAt: true } }),
      prisma.quote.findMany({ where: { isAccepted: true, updatedAt: { gte: since } }, select: { updatedAt: true, estimatedCost: true } }),
      prisma.provider.findFirst({ where: { isVerified: false, isRejected: false }, orderBy: { createdAt: 'asc' }, select: { createdAt: true } }),
      prisma.product.findFirst({ where: { status: 'Pending', deletedAt: null }, orderBy: { updatedAt: 'asc' }, select: { updatedAt: true } }),
      prisma.project.findMany({
        where: { currentStage: { notIn: CLOSED_STAGES } },
        select: {
          updatedAt: true,
          updates: { select: { createdAt: true }, orderBy: { createdAt: 'desc' }, take: 1 },
          tasks: { select: { updatedAt: true }, orderBy: { updatedAt: 'desc' }, take: 1 },
        },
      }),
      prisma.inquiry.count({ where: { status: { notIn: ['Completed', 'Rejected', 'Lead Rejected'] } } }),
      prisma.user.count({ where: { role: 'CONSUMER' } }),
      prisma.provider.count({ where: { isVerified: true } }),
      prisma.product.count({ where: { status: 'Approved', deletedAt: null } }),
      // Data for the existing deep-dive analytics below the tiles
      prisma.project.findMany({
        include: {
          user: { select: { name: true } },
          quotes: { include: { provider: { select: { id: true, businessName: true } } } },
          tasks: { select: { id: true, status: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.quote.findMany({
        where: { isAccepted: true },
        include: { provider: { select: { id: true, businessName: true, ownerName: true } } },
        orderBy: { updatedAt: 'desc' },
      }),
      prisma.inquiry.findMany({
        where: { OR: [{ status: 'Completed' }, { status: 'Closed' }] },
        include: {
          provider: { select: { id: true, businessName: true, ownerName: true, email: true, phone: true, category: true } },
          buyer: { select: { id: true, name: true, email: true } },
          product: { select: { id: true, name: true, pricePerUnit: true, costPrice: true, category: true, unitType: true } },
        },
        orderBy: { updatedAt: 'desc' },
      }),
      getRecentActions(60),
    ]);

    const oldest = [oldestPartner?.createdAt, oldestProduct?.updatedAt]
      .filter((d): d is Date => !!d)
      .reduce<Date | null>((a, b) => (!a || b < a ? b : a), null);
    const stuck = activeProjectsRaw.filter(p => {
      const last = latest(p.updatedAt, p.updates[0]?.createdAt, p.tasks[0]?.updatedAt);
      return now - last.getTime() >= QUIET_DAYS * DAY;
    }).length;

    const overview: OverviewData = {
      events: {
        customers: evCustomers.map(e => e.createdAt.toISOString()),
        partners: evPartners.map(e => e.createdAt.toISOString()),
        projects: evProjects.map(e => e.createdAt.toISOString()),
        orders: evOrders.map(e => e.createdAt.toISOString()),
        deals: evDeals.map(d => ({ at: d.updatedAt.toISOString(), amount: d.estimatedCost || 0 })),
      },
      now: {
        pendingPartners,
        pendingProducts,
        oldestPendingDays: oldest ? Math.floor((now - oldest.getTime()) / DAY) : 0,
        activeProjects: activeProjectsRaw.length,
        stuckProjects: stuck,
        openOrders,
        totalCustomers,
        totalPartners: idxProviders.length,
        verifiedPartners,
        liveProducts,
      },
    };

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
        provider: q.provider ? { id: q.provider.id, businessName: q.provider.businessName } : null,
      })),
      tasks: p.tasks.map(t => ({ id: t.id, status: t.status })),
    }));

    const acceptedQuotesJson = acceptedQuotesRaw.map(q => ({
      id: q.id,
      estimatedCost: q.estimatedCost,
      isAccepted: q.isAccepted,
      createdAt: q.createdAt.toISOString(),
      updatedAt: q.updatedAt.toISOString(),
      provider: { id: q.provider.id, businessName: q.provider.businessName, ownerName: q.provider.ownerName },
    }));

    const materialOrders = completedInquiriesRaw.map(inq => {
      const qty = inq.quantity || 1;
      const unitPrice = inq.quotedPrice ?? inq.product?.pricePerUnit ?? 0;
      const totalRevenue = unitPrice * qty;
      // Partner's cost snapshot from the quote wins over the product's current cost
      const pnl = orderProfit({
        quantity: qty,
        quotedPrice: unitPrice,
        unitCost: inq.unitCost,
        extraCost: inq.extraCost,
        productCostPrice: inq.product?.costPrice,
      });
      const unitCost = inq.unitCost ?? inq.product?.costPrice ?? 0;
      const totalCost = pnl.cost ?? 0;
      // Unknown cost: keep the old 10% estimate so the chart is not empty
      const netProfit = pnl.known ? Math.round(pnl.profit ?? 0) : Math.round(totalRevenue * 0.1);
      return {
        id: inq.id,
        title: inq.title,
        quantity: qty,
        unit: inq.unit || inq.product?.unitType || 'Units',
        unitPrice,
        totalRevenue,
        unitCost,
        totalCost,
        netProfit,
        status: inq.status,
        deliveryStatus: inq.deliveryStatus,
        gstPercent: inq.gstPercent || 18,
        createdAt: inq.createdAt.toISOString(),
        updatedAt: inq.updatedAt.toISOString(),
        provider: inq.provider
          ? { id: inq.provider.id, businessName: inq.provider.businessName, ownerName: inq.provider.ownerName, email: inq.provider.email, phone: inq.provider.phone, category: inq.provider.category }
          : null,
        buyer: inq.buyer ? { id: inq.buyer.id, name: inq.buyer.name, email: inq.buyer.email } : null,
        product: inq.product ? { id: inq.product.id, name: inq.product.name, category: inq.product.category } : null,
      };
    });

    content = (
      <>
        <OverviewTiles data={overview} />
        <div className="mb-3 flex items-center gap-2">
          <h2 className="text-sm font-black uppercase tracking-[0.14em] text-cz-muted">Deep dive</h2>
          <span className="h-px flex-1 bg-cz-line" />
        </div>
        <DashboardAnalytics
          projects={projectsJson}
          acceptedQuotes={acceptedQuotesJson}
          providers={idxProviders.map(p => ({ id: p.id, businessName: p.businessName, ownerName: p.ownerName }))}
          recentActions={recentActions}
          materialOrders={materialOrders}
        />
      </>
    );
  }

  // --------------------------------------------------------------- Approvals
  if (view === 'pending') {
    const [partners, products] = await Promise.all([
      prisma.provider.findMany({
        where: { isVerified: false, isRejected: false },
        select: { id: true, businessName: true, ownerName: true, category: true, createdAt: true, profileCompletion: true },
        orderBy: { createdAt: 'asc' },
      }),
      prisma.product.findMany({
        where: { status: 'Pending', deletedAt: null },
        include: { provider: { select: { businessName: true, isVerified: true } } },
        orderBy: { updatedAt: 'asc' },
      }),
    ]);

    const items: InboxItem[] = [
      ...partners.map<InboxItem>(p => ({
        kind: 'partner',
        id: p.id,
        title: p.businessName,
        owner: p.ownerName,
        category: p.category,
        createdAt: p.createdAt.toISOString(),
        profileCompletion: p.profileCompletion,
      })),
      ...products.map<InboxItem>(p => ({
        kind: 'product',
        id: p.id,
        title: p.name,
        supplierName: p.provider.businessName,
        supplierVerified: p.provider.isVerified,
        category: categoryNameFor(p.categoryId, p.category),
        createdAt: p.updatedAt.toISOString(),
        image: p.images[0] || null,
        pricePerUnit: p.pricePerUnit,
        unitType: p.unitType,
        description: p.description,
        rejectedReason: p.rejectedReason,
      })),
    ].sort((a, b) => a.createdAt.localeCompare(b.createdAt)); // oldest first - fair queue

    content = <ApprovalsInbox items={items} />;
  }

  // ---------------------------------------------------------------- Projects
  if (view === 'projects') {
    const raw = await prisma.project.findMany({
      select: {
        id: true, title: true, type: true, location: true, budget: true, currentStage: true, createdAt: true, updatedAt: true,
        user: { select: { id: true, name: true } },
        quotes: { select: { isAccepted: true, provider: { select: { id: true, businessName: true } } } },
        tasks: { select: { status: true, updatedAt: true } },
        updates: { select: { createdAt: true }, orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: { createdAt: 'desc' },
    });
    const projects: BoardProject[] = raw.map(p => {
      const hired = p.quotes.find(q => q.isAccepted);
      return {
        id: p.id,
        title: p.title,
        type: p.type,
        location: p.location,
        budget: p.budget,
        stage: p.currentStage,
        client: p.user.name,
        clientId: p.user.id,
        partner: hired?.provider.businessName ?? null,
        partnerId: hired?.provider.id ?? null,
        quotes: p.quotes.length,
        tasksDone: p.tasks.filter(t => (t.status || '').toLowerCase() === 'completed').length,
        tasksTotal: p.tasks.length,
        createdAt: p.createdAt.toISOString(),
        lastActivity: latest(p.updatedAt, p.updates[0]?.createdAt, ...p.tasks.map(t => t.updatedAt)).toISOString(),
      };
    });
    content = <ProjectsBoard projects={projects} initialOpen={openId} />;
  }

  // --------------------------------------------------------------- Customers
  if (view === 'users') {
    const raw = await prisma.user.findMany({
      where: { role: 'CONSUMER' },
      select: { id: true, name: true, email: true, phone: true, isApproved: true, createdAt: true, _count: { select: { projects: true, inquiries: true } } },
      orderBy: { createdAt: 'desc' },
    });
    const customers: CustomerRow[] = raw.map(u => ({
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      isApproved: u.isApproved,
      createdAt: u.createdAt.toISOString(),
      projects: u._count.projects,
      orders: u._count.inquiries,
    }));
    content = <CustomersView customers={customers} initialOpen={openId} />;
  }

  // ---------------------------------------------------------------- Partners
  if (view === 'providers') {
    const raw = await prisma.provider.findMany({
      select: {
        id: true, businessName: true, ownerName: true, email: true, phone: true, category: true,
        isVerified: true, isRejected: true, createdAt: true, subscriptionStatus: true, subscriptionExpiresAt: true,
        _count: { select: { quotes: true, products: { where: { deletedAt: null } } } },
      },
      orderBy: { createdAt: 'desc' },
    });
    const partners: PartnerRow[] = raw.map(p => {
      const exp = p.subscriptionExpiresAt?.getTime() ?? 0;
      const daysLeft = exp > now ? Math.ceil((exp - now) / DAY) : 0;
      const status = p.subscriptionStatus === 'ACTIVE' && daysLeft > 0 ? 'ACTIVE' : p.subscriptionExpiresAt ? 'EXPIRED' : p.subscriptionStatus || 'INACTIVE';
      return {
        id: p.id,
        businessName: p.businessName,
        ownerName: p.ownerName,
        email: p.email,
        phone: p.phone,
        category: p.category,
        isVerified: p.isVerified,
        isRejected: p.isRejected,
        createdAt: p.createdAt.toISOString(),
        subscriptionStatus: status,
        daysLeft,
        subscriptionExpiresAt: p.subscriptionExpiresAt?.toISOString() ?? null,
        quotes: p._count.quotes,
        products: p._count.products,
      };
    });
    content = <PartnersView partners={partners} initialOpen={openId} />;
  }

  // ---------------------------------------------------------------- Products
  if (view === 'products') {
    const raw = await prisma.product.findMany({
      where: { deletedAt: null },
      include: { provider: { select: { businessName: true, isVerified: true } } },
      orderBy: { createdAt: 'desc' },
    });
    const products: ModerationProduct[] = raw.map(p => ({
      id: p.id,
      name: p.name,
      description: p.description,
      category: categoryNameFor(p.categoryId, p.category),
      pricePerUnit: p.pricePerUnit,
      unitType: p.unitType,
      image: p.images[0] || null,
      status: p.status,
      rejectedReason: p.rejectedReason,
      supplierName: p.provider.businessName,
      supplierVerified: p.provider.isVerified,
      createdAt: p.createdAt.toISOString(),
    }));
    content = <ProductsModeration initialProducts={products} />;
  }

  // --------------------------------------------------------------------- Ads
  if (view === 'ads') {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const allAdsRaw = await (prisma as any).ad.findMany({ orderBy: { createdAt: 'desc' } });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const adsJson = allAdsRaw.map((ad: any) => ({
      id: ad.id,
      title: ad.title,
      desc: ad.desc,
      badge: ad.badge,
      icon: ad.icon,
      gradient: ad.gradient,
      imageUrl: ad.imageUrl || null,
      mediaType: ad.mediaType || (ad.videoUrl ? 'video' : 'image'),
      videoUrl: ad.videoUrl || null,
      targetSide: ad.targetSide || 'ALL',
      actionUrl: ad.actionUrl || null,
      actionText: ad.actionText || 'Explore Now',
      isActive: ad.isActive !== undefined ? Boolean(ad.isActive) : true,
      createdAt: ad.createdAt.toISOString(),
    }));
    content = <AdsManager initialAds={adsJson} />;
  }

  // ---------------------------------------------------------------- Activity
  if (view === 'recent-actions') {
    content = <RecentActionsFeed initialActions={await getRecentActions(60)} />;
  }

  return (
    <AdminShell
      view={view}
      initialTheme={theme}
      initialCollapsed={collapsed}
      approvalsCount={pendingPartners + pendingProducts}
      searchIndex={searchIndex}
    >
      <ViewTransitionContainer currentView={view}>{content}</ViewTransitionContainer>
    </AdminShell>
  );
}
