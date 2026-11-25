import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { notifyCityProvidersForNewProject, formatCityLocation } from '@/lib/notifications';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function GET(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['CONSUMER'] });
    if (!authResult.ok) return authResult.response;

    const { searchParams } = new URL(request.url);
    // Consumers can only list their own projects
    const userId = authResult.auth?.id ?? searchParams.get('userId');
    if (!userId) {
      return NextResponse.json({ error: 'userId is required' }, { status: 400 });
    }

    const projects = await prisma.project.findMany({
      where: { userId },
      include: {
        // Never return the full user row (password, phone, fcmToken)
        user: { select: { id: true, name: true } },
        tasks: true,
      },
      orderBy: { createdAt: 'desc' }
    });
    return NextResponse.json({ projects });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch projects' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['CONSUMER'] });
    if (!authResult.ok) return authResult.response;

    const body = await request.json();
    // Validate request body
    const { userId, title, type, location, plotSize, budget, timeline, currentStage } = body;

    // A consumer can only create projects for themselves
    const notSelf = denyUnlessSelf(authResult.auth, userId);
    if (notSelf) return notSelf;

    // Normalize location to ensure city is clearly preserved (e.g. Madurai, Tamil Nadu)
    const formattedLocation = formatCityLocation(location);

    const project = await prisma.project.create({
      data: {
        userId,
        title,
        type,
        location: formattedLocation,
        plotSize: parseFloat(plotSize),
        budget: parseFloat(budget),
        timeline,
        currentStage
      }
    });

    // Notify all verified service providers in the city with matching categories
    notifyCityProvidersForNewProject({
      id: project.id,
      title: project.title,
      type: project.type,
      location: project.location,
      budget: project.budget,
    }).catch(err => console.error('Error in background city provider notification:', err));
    
    return NextResponse.json(project, { status: 201 });
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to create project' }, { status: 500 });
  }
}

