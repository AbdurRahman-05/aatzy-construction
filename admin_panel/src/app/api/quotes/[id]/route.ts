import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { createNotification } from '@/lib/notifications';
import { sendQuoteAcceptedNotification } from '@/lib/mail';
import { requireAuth, forbidden } from '@/lib/auth';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    // Only consumers (project owners) can accept / un-accept quotes
    const authResult = requireAuth(request, { roles: ['CONSUMER'] });
    if (!authResult.ok) return authResult.response;
    const auth = authResult.auth;

    const { id } = await context.params;
    const body = await request.json();
    const accept = !!body.isAccepted;

    const existing = await prisma.quote.findUnique({
      where: { id },
      include: { project: { select: { id: true, userId: true } } },
    });
    if (!existing) {
      return NextResponse.json({ error: 'Quote not found' }, { status: 404 });
    }

    // Ownership: the caller must own the project this quote belongs to
    if (auth && existing.project.userId !== auth.id) {
      return forbidden('Only the project owner can accept or decline quotes for this project.');
    }

    if (!accept) {
      const declined = await prisma.quote.update({ where: { id }, data: { isAccepted: false } });
      return NextResponse.json(declined);
    }

    // Idempotent: accepting an already-accepted quote is a no-op
    if (existing.isAccepted) {
      return NextResponse.json(existing);
    }

    // Do not silently replace a partner who is already working on the project
    const otherAccepted = await prisma.quote.findFirst({
      where: { projectId: existing.projectId, isAccepted: true, id: { not: id } },
      select: { id: true },
    });
    if (otherAccepted) {
      return NextResponse.json(
        { error: 'A quote has already been accepted for this project.', code: 'QUOTE_ALREADY_ACCEPTED' },
        { status: 409 }
      );
    }

    // All-or-nothing: accept this quote, reset the others, start tracking
    const [, updatedQuote] = await prisma.$transaction([
      prisma.quote.updateMany({
        where: { projectId: existing.projectId, id: { not: id } },
        data: { isAccepted: false },
      }),
      prisma.quote.update({ where: { id }, data: { isAccepted: true } }),
      prisma.project.update({
        where: { id: existing.projectId },
        data: {
          currentStage: 'Tracking',
          ...(existing.estimatedCost > 0 ? { budget: existing.estimatedCost } : {}),
        },
      }),
    ]);

    // Notifications are best-effort and happen after the data is safely committed
    try {
      const [project, provider] = await Promise.all([
        prisma.project
          .findUnique({
            where: { id: existing.projectId },
            include: { user: { select: { id: true, name: true, email: true } } },
          })
          .catch(() => null),
        prisma.provider.findUnique({ where: { id: existing.providerId } }).catch(() => null),
      ]);

      if (project && project.user && provider) {
        await createNotification({
          recipientId: existing.providerId,
          role: 'PROVIDER',
          title: '🤝 Bid Accepted!',
          body: `Great news! The client accepted your quote for "${project.title}". Project tracking has started.`,
          type: 'QUOTE_ACCEPTED',
          entityId: existing.projectId,
          route: `/provider-job/${existing.projectId}`,
        });

        await createNotification({
          recipientId: project.userId,
          role: 'CONSUMER',
          title: '🎉 Contract Confirmed',
          body: `You accepted ${provider.businessName}'s quote for "${project.title}". Execution tracking is now active.`,
          type: 'QUOTE_ACCEPTED',
          entityId: existing.projectId,
          route: `/project-detail/${existing.projectId}`,
        });

        sendQuoteAcceptedNotification(updatedQuote, project, project.user, provider).catch((err: any) => {
          console.error('Quote acceptance notification email error:', err);
        });
      }
    } catch (notifErr) {
      console.error('Failed to dispatch quote acceptance notifications:', notifErr);
    }

    return NextResponse.json(updatedQuote);
  } catch (error) {
    console.error('Update quote error:', error);
    return NextResponse.json({ error: 'Failed to update quote' }, { status: 500 });
  }
}
