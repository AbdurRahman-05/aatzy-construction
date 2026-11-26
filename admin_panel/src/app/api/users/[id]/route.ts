import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendFCMNotification } from '@/lib/fcm';
import { requireAdmin, requireAuth, denyUnlessSelf } from '@/lib/auth';
import { createNotification } from '@/lib/notifications';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        profileImage: true,
        role: true,
        isApproved: true,
        createdAt: true,
      },
    });

    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    return NextResponse.json(user);
  } catch (error) {
    console.error('Fetch user error:', error);
    return NextResponse.json({ error: 'Failed to fetch user' }, { status: 500 });
  }
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request, { roles: ['CONSUMER'] });
    if (!authResult.ok) return authResult.response;
    const { id: guardUserId } = await context.params;
    const notSelf = denyUnlessSelf(authResult.auth, guardUserId);
    if (notSelf) return notSelf;

    const { id } = await context.params;
    const body = await request.json();
    const { name, phone, profileImage } = body;

    const data: any = {};
    if (name !== undefined) data.name = name;
    if (phone !== undefined) data.phone = phone;
    if (profileImage !== undefined) data.profileImage = profileImage;

    const updated = await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        profileImage: true,
        role: true,
      },
    });

    return NextResponse.json(updated);
  } catch (error) {
    console.error('Update user error:', error);
    return NextResponse.json({ error: 'Failed to update user' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    
    const user = await prisma.user.findUnique({
      where: { id },
      select: { fcmToken: true, name: true, email: true },
    });
    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Projects (and their quotes / updates / tasks) are not cascade-deleted by the database,
    // so a customer with any project could never be deleted. Remove them explicitly.
    const activePartners = await prisma.quote.findMany({
      where: { isAccepted: true, project: { userId: id } },
      select: { providerId: true, projectId: true, project: { select: { title: true, currentStage: true } } },
    });

    await prisma.$transaction([
      prisma.quote.deleteMany({ where: { project: { userId: id } } }),
      prisma.projectUpdate.deleteMany({ where: { project: { userId: id } } }),
      prisma.projectTask.deleteMany({ where: { project: { userId: id } } }),
      prisma.project.deleteMany({ where: { userId: id } }),
      prisma.user.delete({ where: { id } }),
    ]);

    // Tell partners who were working for this customer (best effort)
    const FINISHED = ['completed', 'finished', 'cancelled'];
    for (const q of activePartners) {
      if (FINISHED.includes((q.project.currentStage || '').toLowerCase().trim())) continue;
      createNotification({
        recipientId: q.providerId,
        role: 'PROVIDER',
        title: '❌ Project Cancelled',
        body: `The client account for "${q.project.title}" was removed, so this project has been closed.`,
        type: 'PROJECT_CANCELLED',
        entityId: q.projectId,
        route: '/provider-home',
      }).catch(err => console.error('Client removal notification error:', err));
    }

    if (user?.fcmToken) {
      sendFCMNotification({
        token: user.fcmToken,
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

    return NextResponse.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    return NextResponse.json({ error: 'Failed to delete user' }, { status: 500 });
  }
}
