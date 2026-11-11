import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendFCMNotification } from '@/lib/fcm';

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
    const { id } = await context.params;
    
    const user = await prisma.user.findUnique({
      where: { id },
      select: { fcmToken: true, name: true, email: true },
    });

    await prisma.user.delete({
      where: { id },
    });

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
