import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { createNotification } from '@/lib/notifications';

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
        // Update the project's stage to Tracking to activate the tracking flow
        await prisma.project.update({
          where: { id: quote.projectId },
          data: { currentStage: 'Tracking' }
        });

        // Fetch details to send quote acceptance notification emails & in-app notifications
        Promise.all([
          prisma.project.findUnique({ where: { id: quote.projectId }, include: { user: true } }),
          prisma.provider.findUnique({ where: { id: quote.providerId } }),
        ]).then(([project, provider]) => {
          if (project && project.user && provider) {
            // 1. Notify Provider: Quote was accepted!
            createNotification({
              recipientId: quote.providerId,
              role: 'PROVIDER',
              title: '🤝 Bid Accepted!',
              body: `Great news! The client accepted your quote for "${project.title}". Project tracking has started.`,
              type: 'QUOTE_ACCEPTED',
              entityId: quote.projectId,
              route: `/provider-job/${quote.projectId}`,
            }).catch(err => console.error('Provider quote acceptance notification error:', err));

            // 2. Notify Consumer: Contract Confirmed!
            createNotification({
              recipientId: project.userId,
              role: 'CONSUMER',
              title: '🎉 Contract Confirmed',
              body: `You accepted ${provider.businessName}'s quote for "${project.title}". Execution tracking is now active.`,
              type: 'QUOTE_ACCEPTED',
              entityId: quote.projectId,
              route: `/project-detail/${quote.projectId}`,
            }).catch(err => console.error('Consumer quote confirmation notification error:', err));

            const { sendQuoteAcceptedNotification } = require('@/lib/mail');
            sendQuoteAcceptedNotification(updatedQuote, project, project.user, provider).catch((err: any) => {
              console.error('Quote acceptance notification email error:', err);
            });
          }
        }).catch(err => {
          console.error('Failed to fetch details for quote acceptance notification:', err);
        });
      }
    }

    return NextResponse.json(updatedQuote);
  } catch (error) {
    console.error('Update quote error:', error);
    return NextResponse.json({ error: 'Failed to update quote' }, { status: 500 });
  }
}
