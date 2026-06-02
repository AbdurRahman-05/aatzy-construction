import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const provider = await prisma.provider.findUnique({
      where: { id },
      select: { category: true }
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    // Leads = Projects in the same category
    const activeLeadsCount = await prisma.project.count({
      where: { type: provider.category }
    });

    // Projects = Projects where this provider has sent a quote
    const projectsCount = await prisma.quote.count({
      where: { providerId: id }
    });

    // Recent Leads = Latest 5 projects in the same category
    const recentLeads = await prisma.project.findMany({
      where: { type: provider.category },
      orderBy: { createdAt: 'desc' },
      take: 5,
      include: {
        user: { select: { name: true } }
      }
    });

    return NextResponse.json({
      activeLeads: activeLeadsCount,
      projects: projectsCount,
      recentLeads: recentLeads.map(l => ({
        id: l.id,
        title: l.title,
        userName: l.user.name,
        createdAt: l.createdAt
      }))
    });

  } catch (error) {
    console.error('Stats error:', error);
    return NextResponse.json({ error: 'Failed to fetch stats' }, { status: 500 });
  }
}
