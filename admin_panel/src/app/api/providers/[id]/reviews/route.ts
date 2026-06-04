import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: providerId } = await context.params;
    const body = await request.json();
    const { userId, rating, comment, projectId } = body;

    if (!userId || rating === undefined || rating === null) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const numericRating = parseInt(rating);
    if (isNaN(numericRating) || numericRating < 1 || numericRating > 5) {
      return NextResponse.json({ error: 'Rating must be between 1 and 5' }, { status: 400 });
    }

    const review = await prisma.review.create({
      data: {
        providerId,
        userId,
        projectId: projectId || null,
        rating: numericRating,
        comment: comment || "",
      },
      include: {
        user: {
          select: {
            name: true,
          }
        }
      }
    });

    return NextResponse.json(review, { status: 201 });
  } catch (error) {
    console.error('Create review error:', error);
    return NextResponse.json({ error: 'Failed to create review' }, { status: 500 });
  }
}
