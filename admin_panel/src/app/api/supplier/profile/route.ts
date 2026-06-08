import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const {
      supplierId,
      companyName,
      description,
      location,
    } = body;

    if (!supplierId) {
      return NextResponse.json({ error: 'Missing supplierId' }, { status: 400 });
    }

    const updatedProvider = await prisma.provider.update({
      where: { id: supplierId },
      data: {
        businessName: companyName,
        address: location,
        bio: description,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Business profile updated successfully',
      provider: updatedProvider,
    });
  } catch (error) {
    console.error('Update supplier profile error:', error);
    return NextResponse.json({ error: 'Failed to update profile' }, { status: 500 });
  }
}
