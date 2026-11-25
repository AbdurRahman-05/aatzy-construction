import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function GET(request: Request) {
  try {
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;

    const { searchParams } = new URL(request.url);
    const recipientId = searchParams.get('recipientId') || searchParams.get('userId');
    const role = searchParams.get('role');
    const unreadOnly = searchParams.get('unreadOnly') === 'true';

    if (!recipientId) {
      return NextResponse.json({ error: 'recipientId or userId is required' }, { status: 400 });
    }

    // Users can only read their own notifications
    const notSelf = denyUnlessSelf(authResult.auth, recipientId);
    if (notSelf) return notSelf;

    const where: any = {
      recipientId,
    };

    if (role) {
      where.role = role.toUpperCase();
    }

    if (unreadOnly) {
      where.isRead = false;
    }

    const notifications = await prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    return NextResponse.json(notifications);
  } catch (error) {
    console.error('Fetch notifications error:', error);
    return NextResponse.json({ error: 'Failed to fetch notifications' }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;
    const auth = authResult.auth;

    const body = await request.json();
    const { id, recipientId, all } = body;

    if (all && recipientId) {
      const notSelf = denyUnlessSelf(auth, recipientId);
      if (notSelf) return notSelf;

      await prisma.notification.updateMany({
        where: { recipientId, isRead: false },
        data: { isRead: true },
      });
      return NextResponse.json({ message: 'All notifications marked as read' });
    }

    if (id) {
      // Scope to the caller's own notifications when authenticated
      const result = await prisma.notification.updateMany({
        where: auth ? { id, recipientId: auth.id } : { id },
        data: { isRead: true },
      });
      if (result.count === 0) {
        return NextResponse.json({ error: 'Notification not found' }, { status: 404 });
      }
      return NextResponse.json({ message: 'Notification marked as read' });
    }

    return NextResponse.json({ error: 'Provide either id or recipientId with all: true' }, { status: 400 });
  } catch (error) {
    console.error('Update notification error:', error);
    return NextResponse.json({ error: 'Failed to update notification' }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;
    const auth = authResult.auth;

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const recipientId = searchParams.get('recipientId');
    const all = searchParams.get('all') === 'true';

    if (all && recipientId) {
      const notSelf = denyUnlessSelf(auth, recipientId);
      if (notSelf) return notSelf;

      await prisma.notification.deleteMany({
        where: { recipientId },
      });
      return NextResponse.json({ message: 'All notifications deleted' });
    }

    if (!id) {
      return NextResponse.json({ error: 'Notification id is required' }, { status: 400 });
    }

    const removed = await prisma.notification.deleteMany({
      where: auth ? { id, recipientId: auth.id } : { id },
    });
    if (removed.count === 0) {
      return NextResponse.json({ error: 'Notification not found' }, { status: 404 });
    }

    return NextResponse.json({ message: 'Notification deleted' });
  } catch (error) {
    console.error('Delete notification error:', error);
    return NextResponse.json({ error: 'Failed to delete notification' }, { status: 500 });
  }
}
