import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

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
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const { id: guardProviderId } = await context.params;
    const notSelf = denyUnlessSelf(authResult.auth, guardProviderId);
    if (notSelf) return notSelf;

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

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const { id: guardProviderId } = await context.params;
    const notSelf = denyUnlessSelf(authResult.auth, guardProviderId);
    if (notSelf) return notSelf;

    const { searchParams } = new URL(request.url);
    const imageId = searchParams.get('imageId');

    if (!imageId) {
      return NextResponse.json({ error: 'Image ID is required' }, { status: 400 });
    }

    // Only delete images that belong to this provider
    const removed = await prisma.portfolioImage.deleteMany({
      where: { id: imageId, providerId: guardProviderId },
    });
    if (removed.count === 0) {
      return NextResponse.json({ error: 'Image not found' }, { status: 404 });
    }

    return NextResponse.json({ message: 'Image deleted successfully' });
  } catch (error) {
    console.error('Delete portfolio image error:', error);
    return NextResponse.json({ error: 'Failed to delete portfolio image' }, { status: 500 });
  }
}
