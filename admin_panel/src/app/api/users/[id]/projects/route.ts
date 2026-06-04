import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const projects = await prisma.project.findMany({
      where: { userId: id },
      orderBy: { createdAt: 'desc' },
      include: {
        tasks: true,
        _count: {
          select: { quotes: true }
        }
      }
    });

    return NextResponse.json(projects);

  } catch (error) {
    console.error('Fetch projects error:', error);
    return NextResponse.json({ error: 'Failed to fetch projects' }, { status: 500 });
  }
}
