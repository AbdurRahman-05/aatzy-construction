import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    const partnerId = searchParams.get('partnerId');

    if (!userId || !partnerId) {
      return NextResponse.json({ error: 'Missing userId or partnerId' }, { status: 400 });
    }

    const messages = await prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId, receiverId: partnerId },
          { senderId: partnerId, receiverId: userId },
        ],
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    return NextResponse.json({ messages });
  } catch (error) {
    console.error('Fetch chat messages error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const messageId = searchParams.get('messageId');
    const userId = searchParams.get('userId');
    const partnerId = searchParams.get('partnerId');

    // Case 1: Unsend / delete a single message
    if (messageId) {
      const existing = await prisma.message.findUnique({
        where: { id: messageId },
      });

      if (!existing) {
        return NextResponse.json({ success: true, message: 'Message already removed' });
      }

      // If userId is provided, ensure only sender (or receiver) can delete
      if (userId && existing.senderId !== userId && existing.receiverId !== userId) {
        return NextResponse.json({ error: 'Unauthorized to delete this message' }, { status: 403 });
      }

      await prisma.message.delete({
        where: { id: messageId },
      });

      return NextResponse.json({ success: true, message: 'Message un-sent successfully' });
    }

    // Case 2: Delete entire conversation / delete person
    if (userId && partnerId) {
      await prisma.message.deleteMany({
        where: {
          OR: [
            { senderId: userId, receiverId: partnerId },
            { senderId: partnerId, receiverId: userId },
          ],
        },
      });

      return NextResponse.json({ success: true, message: 'Conversation deleted successfully' });
    }

    return NextResponse.json(
      { error: 'Missing parameters. Provide messageId or (userId and partnerId)' },
      { status: 400 }
    );
  } catch (error) {
    console.error('Delete chat error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
