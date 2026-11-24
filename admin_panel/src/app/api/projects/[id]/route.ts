import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    let project: any = null;
    try {
      project = await prisma.project.findUnique({
        where: { id },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
            }
          },
          quotes: {
            include: {
              provider: {
                select: {
                  id: true,
                  businessName: true,
                  ownerName: true,
                  phone: true,
                  email: true,
                  profileImage: true,
                }
              }
            }
          },
          updates: {
            orderBy: {
              createdAt: 'desc'
            }
          },
          tasks: {
            orderBy: {
              createdAt: 'asc'
            }
          }
        }
      });
    } catch (queryErr) {
      console.warn('Full project include failed, attempting fallback query without updates:', queryErr);
      project = await prisma.project.findUnique({
        where: { id },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
            }
          },
          quotes: {
            include: {
              provider: {
                select: {
                  id: true,
                  businessName: true,
                  ownerName: true,
                  phone: true,
                  email: true,
                  profileImage: true,
                }
              }
            }
          },
          tasks: {
            orderBy: {
              createdAt: 'asc'
            }
          }
        }
      });
      if (project) {
        project.updates = [];
      }
    }

    if (!project) {
      return NextResponse.json({ error: 'Project not found' }, { status: 404 });
    }

    return NextResponse.json(project);
  } catch (error) {
    console.error('Fetch project detail error:', error);
    return NextResponse.json({ error: 'Failed to fetch project' }, { status: 500 });
  }
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const { title, type, location, plotSize, budget, timeline, currentStage } = body;

    const updatedProject = await prisma.project.update({
      where: { id },
      data: {
        title,
        type,
        location,
        plotSize: plotSize !== undefined ? parseFloat(plotSize) : undefined,
        budget: budget !== undefined ? parseFloat(budget) : undefined,
        timeline,
        currentStage,
      },
    });

    if (currentStage === 'On Hold' && updatedProject.userId) {
      try {
        await prisma.notification.create({
          data: {
            recipientId: updatedProject.userId,
            role: 'CONSUMER',
            title: 'Project Put On Hold',
            body: `Your project "${updatedProject.title}" has been put on hold by the service provider.`,
            type: 'STAGE_COMPLETED',
            entityId: id,
            route: `/project-detail/${id}`,
          },
        });
        await prisma.projectUpdate.create({
          data: {
            projectId: id,
            title: 'Project Status: On Hold',
            status: 'On Hold',
            notes: 'Service provider temporarily paused this project.',
          },
        });
      } catch (e) {
        console.error('Failed to log on-hold event:', e);
      }
    } else if (currentStage === 'Tracking' && updatedProject.userId) {
      try {
        await prisma.notification.create({
          data: {
            recipientId: updatedProject.userId,
            role: 'CONSUMER',
            title: 'Project Resumed',
            body: `Work has resumed on your project "${updatedProject.title}".`,
            type: 'STAGE_COMPLETED',
            entityId: id,
            route: `/project-detail/${id}`,
          },
        });
        await prisma.projectUpdate.create({
          data: {
            projectId: id,
            title: 'Project Status: Resumed',
            status: 'Tracking',
            notes: 'Service provider resumed work on this project.',
          },
        });
      } catch (e) {
        console.error('Failed to log resume event:', e);
      }
    }

    return NextResponse.json(updatedProject);
  } catch (error) {
    console.error('Update project error:', error);
    return NextResponse.json({ error: 'Failed to update project' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    // Delete related records in quotes, tasks, and updates first, then delete project
    await prisma.$transaction([
      prisma.quote.deleteMany({ where: { projectId: id } }),
      prisma.projectUpdate.deleteMany({ where: { projectId: id } }),
      prisma.projectTask.deleteMany({ where: { projectId: id } }),
      prisma.project.delete({ where: { id } }),
    ]);

    return NextResponse.json({ success: true, message: 'Project deleted successfully' });
  } catch (error) {
    console.error('Delete project error:', error);
    return NextResponse.json({ error: 'Failed to delete project' }, { status: 500 });
  }
}
