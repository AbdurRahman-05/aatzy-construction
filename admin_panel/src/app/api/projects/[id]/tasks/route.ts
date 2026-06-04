import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: projectId } = await context.params;
    const body = await request.json();

    // 1. Bulk creation (template tasks)
    if (body.tasks && Array.isArray(body.tasks)) {
      const createdTasks = await prisma.$transaction(
        body.tasks.map((task: any) =>
          prisma.projectTask.create({
            data: {
              projectId,
              stage: task.stage,
              title: task.title,
              duration: parseInt(task.duration) || 1,
              status: task.status || 'Todo',
            },
          })
        )
      );
      return NextResponse.json(createdTasks, { status: 201 });
    }

    // 2. Single task creation
    const { stage, title, duration, quotedCost } = body;
    if (!stage || !title) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const newTask = await prisma.projectTask.create({
      data: {
        projectId,
        stage,
        title,
        duration: parseInt(duration) || 1,
        status: 'Todo',
        quotedCost: quotedCost !== undefined ? parseFloat(quotedCost) : 0.0,
      },
    });

    return NextResponse.json(newTask, { status: 201 });
  } catch (error) {
    console.error('Create project task error:', error);
    return NextResponse.json({ error: 'Failed to create task(s)' }, { status: 500 });
  }
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const body = await request.json();
    const {
      taskId,
      status,
      title,
      duration,
      photoUrl,
      materialName,
      materialQuantity,
      materialUnitCost,
      taskCost,
      quotedCost
    } = body;

    if (!taskId) {
      return NextResponse.json({ error: 'Missing taskId' }, { status: 400 });
    }

    const updatedTask = await prisma.projectTask.update({
      where: { id: taskId },
      data: {
        status,
        title,
        duration: duration !== undefined ? parseInt(duration) : undefined,
        photoUrl: photoUrl !== undefined ? photoUrl : undefined,
        materialName: materialName !== undefined ? materialName : undefined,
        materialQuantity: materialQuantity !== undefined ? (materialQuantity === null ? null : parseInt(materialQuantity)) : undefined,
        materialUnitCost: materialUnitCost !== undefined ? (materialUnitCost === null ? null : parseFloat(materialUnitCost)) : undefined,
        taskCost: taskCost !== undefined ? (taskCost === null ? 0.0 : parseFloat(taskCost)) : undefined,
        quotedCost: quotedCost !== undefined ? (quotedCost === null ? 0.0 : parseFloat(quotedCost)) : undefined,
      },
    });

    return NextResponse.json(updatedTask);
  } catch (error) {
    console.error('Update project task error:', error);
    return NextResponse.json({ error: 'Failed to update task' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { searchParams } = new URL(request.url);
    const taskId = searchParams.get('taskId');

    if (!taskId) {
      return NextResponse.json({ error: 'Missing taskId' }, { status: 400 });
    }

    await prisma.projectTask.delete({
      where: { id: taskId },
    });

    return NextResponse.json({ message: 'Task deleted successfully' });
  } catch (error) {
    console.error('Delete project task error:', error);
    return NextResponse.json({ error: 'Failed to delete task' }, { status: 500 });
  }
}
