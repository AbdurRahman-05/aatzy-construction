import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function POST(request: Request) {
  try {
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;

    const { userId, role, oldPassword, newPassword } = await request.json();

    if (!userId || !role || !oldPassword || !newPassword) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Only change your own password
    const notSelf = denyUnlessSelf(authResult.auth, userId);
    if (notSelf) return notSelf;

    if (role === 'PROVIDER') {
      const provider = await prisma.provider.findUnique({
        where: { id: userId },
      });

      if (!provider) {
        return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
      }

      if (provider.password !== oldPassword) {
        return NextResponse.json({ error: 'Incorrect current password' }, { status: 403 });
      }

      await prisma.provider.update({
        where: { id: userId },
        data: { password: newPassword },
      });
    } else {
      const user = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) {
        return NextResponse.json({ error: 'User not found' }, { status: 404 });
      }

      if (user.password !== oldPassword) {
        return NextResponse.json({ error: 'Incorrect current password' }, { status: 403 });
      }

      await prisma.user.update({
        where: { id: userId },
        data: { password: newPassword },
      });
    }

    return NextResponse.json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
