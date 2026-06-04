import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    const role = searchParams.get('role'); // 'PROVIDER' or 'CONSUMER'

    if (!userId || !role) {
      return NextResponse.json({ error: 'Missing userId or role' }, { status: 400 });
    }

    // Get all messages involving this user
    const messages = await prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId },
          { receiverId: userId },
        ],
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Group messages by partner ID
    const conversationsMap = new Map<string, any>();

    for (const msg of messages) {
      const partnerId = msg.senderId === userId ? msg.receiverId : msg.senderId;
      if (!conversationsMap.has(partnerId)) {
        conversationsMap.set(partnerId, {
          lastMessage: msg.text,
          createdAt: msg.createdAt,
          partnerId: partnerId,
        });
      }
    }

    const conversations = Array.from(conversationsMap.values());

    // Populate partner details (e.g. name, profileImage)
    const result = [];
    for (const conv of conversations) {
      let partnerName = 'Unknown User';
      let partnerImage = '';

      if (role === 'CONSUMER') {
        // Partner is a PROVIDER
        const provider = await prisma.provider.findUnique({
          where: { id: conv.partnerId },
          select: { businessName: true, profileImage: true },
        });
        if (provider) {
          partnerName = provider.businessName;
          partnerImage = provider.profileImage || '';
        }
      } else {
        // Partner is a CONSUMER (User)
        const user = await prisma.user.findUnique({
          where: { id: conv.partnerId },
          select: { name: true },
        });
        if (user) {
          partnerName = user.name;
        }
      }

      result.push({
        ...conv,
        partnerName,
        partnerImage,
      });
    }

    return NextResponse.json({ conversations: result });
  } catch (error) {
    console.error('Fetch chat list error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
