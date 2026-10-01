import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { locationsMatch } from '@/lib/notifications';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const provider = await prisma.provider.findUnique({
      where: { id },
      select: { category: true, address: true }
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    // Fetch all active projects that don't have any accepted quotes
    const allProjects = await prisma.project.findMany({
      where: {
        quotes: {
          none: {
            isAccepted: true
          }
        },
        currentStage: {
          notIn: ['Completed', 'Finished', 'Cancelled', 'completed', 'finished', 'cancelled']
        }
      },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { name: true } }
      }
    });

    // Filter projects where project type/services matches provider.category
    const categoryProjects = allProjects.filter(project => {
      // If no category restriction on provider, show all
      if (!provider.category || provider.category.trim() === '' || provider.category.toLowerCase() === 'all') {
        return true;
      }
      if (!project.type || project.type.trim() === '') return true;

      const projectTypeLower = project.type.toLowerCase();
      const providerCategories = provider.category
        .split(',')
        .map(c => c.trim().toLowerCase())
        .filter(Boolean);

      if (providerCategories.length === 0) return true;

      // Check if any provider category matches project type or services
      return providerCategories.some(cat => {
        if (projectTypeLower.includes(cat)) return true;
        const tokens = projectTypeLower.split(/[,-/]/).map(t => t.trim()).filter(Boolean);
        return tokens.some(t => t === cat || t.includes(cat) || cat.includes(t));
      });
    });

    // Filter projects based on locations compatibility
    const matchedProjects = categoryProjects.filter(project => 
      locationsMatch(project.location, provider.address)
    );

    const activeLeadsCount = matchedProjects.length;
    const recentLeads = matchedProjects.slice(0, 5);

    // Fetch active jobs (where provider's quote is accepted and project is ongoing)
    const acceptedQuotes = await prisma.quote.findMany({
      where: {
        providerId: id,
        isAccepted: true
      },
      include: {
        project: {
          include: {
            user: { select: { name: true } }
          }
        }
      }
    });

    // Fetch all quotes submitted by this provider (both accepted and pending)
    const allQuotes = await prisma.quote.findMany({
      where: { providerId: id },
      include: {
        project: {
          select: {
            id: true,
            title: true,
            location: true,
            budget: true,
            currentStage: true,
            createdAt: true,
            user: { select: { name: true } },
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const activeJobs = acceptedQuotes.filter(q => {
      const stage = (q.project?.currentStage || '').toLowerCase().trim();
      return !['completed', 'finished', 'cancelled'].includes(stage);
    }).map(q => ({
      id: q.project.id,
      title: q.project.title,
      userName: q.project.user.name,
      location: q.project.location,
      budget: q.project.budget,
      timeline: q.project.timeline,
      currentStage: q.project.currentStage,
      quoteId: q.id,
      quoteAmount: q.estimatedCost,
      createdAt: q.createdAt,
    }));

    const totalQuotedRevenue = acceptedQuotes.reduce((sum, q) => sum + (q.estimatedCost || 0), 0);
    const projectsCount = activeJobs.length;

    return NextResponse.json({
      activeLeads: activeLeadsCount,
      projects: projectsCount,
      activeJobs,
      totalQuotes: allQuotes.length,
      acceptedQuotesCount: acceptedQuotes.length,
      totalRevenue: totalQuotedRevenue,
      allQuotes: allQuotes.map(q => ({
        id: q.id,
        projectId: q.projectId,
        projectTitle: q.project?.title,
        estimatedCost: q.estimatedCost,
        timeline: q.timeline,
        notes: q.notes,
        isAccepted: q.isAccepted,
        createdAt: q.createdAt,
      })),
      recentLeads: recentLeads.map(l => ({
        id: l.id,
        title: l.title,
        type: l.type,
        budget: l.budget,
        timeline: l.timeline,
        userName: l.user.name,
        location: l.location,
        createdAt: l.createdAt
      })),
      allLeads: matchedProjects.map(l => ({
        id: l.id,
        title: l.title,
        type: l.type,
        budget: l.budget,
        timeline: l.timeline,
        userName: l.user.name,
        location: l.location,
        createdAt: l.createdAt
      }))
    });

  } catch (error) {
    console.error('Stats error:', error);
    return NextResponse.json({ error: 'Failed to fetch stats' }, { status: 500 });
  }
}
