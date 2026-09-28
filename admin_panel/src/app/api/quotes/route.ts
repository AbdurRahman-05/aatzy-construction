import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { createNotification } from '@/lib/notifications';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { projectId, providerId, estimatedCost, timeline, notes } = body;

    if (!projectId || !providerId || !estimatedCost || !timeline) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const quote = await prisma.quote.create({
      data: {
        projectId,
        providerId,
        estimatedCost: parseFloat(estimatedCost.toString()),
        timeline,
        notes: notes || '',
      }
    });

    // Fetch details to send quote proposal notification emails & in-app notification
    Promise.all([
      prisma.project.findUnique({ where: { id: projectId }, include: { user: true } }),
      prisma.provider.findUnique({ where: { id: providerId } }),
    ]).then(([project, provider]) => {
      if (project && project.user && provider) {
        // In-app notification to consumer
        createNotification({
          recipientId: project.userId,
          role: 'CONSUMER',
          title: `💬 New Bid: ${provider.businessName}`,
          body: `Submitted a quote of ₹${quote.estimatedCost.toLocaleString()} on "${project.title}". Tap to review.`,
          type: 'QUOTE_ACCEPTED',
          entityId: project.id,
          route: `/compare-quotes/${project.id}`,
        }).catch(err => console.error('Quote proposal in-app notification error:', err));

        const { sendQuoteNotification } = require('@/lib/mail');
        sendQuoteNotification(quote, project, project.user, provider).catch((err: any) => {
          console.error('Quote proposal email error:', err);
        });
      }
    }).catch(err => {
      console.error('Failed to fetch details for quote notification:', err);
    });

    return NextResponse.json(quote, { status: 201 });
  } catch (error) {
    console.error('Create quote error:', error);
    return NextResponse.json({ error: 'Failed to submit quote' }, { status: 500 });
  }
}
