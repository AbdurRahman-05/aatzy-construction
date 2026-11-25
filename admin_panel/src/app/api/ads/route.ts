import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAdmin } from '@/lib/auth';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const target = searchParams.get('target'); // 'CLIENT' | 'PROVIDER'
    const activeOnly = searchParams.get('activeOnly') === 'true';
    const placement = searchParams.get('placement'); // 'POPUP' | 'HOME'

    const where: any = {};
    if (activeOnly) {
      where.isActive = true;
    }

    if (placement) {
      const normalizedPlacement = placement.toUpperCase();
      // An ad shows in a slot if it's placed there specifically or in BOTH slots
      where.placement = { in: ['BOTH', normalizedPlacement] };
    }

    if (target) {
      const normalized = target.toUpperCase();
      // An ad matches if it's targeted to ALL/BOTH or specifically to this side
      where.targetSide = { in: ['ALL', 'BOTH', 'BOTH_SIDES', normalized] };
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
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const body = await request.json();
    const {
      title,
      desc,
      badge,
      icon,
      gradient,
      imageUrl,
      mediaType,
      videoUrl,
      targetSide,
      placement,
      actionUrl,
      actionText,
      isActive,
    } = body;

    const allowedPlacements = ['POPUP', 'HOME', 'BOTH'];
    const normalizedPlacement = String(placement || 'BOTH').toUpperCase();
    if (!allowedPlacements.includes(normalizedPlacement)) {
      return NextResponse.json({ error: 'placement must be POPUP, HOME or BOTH' }, { status: 400 });
    }

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
        mediaType: mediaType || (videoUrl ? 'video' : 'image'),
        videoUrl: videoUrl || null,
        targetSide: targetSide || 'ALL',
        placement: normalizedPlacement,
        actionUrl: actionUrl || null,
        actionText: actionText || 'Explore Now',
        isActive: isActive !== undefined ? Boolean(isActive) : true,
      },
    });

    return NextResponse.json({ ad }, { status: 201 });
  } catch (error: any) {
    console.error('Create ad error:', error);
    return NextResponse.json({ error: 'Failed to create ad', details: error?.message || String(error) }, { status: 500 });
  }
}
