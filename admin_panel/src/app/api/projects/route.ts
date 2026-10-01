import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { notifyCityProvidersForNewProject, formatCityLocation } from '@/lib/notifications';

export async function GET() {
  try {
    const projects = await prisma.project.findMany({
      include: {
        user: true,
        tasks: true,
      },
      orderBy: { createdAt: 'desc' }
    });
    return NextResponse.json(projects);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch projects' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    // Validate request body
    const { userId, title, type, location, plotSize, budget, timeline, currentStage } = body;
    
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

