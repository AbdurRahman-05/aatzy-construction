import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

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
      }
    }

    return NextResponse.json(updatedQuote);
  } catch (error) {
    console.error('Update quote error:', error);
    return NextResponse.json({ error: 'Failed to update quote' }, { status: 500 });
  }
}
