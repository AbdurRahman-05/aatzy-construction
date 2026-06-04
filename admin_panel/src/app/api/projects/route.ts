import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

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
    
    const project = await prisma.project.create({
      data: {
        userId,
        title,
        type,
        location,
        plotSize: parseFloat(plotSize),
        budget: parseFloat(budget),
        timeline,
        currentStage
      }
    });
    
    return NextResponse.json(project, { status: 201 });
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to create project' }, { status: 500 });
  }
}
