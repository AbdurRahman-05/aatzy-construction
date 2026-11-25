import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET() {
  try {
    const news = await prisma.materialNews.findMany({
      orderBy: { publishedAt: 'desc' },
    });


    return NextResponse.json({ success: true, news });
  } catch (error) {
    console.error('Fetch news error:', error);
    return NextResponse.json({ error: 'Failed to fetch news' }, { status: 500 });
  }
}
