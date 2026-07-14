import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET() {
  try {
    const ads = await (prisma as any).ad.findMany({
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
    const { title, desc, badge, icon, gradient } = await request.json();

    if (!title || !desc || !badge) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const ad = await (prisma as any).ad.create({
      data: {
        title,
        desc,
        badge,
        icon: icon || undefined,
        gradient: gradient || undefined,
      },
    });

    return NextResponse.json({ ad }, { status: 201 });
  } catch (error) {
    console.error('Create ad error:', error);
    return NextResponse.json({ error: 'Failed to create ad' }, { status: 500 });
  }
}
