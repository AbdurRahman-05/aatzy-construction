import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAdmin } from '@/lib/auth';

/** Project detail for the admin Projects board side panel (photos left out to keep it light). */
export async function GET(_request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    const p = await prisma.project.findUnique({
      where: { id },
      select: {
        id: true, title: true, type: true, location: true, plotSize: true, budget: true, timeline: true,
        currentStage: true, createdAt: true, updatedAt: true,
        user: { select: { id: true, name: true, email: true, phone: true } },
        quotes: {
          select: {
            id: true, estimatedCost: true, timeline: true, isAccepted: true, createdAt: true,
            provider: { select: { id: true, businessName: true, phone: true, isVerified: true } },
          },
          orderBy: [{ isAccepted: 'desc' }, { estimatedCost: 'asc' }],
        },
        tasks: {
          select: { id: true, stage: true, title: true, status: true, duration: true, taskCost: true, updatedAt: true },
          orderBy: { createdAt: 'asc' },
        },
        updates: {
          select: { id: true, title: true, status: true, notes: true, createdAt: true },
          orderBy: { createdAt: 'desc' },
          take: 12,
        },
      },
    });
    if (!p) return NextResponse.json({ error: 'Project not found' }, { status: 404 });

    const lastActivity = [p.updatedAt, ...p.updates.map(u => u.createdAt), ...p.tasks.map(t => t.updatedAt)]
      .reduce((a, b) => (b > a ? b : a), p.createdAt);

    return NextResponse.json({
      ...p,
      createdAt: p.createdAt.toISOString(),
      updatedAt: p.updatedAt.toISOString(),
      lastActivity: lastActivity.toISOString(),
      quotes: p.quotes.map(q => ({ ...q, createdAt: q.createdAt.toISOString() })),
      tasks: p.tasks.map(t => ({ ...t, updatedAt: t.updatedAt.toISOString() })),
      updates: p.updates.map(u => ({ ...u, createdAt: u.createdAt.toISOString() })),
    });
  } catch (error) {
    console.error('Admin project detail error:', error);
    return NextResponse.json({ error: 'Failed to load project' }, { status: 500 });
  }
}
