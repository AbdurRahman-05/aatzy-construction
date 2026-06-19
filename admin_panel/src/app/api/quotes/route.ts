import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

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

    // Fetch details to send quote proposal notification emails
    Promise.all([
      prisma.project.findUnique({ where: { id: projectId }, include: { user: true } }),
      prisma.provider.findUnique({ where: { id: providerId } }),
    ]).then(([project, provider]) => {
      if (project && project.user && provider) {
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
