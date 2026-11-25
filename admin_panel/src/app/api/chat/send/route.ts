import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { notifyChatMessage } from '@/lib/notifications';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function POST(request: Request) {
  try {
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;

    const { senderId, receiverId, text } = await request.json();

    if (!senderId || !receiverId || !text) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Nobody can send messages as someone else
    const notSelf = denyUnlessSelf(authResult.auth, senderId);
    if (notSelf) return notSelf;

    const message = await prisma.message.create({
      data: {
        senderId,
        receiverId,
        text,
      },
    });

    // Fire-and-forget: notify the receiver about the new message
    notifyChatMessage({ senderId, receiverId, text }).catch((err) =>
      console.error('Chat notification error:', err)
    );

    return NextResponse.json({ message });
  } catch (error) {
    console.error('Send message error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
