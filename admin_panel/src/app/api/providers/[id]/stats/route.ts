import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

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

    // Projects = Projects taken by this provider (where quote is accepted)
    const projectsCount = await prisma.quote.count({
      where: { 
        providerId: id,
        isAccepted: true
      }
    });

    // Helper to match locations case-insensitively
    const locationsMatch = (projLoc: string, provAddr: string | null): boolean => {
      if (!provAddr) return true; // If provider hasn't set location, show all leads in category
      const cleanedProj = projLoc.toLowerCase().trim();
      const cleanedProv = provAddr.toLowerCase().trim();

      if (cleanedProj === '' || cleanedProv === '') return true;

      // 1. Direct contains check
      if (cleanedProv.includes(cleanedProj) || cleanedProj.includes(cleanedProv)) return true;

      // 2. Token word match (ignoring common address descriptors)
      const stopWords = new Set(['and', 'the', 'for', 'our', 'new', 'old', 'street', 'road', 'avenue', 'lane', 'drive', 'court', 'plaza', 'way', 'near', 'opp', 'opposite']);
      const projWords = cleanedProj.split(/[\s,.-]+/).filter(w => w.length > 2 && !stopWords.has(w));
      const provWords = cleanedProv.split(/[\s,.-]+/).filter(w => w.length > 2 && !stopWords.has(w));

      for (const word of projWords) {
        if (provWords.includes(word)) return true;
      }

      return false;
    };

    // Fetch all active projects that don't have any accepted quotes
    const allProjects = await prisma.project.findMany({
      where: {
        quotes: {
          none: {
            isAccepted: true
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { name: true } }
      }
    });

    // Filter projects where project type/services matches provider.category
    const categoryProjects = allProjects.filter(project => {
      if (!project.type || !provider.category) return false;
      const projectServices = project.type.split(',').map(s => s.trim().toLowerCase());
      const providerServices = provider.category.split(',').map(s => s.trim().toLowerCase());
      return projectServices.some(service => providerServices.includes(service));
    });

    // Filter projects based on locations compatibility
    const matchedProjects = categoryProjects.filter(project => 
      locationsMatch(project.location, provider.address)
    );

    const activeLeadsCount = matchedProjects.length;
    const recentLeads = matchedProjects.slice(0, 5);

    // Fetch active jobs (where provider's quote is accepted)
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

    const activeJobs = acceptedQuotes.map(q => ({
      id: q.project.id,
      title: q.project.title,
      userName: q.project.user.name,
      location: q.project.location,
      budget: q.project.budget,
      timeline: q.project.timeline,
      currentStage: q.project.currentStage,
      quoteId: q.id
    }));

    return NextResponse.json({
      activeLeads: activeLeadsCount,
      projects: projectsCount,
      activeJobs,
      recentLeads: recentLeads.map(l => ({
        id: l.id,
        title: l.title,
        userName: l.user.name,
        location: l.location,
        createdAt: l.createdAt
      })),
      allLeads: matchedProjects.map(l => ({
        id: l.id,
        title: l.title,
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
