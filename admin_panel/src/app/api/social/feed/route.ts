import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const images = await prisma.portfolioImage.findMany({
      include: {
        provider: {
          select: {
            id: true,
            businessName: true,
            ownerName: true,
            category: true,
          }
        }
      },
      orderBy: { createdAt: 'desc' },
    });

    return NextResponse.json({ images });
  } catch (error) {
    console.error('Fetch social feed error:', error);
    return NextResponse.json({ error: 'Failed to fetch social feed' }, { status: 500 });
  }
}
