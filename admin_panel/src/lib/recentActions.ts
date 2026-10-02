import prisma from '@/lib/prisma';

export interface RecentAction {
  id: string;
  category: 'project' | 'task' | 'quote' | 'user' | 'provider' | 'inquiry' | 'subscription' | 'review' | 'ad';
  actionType: string;
  title: string;
  description: string;
  actor: {
    name: string;
    role: string;
    avatarColor?: string;
  };
  entityTitle?: string;
  location?: string;
  timestamp: string; // ISO
  badge: {
    text: string;
    color: 'blue' | 'emerald' | 'amber' | 'indigo' | 'purple' | 'rose' | 'teal' | 'slate' | 'sky';
  };
  amount?: number;
  status?: string;
  hasPhoto?: boolean;
  photoUrl?: string;
  metadata?: Record<string, string | number | boolean | null | undefined>;
}

export async function getRecentActions(limit = 50): Promise<RecentAction[]> {
  try {
    const [
      recentProjects,
      recentTasks,
      recentQuotes,
      recentUsers,
      recentProviders,
      recentInquiries,
      recentSubscriptions,
      recentReviews,
      recentAds,
    ] = await Promise.all([
      // 1. Projects
      prisma.project.findMany({
        take: 15,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { name: true, email: true } },
        },
      }),

      // 2. Project Tasks / Milestones
      prisma.projectTask.findMany({
        take: 20,
        orderBy: { updatedAt: 'desc' },
        include: {
          project: {
            select: {
              id: true,
              title: true,
              location: true,
              user: { select: { name: true } },
            },
          },
        },
      }),

      // 3. Quotes
      prisma.quote.findMany({
        take: 20,
        orderBy: { updatedAt: 'desc' },
        include: {
          project: { select: { id: true, title: true, location: true, user: { select: { name: true } } } },
          provider: { select: { id: true, businessName: true, ownerName: true } },
        },
      }),

      // 4. Users (Homeowners)
      prisma.user.findMany({
        where: { role: 'CONSUMER' },
        take: 15,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          isApproved: true,
          createdAt: true,
        },
      }),

      // 5. Providers
      prisma.provider.findMany({
        take: 15,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          businessName: true,
          ownerName: true,
          category: true,
          isVerified: true,
          isRejected: true,
          subscriptionStatus: true,
          createdAt: true,
          updatedAt: true,
        },
      }),

      // 6. Inquiries
      prisma.inquiry.findMany({
        take: 15,
        orderBy: { updatedAt: 'desc' },
        include: {
          buyer: { select: { id: true, name: true } },
          provider: { select: { id: true, businessName: true } },
          product: { select: { id: true, name: true } },
        },
      }),

      // 7. Subscriptions
      prisma.subscription.findMany({
        take: 15,
        orderBy: { createdAt: 'desc' },
        include: {
          provider: { select: { id: true, businessName: true, ownerName: true } },
        },
      }),

      // 8. Reviews
      prisma.review.findMany({
        take: 15,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { name: true } },
          provider: { select: { businessName: true } },
          project: { select: { title: true } },
        },
      }),

      // 9. Ads
      prisma.ad.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const actions: RecentAction[] = [];

    // Map Projects
    recentProjects.forEach((p) => {
      actions.push({
        id: `project-${p.id}`,
        category: 'project',
        actionType: 'PROJECT_CREATED',
        title: 'New Construction Project Created',
        description: `${p.user?.name || 'Client'} posted "${p.title}" (${p.type}) in ${p.location}`,
        actor: {
          name: p.user?.name || 'Homeowner',
          role: 'Homeowner',
          avatarColor: 'bg-blue-600',
        },
        entityTitle: p.title,
        location: p.location,
        amount: p.budget,
        timestamp: p.createdAt.toISOString(),
        badge: {
          text: p.currentStage || 'New Project',
          color: 'blue',
        },
        metadata: {
          type: p.type,
          timeline: p.timeline,
          plotSize: `${p.plotSize} sq ft`,
        },
      });
    });

    // Map Tasks / Milestones
    recentTasks.forEach((t) => {
      const isCompleted = t.status.toLowerCase() === 'completed';
      const isInProgress = t.status.toLowerCase() === 'in progress';

      actions.push({
        id: `task-${t.id}-${t.updatedAt.getTime()}`,
        category: 'task',
        actionType: isCompleted ? 'TASK_COMPLETED' : isInProgress ? 'TASK_IN_PROGRESS' : 'TASK_CREATED',
        title: isCompleted ? 'Site Milestone Completed' : isInProgress ? 'Milestone In Progress' : 'Task Scheduled',
        description: `"${t.title}" (${t.stage}) on project "${t.project?.title || 'Project'}"`,
        actor: {
          name: t.project?.user?.name || 'Site Crew',
          role: 'Site Contractor',
          avatarColor: isCompleted ? 'bg-emerald-600' : 'bg-amber-500',
        },
        entityTitle: t.project?.title,
        location: t.project?.location,
        amount: t.taskCost || undefined,
        status: t.status,
        hasPhoto: !!t.photoUrl,
        photoUrl: t.photoUrl || undefined,
        timestamp: t.updatedAt.toISOString(),
        badge: {
          text: t.status,
          color: isCompleted ? 'emerald' : isInProgress ? 'amber' : 'slate',
        },
        metadata: {
          stage: t.stage,
          material: t.materialName ? `${t.materialQuantity || ''} ${t.materialName}` : undefined,
          duration: `${t.duration} days`,
        },
      });
    });

    // Map Quotes
    recentQuotes.forEach((q) => {
      const isAccepted = q.isAccepted;
      actions.push({
        id: `quote-${q.id}-${isAccepted ? 'accepted' : 'created'}`,
        category: 'quote',
        actionType: isAccepted ? 'QUOTE_ACCEPTED' : 'QUOTE_SUBMITTED',
        title: isAccepted ? 'Quote Proposal Accepted' : 'New Quote Proposal Submitted',
        description: isAccepted
          ? `${q.project?.user?.name || 'Client'} accepted quote from ${q.provider?.businessName || 'Contractor'} for "${q.project?.title || 'Project'}"`
          : `${q.provider?.businessName || 'Contractor'} bid on "${q.project?.title || 'Project'}"`,
        actor: {
          name: q.provider?.businessName || 'Contractor',
          role: isAccepted ? 'Verified Contractor' : 'Bidding Provider',
          avatarColor: isAccepted ? 'bg-emerald-600' : 'bg-indigo-600',
        },
        entityTitle: q.project?.title,
        location: q.project?.location,
        amount: q.estimatedCost,
        timestamp: isAccepted ? q.updatedAt.toISOString() : q.createdAt.toISOString(),
        badge: {
          text: isAccepted ? 'Accepted & Awarded' : 'Pending Review',
          color: isAccepted ? 'emerald' : 'indigo',
        },
        metadata: {
          timeline: q.timeline,
          notes: q.notes ? q.notes.slice(0, 100) : undefined,
        },
      });
    });

    // Map Users
    recentUsers.forEach((u) => {
      actions.push({
        id: `user-${u.id}`,
        category: 'user',
        actionType: 'USER_REGISTERED',
        title: 'New Client Onboarded',
        description: `${u.name} registered as a property owner (${u.email})`,
        actor: {
          name: u.name,
          role: 'Homeowner',
          avatarColor: 'bg-blue-500',
        },
        timestamp: u.createdAt.toISOString(),
        badge: {
          text: u.isApproved ? 'Active Client' : 'Pending',
          color: u.isApproved ? 'blue' : 'slate',
        },
        metadata: {
          email: u.email,
          phone: u.phone || undefined,
        },
      });
    });

    // Map Providers
    recentProviders.forEach((p) => {
      actions.push({
        id: `provider-${p.id}`,
        category: 'provider',
        actionType: p.isVerified ? 'PROVIDER_VERIFIED' : p.isRejected ? 'PROVIDER_REJECTED' : 'PROVIDER_REGISTERED',
        title: p.isVerified ? 'Provider Verified' : p.isRejected ? 'Provider Rejected' : 'New Provider Application',
        description: `${p.businessName} (${p.ownerName}) registered in category "${p.category}"`,
        actor: {
          name: p.businessName,
          role: p.category,
          avatarColor: p.isVerified ? 'bg-emerald-600' : p.isRejected ? 'bg-rose-600' : 'bg-amber-500',
        },
        timestamp: p.createdAt.toISOString(),
        badge: {
          text: p.isVerified ? 'Verified Pro' : p.isRejected ? 'Rejected' : 'Needs Approval',
          color: p.isVerified ? 'emerald' : p.isRejected ? 'rose' : 'amber',
        },
        metadata: {
          category: p.category,
          subscription: p.subscriptionStatus,
        },
      });
    });

    // Map Inquiries (B2B Materials)
    recentInquiries.forEach((inq) => {
      const isAccepted = inq.status.toLowerCase() === 'accepted';
      actions.push({
        id: `inquiry-${inq.id}`,
        category: 'inquiry',
        actionType: isAccepted ? 'INQUIRY_ACCEPTED' : 'INQUIRY_CREATED',
        title: isAccepted ? 'B2B Material Order Accepted' : 'New Material Inquiry (RFQ)',
        description: `${inq.buyer?.name || 'Buyer'} requested ${inq.quantity} ${inq.unit} from ${inq.provider?.businessName || 'Supplier'} (${inq.title})`,
        actor: {
          name: inq.buyer?.name || 'Buyer',
          role: 'Material Buyer',
          avatarColor: 'bg-purple-600',
        },
        entityTitle: inq.title,
        location: inq.location,
        amount: inq.quotedPrice || undefined,
        status: inq.status,
        timestamp: inq.updatedAt.toISOString(),
        badge: {
          text: `Inquiry: ${inq.status}`,
          color: isAccepted ? 'emerald' : 'purple',
        },
        metadata: {
          product: inq.product?.name || inq.title,
          quantity: `${inq.quantity} ${inq.unit}`,
          deliveryStatus: inq.deliveryStatus,
        },
      });
    });

    // Map Subscriptions
    recentSubscriptions.forEach((sub) => {
      actions.push({
        id: `subscription-${sub.id}`,
        category: 'subscription',
        actionType: 'SUBSCRIPTION_ACTIVATED',
        title: 'Provider Pro Subscription Paid',
        description: `${sub.provider?.businessName || 'Provider'} activated ${sub.plan.replace('_', ' ')} plan for ₹${sub.amount.toLocaleString('en-IN')}`,
        actor: {
          name: sub.provider?.businessName || 'Contractor',
          role: 'Pro Member',
          avatarColor: 'bg-emerald-600',
        },
        amount: sub.amount,
        status: sub.status,
        timestamp: sub.createdAt.toISOString(),
        badge: {
          text: 'Payment Success',
          color: 'emerald',
        },
        metadata: {
          plan: sub.plan,
          expiresAt: sub.expiresAt.toLocaleDateString('en-IN'),
          orderId: sub.razorpayOrderId || undefined,
        },
      });
    });

    // Map Reviews
    recentReviews.forEach((rev) => {
      actions.push({
        id: `review-${rev.id}`,
        category: 'review',
        actionType: 'REVIEW_POSTED',
        title: `Client Review (${rev.rating}★ Stars)`,
        description: `${rev.user?.name || 'Client'} rated ${rev.provider?.businessName || 'Provider'}: "${rev.comment.length > 70 ? rev.comment.slice(0, 70) + '...' : rev.comment}"`,
        actor: {
          name: rev.user?.name || 'Client',
          role: 'Client Reviewer',
          avatarColor: 'bg-amber-500',
        },
        entityTitle: rev.project?.title,
        timestamp: rev.createdAt.toISOString(),
        badge: {
          text: `${rev.rating} ★ Rating`,
          color: 'amber',
        },
        metadata: {
          comment: rev.comment,
        },
      });
    });

    // Map Ads
    recentAds.forEach((ad) => {
      actions.push({
        id: `ad-${ad.id}`,
        category: 'ad',
        actionType: 'AD_POSTED',
        title: 'Promotional Ad Campaign Live',
        description: `Campaign "${ad.title}" broadcasting to ${ad.targetSide.toLowerCase()}s`,
        actor: {
          name: 'Admin System',
          role: 'Administrator',
          avatarColor: 'bg-slate-700',
        },
        timestamp: ad.createdAt.toISOString(),
        badge: {
          text: ad.targetSide,
          color: 'sky',
        },
        metadata: {
          badge: ad.badge,
          actionText: ad.actionText || undefined,
        },
      });
    });

    // Sort all by timestamp descending
    actions.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

    return actions.slice(0, limit);
  } catch (error) {
    console.error('Error fetching recent actions:', error);
    return [];
  }
}
