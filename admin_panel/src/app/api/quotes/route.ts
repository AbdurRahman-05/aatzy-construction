import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { createNotification } from '@/lib/notifications';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';
import { isProjectOpenForQuotes } from '@/lib/projectAccess';

export async function POST(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;

    const body = await request.json();
    const { projectId, providerId, estimatedCost, timeline, notes } = body;

    if (!projectId || !providerId || !estimatedCost || !timeline) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // A partner can only quote as themselves
    const notSelf = denyUnlessSelf(authResult.auth, providerId);
    if (notSelf) return notSelf;

    const cost = parseFloat(estimatedCost.toString());
    if (!Number.isFinite(cost) || cost <= 0) {
      return NextResponse.json({ error: 'Estimated cost must be a positive number' }, { status: 400 });
    }

    // Only verified (admin-approved) partners may bid
    const bidder = await prisma.provider.findUnique({
      where: { id: providerId },
      select: { isVerified: true, isRejected: true },
    });
    if (!bidder) {
      return NextResponse.json({ error: 'Partner account not found' }, { status: 404 });
    }
    if (!bidder.isVerified || bidder.isRejected) {
      return NextResponse.json(
        { error: 'Your partner account must be approved by an admin before you can send quotes.', code: 'PROVIDER_NOT_VERIFIED' },
        { status: 403 }
      );
    }

    // Project must exist, still be open, and not have an accepted quote already
    const targetProject = await prisma.project.findUnique({
      where: { id: projectId },
      select: { userId: true, currentStage: true },
    });
    if (!targetProject) {
      return NextResponse.json({ error: 'Project not found' }, { status: 404 });
    }
    const alreadyAccepted = await prisma.quote.findFirst({
      where: { projectId, isAccepted: true },
      select: { id: true },
    });
    if (alreadyAccepted || !isProjectOpenForQuotes(targetProject.currentStage)) {
      return NextResponse.json(
        { error: 'This project is no longer accepting quotes.', code: 'PROJECT_CLOSED' },
        { status: 409 }
      );
    }

    // One quote per partner per project
    const existingQuote = await prisma.quote.findFirst({
      where: { projectId, providerId },
      select: { id: true },
    });
    if (existingQuote) {
      return NextResponse.json(
        { error: 'You have already submitted a quote for this project.', code: 'DUPLICATE_QUOTE', quoteId: existingQuote.id },
        { status: 409 }
      );
    }

    const quote = await prisma.quote.create({
      data: {
        projectId,
        providerId,
        estimatedCost: cost,
        timeline,
        notes: notes || '',
      }
    });

    // Fetch details to send quote proposal notification emails & in-app notification
    try {
      const [project, provider] = await Promise.all([
        prisma.project
          .findUnique({
            where: { id: projectId },
            include: { user: { select: { id: true, name: true, email: true } } },
          })
          .catch(() => null),
        prisma.provider.findUnique({ where: { id: providerId } }).catch(() => null),
      ]);

      if (project && project.user && provider) {
        // In-app notification & push to consumer
        await createNotification({
          recipientId: project.userId,
          role: 'CONSUMER',
          title: `💬 New Bid: ${provider.businessName}`,
          body: `Submitted a quote of ₹${quote.estimatedCost.toLocaleString()} on "${project.title}". Tap to review.`,
          type: 'NEW_QUOTE',
          entityId: project.id,
          route: `/compare-quotes/${project.id}`,
        });

        const { sendQuoteNotification } = require('@/lib/mail');
        sendQuoteNotification(quote, project, project.user, provider).catch((err: any) => {
          console.error('Quote proposal email error:', err);
        });
      }
    } catch (notifErr) {
      console.error('Failed to dispatch quote proposal notification:', notifErr);
    }

    return NextResponse.json(quote, { status: 201 });
  } catch (error) {
    console.error('Create quote error:', error);
    return NextResponse.json({ error: 'Failed to submit quote' }, { status: 500 });
  }
}
