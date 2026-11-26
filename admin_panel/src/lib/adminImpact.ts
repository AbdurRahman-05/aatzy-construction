import prisma from '@/lib/prisma';

/**
 * What deleting an account will remove. Shown in the admin delete dialog so the admin
 * sees the real consequences before typing the name to confirm.
 * Must stay in step with the DELETE handlers in api/providers/[id] and api/users/[id].
 */

// Same list the provider DELETE route uses to decide which projects to reopen.
export const PROVIDER_FINISHED_STAGES = ['completed', 'finished', 'finished pending approval', 'cancelled'];
// Same list the user DELETE route uses to decide which partners to notify.
export const USER_FINISHED_STAGES = ['completed', 'finished', 'cancelled'];

export interface ImpactLine {
  label: string;
  count: number;
  /** "removed" lines are deleted; "changed" lines are kept but modified. */
  kind: 'removed' | 'changed';
}

export async function providerDeleteImpact(id: string): Promise<ImpactLine[]> {
  const [quotes, accepted, products, inquiries, reviews, portfolio, payments] = await Promise.all([
    prisma.quote.count({ where: { providerId: id } }),
    prisma.quote.findMany({ where: { providerId: id, isAccepted: true }, select: { project: { select: { currentStage: true } } } }),
    prisma.product.count({ where: { providerId: id, deletedAt: null } }),
    prisma.inquiry.count({ where: { providerId: id } }),
    prisma.review.count({ where: { providerId: id } }),
    prisma.portfolioImage.count({ where: { providerId: id } }),
    prisma.subscription.count({ where: { providerId: id } }),
  ]);
  const reopen = accepted.filter(q => !PROVIDER_FINISHED_STAGES.includes((q.project.currentStage || '').toLowerCase().trim())).length;

  return [
    { label: 'active projects reopen for new quotes (clients are notified)', count: reopen, kind: 'changed' },
    { label: 'quotes sent to customers', count: quotes, kind: 'removed' },
    { label: 'material products', count: products, kind: 'removed' },
    { label: 'material orders & enquiries', count: inquiries, kind: 'removed' },
    { label: 'reviews', count: reviews, kind: 'removed' },
    { label: 'portfolio photos', count: portfolio, kind: 'removed' },
    { label: 'membership payment records', count: payments, kind: 'removed' },
  ];
}

export async function userDeleteImpact(id: string): Promise<ImpactLine[]> {
  const [projects, quotes, accepted, inquiries, reviews] = await Promise.all([
    prisma.project.count({ where: { userId: id } }),
    prisma.quote.count({ where: { project: { userId: id } } }),
    prisma.quote.findMany({ where: { isAccepted: true, project: { userId: id } }, select: { project: { select: { currentStage: true } } } }),
    prisma.inquiry.count({ where: { buyerId: id } }),
    prisma.review.count({ where: { userId: id } }),
  ]);
  const activePartners = accepted.filter(q => !USER_FINISHED_STAGES.includes((q.project.currentStage || '').toLowerCase().trim())).length;

  return [
    { label: 'partners working on their projects are told the project is cancelled', count: activePartners, kind: 'changed' },
    { label: 'projects (with their tasks and updates)', count: projects, kind: 'removed' },
    { label: 'quotes partners sent for those projects', count: quotes, kind: 'removed' },
    { label: 'material orders & enquiries', count: inquiries, kind: 'removed' },
    { label: 'reviews they wrote', count: reviews, kind: 'removed' },
  ];
}
