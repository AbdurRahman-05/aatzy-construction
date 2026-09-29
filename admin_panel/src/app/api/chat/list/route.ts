import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    const role = searchParams.get('role'); // 'PROVIDER' or 'CONSUMER'

    if (!userId) {
      return NextResponse.json({ error: 'Missing userId' }, { status: 400 });
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
    const normalizedRole = role ? role.toUpperCase() : '';

    for (const conv of conversations) {
      let partnerName = '';
      let partnerImage = '';

      if (normalizedRole === 'CONSUMER') {
        // Consumer partner is usually a Provider
        const provider = await prisma.provider.findUnique({
          where: { id: conv.partnerId },
          select: { businessName: true, ownerName: true, profileImage: true },
        });
        if (provider) {
          partnerName = provider.businessName || provider.ownerName || 'Provider';
          partnerImage = provider.profileImage || '';
        } else {
          const user = await prisma.user.findUnique({
            where: { id: conv.partnerId },
            select: { name: true, profileImage: true },
          });
          if (user) {
            partnerName = user.name;
            partnerImage = user.profileImage || '';
          }
        }
      } else if (normalizedRole === 'PROVIDER') {
        // Provider partner is usually a Consumer (User)
        const user = await prisma.user.findUnique({
          where: { id: conv.partnerId },
          select: { name: true, profileImage: true },
        });
        if (user) {
          partnerName = user.name;
          partnerImage = user.profileImage || '';
        } else {
          const provider = await prisma.provider.findUnique({
            where: { id: conv.partnerId },
            select: { businessName: true, ownerName: true, profileImage: true },
          });
          if (provider) {
            partnerName = provider.businessName || provider.ownerName || 'Provider';
            partnerImage = provider.profileImage || '';
          }
        }
      } else {
        // Unknown or unspecified role: search provider then user
        const provider = await prisma.provider.findUnique({
          where: { id: conv.partnerId },
          select: { businessName: true, ownerName: true, profileImage: true },
        });
        if (provider) {
          partnerName = provider.businessName || provider.ownerName || 'Provider';
          partnerImage = provider.profileImage || '';
        } else {
          const user = await prisma.user.findUnique({
            where: { id: conv.partnerId },
            select: { name: true, profileImage: true },
          });
          if (user) {
            partnerName = user.name;
            partnerImage = user.profileImage || '';
          }
        }
      }

      if (!partnerName || partnerName.trim().length === 0) {
        partnerName = 'Contact';
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
