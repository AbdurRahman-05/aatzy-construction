import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth } from '@/lib/auth';
import { denyUnlessProjectParticipant } from '@/lib/projectAccess';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;
    const { id: guardProjectId } = await context.params;
    const denied = await denyUnlessProjectParticipant(guardProjectId, authResult.auth);
    if (denied) return denied;

    const { id } = await context.params;
    const body = await request.json();
    const { title, status, notes, photoUrl, imageUrl } = body;

    if (!title || !status) {
      return NextResponse.json({ error: 'Title and status are required' }, { status: 400 });
    }

    const finalPhoto = photoUrl || imageUrl || null;
    const notesToSave = finalPhoto && !notes?.includes('[PHOTO:')
      ? `${notes || ''}\n[PHOTO:${finalPhoto}]`
      : (notes || '');

    const newUpdate = await prisma.projectUpdate.create({
      data: {
        projectId: id,
        title,
        status,
        notes: notesToSave,
      }
    });

    return NextResponse.json(newUpdate);
  } catch (error) {
    console.error('Create project update error:', error);
    return NextResponse.json({ error: 'Failed to create update' }, { status: 500 });
  }
}
