import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const acceptedQuotes = await prisma.quote.findMany({
      where: {
        providerId: id,
        isAccepted: true
      },
      include: {
        project: {
          include: {
            user: { select: { name: true } },
            tasks: true
          }
        }
      }
    });

    const projects = acceptedQuotes.map(q => ({
      ...q.project,
      quoteId: q.id
    }));

    return NextResponse.json(projects);

  } catch (error) {
    console.error('Fetch provider projects error:', error);
    return NextResponse.json({ error: 'Failed to fetch provider projects' }, { status: 500 });
  }
}
