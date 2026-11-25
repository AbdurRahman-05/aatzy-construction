import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;
    const { id } = await context.params;
    // A customer can only list their own projects
    const notSelf = denyUnlessSelf(authResult.auth, id);
    if (notSelf) return notSelf;

    const projects = await prisma.project.findMany({
      where: { userId: id },
      orderBy: { createdAt: 'desc' },
      include: {
        tasks: true,
        quotes: {
          select: {
            id: true,
            isAccepted: true,
            estimatedCost: true,
            providerId: true,
          }
        },
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
