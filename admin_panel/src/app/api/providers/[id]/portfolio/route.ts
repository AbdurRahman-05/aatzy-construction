import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const images = await prisma.portfolioImage.findMany({
      where: { providerId: id },
      orderBy: { createdAt: 'desc' },
    });

    return NextResponse.json({ images });
  } catch (error) {
    console.error('Fetch portfolio images error:', error);
    return NextResponse.json({ error: 'Failed to fetch portfolio images' }, { status: 500 });
  }
}

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const { title, description, imageData } = body;

    if (!title || !imageData) {
      return NextResponse.json({ error: 'Title and image data are required' }, { status: 400 });
    }

    const newImage = await prisma.portfolioImage.create({
      data: {
        providerId: id,
        title,
        description,
        imageData,
      },
    });

    return NextResponse.json(newImage, { status: 201 });
  } catch (error) {
    console.error('Add portfolio image error:', error);
    return NextResponse.json({ error: 'Failed to add portfolio image' }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const imageId = searchParams.get('imageId');

    if (!imageId) {
      return NextResponse.json({ error: 'Image ID is required' }, { status: 400 });
    }

    await prisma.portfolioImage.delete({
      where: { id: imageId },
    });

    return NextResponse.json({ message: 'Image deleted successfully' });
  } catch (error) {
    console.error('Delete portfolio image error:', error);
    return NextResponse.json({ error: 'Failed to delete portfolio image' }, { status: 500 });
  }
}
