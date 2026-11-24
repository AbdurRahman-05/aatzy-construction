import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { createNotification } from '@/lib/notifications';
import { sendQuoteAcceptedNotification } from '@/lib/mail';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const { isAccepted } = body;

    // Update the quote to be accepted
    const updatedQuote = await prisma.quote.update({
      where: { id },
      data: { isAccepted: !!isAccepted }
    });

    if (isAccepted) {
      // Fetch the quote to identify the project
      const quote = await prisma.quote.findUnique({
        where: { id },
        include: { project: true }
      });

      if (quote) {
        // Mark all other quotes for this project as not accepted
        await prisma.quote.updateMany({
          where: {
            projectId: quote.projectId,
            id: { not: id }
          },
          data: { isAccepted: false }
        });

        // Update the project's stage to Tracking to activate the tracking flow
        await prisma.project.update({
          where: { id: quote.projectId },
          data: { currentStage: 'Tracking' }
        });

        // Fetch details to send quote acceptance notification emails & in-app notifications
        try {
          const [project, provider] = await Promise.all([
            prisma.project.findUnique({ where: { id: quote.projectId }, include: { user: true } }).catch(() => null),
            prisma.provider.findUnique({ where: { id: quote.providerId } }).catch(() => null),
          ]);

          if (project && project.user && provider) {
            // 1. Notify Provider: Quote was accepted!
            await createNotification({
              recipientId: quote.providerId,
              role: 'PROVIDER',
              title: '🤝 Bid Accepted!',
              body: `Great news! The client accepted your quote for "${project.title}". Project tracking has started.`,
              type: 'QUOTE_ACCEPTED',
              entityId: quote.projectId,
              route: `/provider-job/${quote.projectId}`,
            });

            // 2. Notify Consumer: Contract Confirmed!
            await createNotification({
              recipientId: project.userId,
              role: 'CONSUMER',
              title: '🎉 Contract Confirmed',
              body: `You accepted ${provider.businessName}'s quote for "${project.title}". Execution tracking is now active.`,
              type: 'QUOTE_ACCEPTED',
              entityId: quote.projectId,
              route: `/project-detail/${quote.projectId}`,
            });

            sendQuoteAcceptedNotification(updatedQuote, project, project.user, provider).catch((err: any) => {
              console.error('Quote acceptance notification email error:', err);
            });
          }
        } catch (notifErr) {
          console.error('Failed to dispatch quote acceptance notifications:', notifErr);
        }
      }
    }

    return NextResponse.json(updatedQuote);
  } catch (error) {
    console.error('Update quote error:', error);
    return NextResponse.json({ error: 'Failed to update quote' }, { status: 500 });
  }
}
