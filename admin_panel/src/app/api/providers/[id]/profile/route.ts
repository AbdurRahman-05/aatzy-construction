import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const provider = await prisma.provider.findUnique({
      where: { id },
      select: {
        id: true,
        businessName: true,
        ownerName: true,
        email: true,
        phone: true,
        category: true,
        experience: true,
        isVerified: true,
        isRejected: true,
        address: true,
        bio: true,
        aadharCard: true,
        panCard: true,
        profileCompletion: true,
        createdAt: true,
      },
    });

    if (!provider) {
      return NextResponse.json({ error: 'Provider not found' }, { status: 404 });
    }

    return NextResponse.json({ provider });
  } catch (error) {
    console.error('Get provider profile error:', error);
    return NextResponse.json({ error: 'Failed to fetch provider' }, { status: 500 });
  }
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();

    const updatedProvider = await prisma.provider.update({
      where: { id },
      data: {
        businessName: body.businessName,
        ownerName: body.ownerName,
        phone: body.phone,
        category: body.category,
        experience: body.experience ? parseInt(body.experience) : undefined,
        address: body.address,
        bio: body.bio,
        aadharCard: body.aadharCard,
        panCard: body.panCard,
        profileCompletion: body.profileCompletion,
      },
    });

    return NextResponse.json(updatedProvider);
  } catch (error) {
    console.error('Update provider error:', error);
    return NextResponse.json({ error: 'Failed to update profile' }, { status: 500 });
  }
}
