import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function PUT(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const guardBody = await request.clone().json().catch(() => ({}));
    const notSelf = denyUnlessSelf(authResult.auth, guardBody?.supplierId);
    if (notSelf) return notSelf;

    const body = await request.json();
    const {
      supplierId,
      companyName,
      description,
      location,
      businessType,
      gstNumber,
      website,
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
        businessType: businessType,
        gstNumber: gstNumber,
        website: website,
      } as any,
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
