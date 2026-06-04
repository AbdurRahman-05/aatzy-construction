import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const { title, status, notes } = body;

    if (!title || !status) {
      return NextResponse.json({ error: 'Title and status are required' }, { status: 400 });
    }

    const newUpdate = await prisma.projectUpdate.create({
      data: {
        projectId: id,
        title,
        status,
        notes: notes || '',
      }
    });

    return NextResponse.json(newUpdate);
  } catch (error) {
    console.error('Create project update error:', error);
    return NextResponse.json({ error: 'Failed to create update' }, { status: 500 });
  }
}
