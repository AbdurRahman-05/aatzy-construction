import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const target = searchParams.get('target'); // 'CLIENT' | 'PROVIDER'
    const activeOnly = searchParams.get('activeOnly') === 'true';

    const where: any = {};
    if (activeOnly) {
      where.isActive = true;
    }

    if (target) {
      const normalized = target.toUpperCase();
      // An ad matches if it's targeted to ALL/BOTH or specifically to this side
      where.targetSide = { in: ['ALL', 'BOTH', normalized] };
    }

    const ads = await (prisma as any).ad.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    return NextResponse.json({ ads });
  } catch (error) {
    console.error('Fetch ads error:', error);
    return NextResponse.json({ error: 'Failed to fetch ads' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      title,
      desc,
      badge,
      icon,
      gradient,
      imageUrl,
      targetSide,
      actionUrl,
      actionText,
      isActive,
    } = body;

    if (!title) {
      return NextResponse.json({ error: 'Ad title is required' }, { status: 400 });
    }

    const ad = await (prisma as any).ad.create({
      data: {
        title,
        desc: desc || '',
        badge: badge || 'SPECIAL',
        icon: icon || 'star',
        gradient: gradient || '0xFF064354,0xFF0B7C8E',
        imageUrl: imageUrl || null,
        targetSide: targetSide || 'ALL',
        actionUrl: actionUrl || null,
        actionText: actionText || 'Explore Now',
        isActive: isActive !== undefined ? Boolean(isActive) : true,
      },
    });

    return NextResponse.json({ ad }, { status: 201 });
  } catch (error) {
    console.error('Create ad error:', error);
    return NextResponse.json({ error: 'Failed to create ad' }, { status: 500 });
  }
}
