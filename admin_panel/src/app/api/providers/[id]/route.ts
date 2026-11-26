import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendFCMNotification } from '@/lib/fcm';
import { requireAdmin } from '@/lib/auth';
import { createNotification } from '@/lib/notifications';

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    
    const provider = await prisma.provider.findUnique({
      where: { id },
      select: { fcmToken: true, businessName: true, email: true },
    });
    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    // Quotes are not cascade-deleted by the database (that is what made delete fail).
    // Projects this partner was actively working on go back to "open for quotes" so the client can hire someone else.
    const acceptedQuotes = await prisma.quote.findMany({
      where: { providerId: id, isAccepted: true },
      select: { projectId: true, project: { select: { userId: true, title: true, currentStage: true } } },
    });
    const FINISHED = ['completed', 'finished', 'finished pending approval', 'cancelled'];
    const projectsToReopen = acceptedQuotes.filter(
      q => !FINISHED.includes((q.project.currentStage || '').toLowerCase().trim())
    );

    await prisma.$transaction([
      ...projectsToReopen.map(q =>
        prisma.project.update({
          where: { id: q.projectId },
          data: { currentStage: 'Planning & Approvals' },
        })
      ),
      ...projectsToReopen.map(q =>
        prisma.projectUpdate.create({
          data: {
            projectId: q.projectId,
            title: 'Partner removed',
            status: 'Planning & Approvals',
            notes: `${provider.businessName} is no longer on Connectzy. Your project is open for new quotes.`,
          },
        })
      ),
      prisma.quote.deleteMany({ where: { providerId: id } }),
      prisma.provider.delete({ where: { id } }),
    ]);

    // Tell affected clients (best effort)
    for (const q of projectsToReopen) {
      createNotification({
        recipientId: q.project.userId,
        role: 'CONSUMER',
        title: 'Your partner was removed',
        body: `${provider.businessName} is no longer available for "${q.project.title}". Your project is open for new quotes.`,
        type: 'STAGE_COMPLETED',
        entityId: q.projectId,
        route: `/project-detail/${q.projectId}`,
      }).catch(err => console.error('Partner removal notification error:', err));
    }

    if (provider?.fcmToken) {
      sendFCMNotification({
        token: provider.fcmToken,
        title: 'Account Deleted',
        body: 'Your account has been deleted by an administrator.',
        route: '/login',
        channelId: 'buildzy_general_v2',
        recipientId: id,
        action: 'FORCE_LOGOUT',
      }).catch(err => {
        console.error('FCM delete notification error:', err);
      });
    }

    return NextResponse.json({ message: 'Provider deleted successfully' });
  } catch (error) {
    console.error('Delete provider error:', error);
    return NextResponse.json({ error: 'Failed to delete provider' }, { status: 500 });
  }
}
