import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { id, role, fcmToken, action } = body;
    const token = fcmToken || body.token || body.deviceToken;
    const normalizedRole = (role || '').toUpperCase();

    // 1. Handle Logout / Clear Token Request
    if (action === 'clear' || action === 'logout' || !token) {
      if (id) {
        if (normalizedRole === 'PROVIDER') {
          await prisma.provider.updateMany({
            where: { id },
            data: { fcmToken: null },
          });
        } else {
          await prisma.user.updateMany({
            where: { id },
            data: { fcmToken: null },
          });
        }
      }

      // If a device token was provided, clear ANY accounts (both Provider and User) associated with it
      if (token && typeof token === 'string' && token.trim().length > 0) {
        await prisma.user.updateMany({
          where: { fcmToken: token },
          data: { fcmToken: null },
        });
        await prisma.provider.updateMany({
          where: { fcmToken: token },
          data: { fcmToken: null },
        });
      }

      console.log(`[FCM] Token cleared for ${normalizedRole || 'USER'} ${id || ''} (token: ${token ? 'present' : 'none'})`);
      return NextResponse.json({
        success: true,
        message: 'FCM Token cleared successfully',
      });
    }

    // 2. Handle Login / Token Registration
    if (!id) {
      return NextResponse.json({ error: 'id is required' }, { status: 400 });
    }

    // Detach this device token from any other accounts on this physical phone
    // so previous accounts on the same device do not receive stray push notifications.
    await prisma.user.updateMany({
      where: {
        fcmToken: token,
        ...(normalizedRole !== 'PROVIDER' ? { NOT: { id } } : {}),
      },
      data: { fcmToken: null },
    });
    await prisma.provider.updateMany({
      where: {
        fcmToken: token,
        ...(normalizedRole === 'PROVIDER' ? { NOT: { id } } : {}),
      },
      data: { fcmToken: null },
    });

    // Assign device token to current active user/provider
    if (normalizedRole === 'PROVIDER') {
      await prisma.provider.updateMany({
        where: { id },
        data: { fcmToken: token },
      });
    } else {
      await prisma.user.updateMany({
        where: { id },
        data: { fcmToken: token },
      });
    }

    console.log(`[FCM] Token saved for ${normalizedRole} ${id}`);
    return NextResponse.json({
      success: true,
      message: 'FCM Token saved successfully',
    });
  } catch (error) {
    console.error('Failed to handle FCM Token request:', error);
    return NextResponse.json({ error: 'Failed to process FCM token' }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    let id: string | undefined;
    let role: string | undefined;
    let token: string | undefined;

    try {
      const body = await request.json();
      id = body.id;
      role = body.role;
      token = body.fcmToken || body.token || body.deviceToken;
    } catch (_) {
      const url = new URL(request.url);
      id = url.searchParams.get('id') || undefined;
      role = url.searchParams.get('role') || undefined;
      token = url.searchParams.get('fcmToken') || url.searchParams.get('token') || undefined;
    }

    const normalizedRole = (role || '').toUpperCase();

    if (id) {
      if (normalizedRole === 'PROVIDER') {
        await prisma.provider.updateMany({
          where: { id },
          data: { fcmToken: null },
        });
      } else {
        await prisma.user.updateMany({
          where: { id },
          data: { fcmToken: null },
        });
      }
    }

    if (token) {
      await prisma.user.updateMany({
        where: { fcmToken: token },
        data: { fcmToken: null },
      });
      await prisma.provider.updateMany({
        where: { fcmToken: token },
        data: { fcmToken: null },
      });
    }

    return NextResponse.json({
      success: true,
      message: 'FCM Token removed successfully',
    });
  } catch (error) {
    console.error('Failed to delete FCM Token:', error);
    return NextResponse.json({ error: 'Failed to delete FCM token' }, { status: 500 });
  }
}

