import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { AuthIdentity, forbidden } from '@/lib/auth';

/** Stages after which a project no longer accepts new quotes. */
export const CLOSED_PROJECT_STAGES = [
  'tracking',
  'completed',
  'finished',
  'finished pending approval',
  'cancelled',
  'canceled',
  'on hold',
];

export function isProjectOpenForQuotes(currentStage: string | null | undefined): boolean {
  return !CLOSED_PROJECT_STAGES.includes((currentStage || '').toLowerCase().trim());
}

/**
 * Only the consumer who owns the project, or the provider whose quote was accepted,
 * may modify a project (stage, tasks, updates, delete).
 * Returns a 404/403 response to send back, or null when access is allowed.
 * Legacy token-less requests (auth === null) are allowed while AUTH_ENFORCE is off.
 */
export async function denyUnlessProjectParticipant(
  projectId: string,
  auth: AuthIdentity | null
): Promise<NextResponse | null> {
  if (!auth) return null;

  const project = await prisma.project.findUnique({
    where: { id: projectId },
    select: { userId: true },
  });
  if (!project) {
    return NextResponse.json({ error: 'Project not found' }, { status: 404 });
  }

  if (auth.role === 'CONSUMER' && project.userId === auth.id) return null;

  if (auth.role === 'PROVIDER') {
    const accepted = await prisma.quote.findFirst({
      where: { projectId, providerId: auth.id, isAccepted: true },
      select: { id: true },
    });
    if (accepted) return null;
  }

  return forbidden('Only the project owner or the assigned partner can change this project.');
}
