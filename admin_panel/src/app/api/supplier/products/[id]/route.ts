import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, forbidden } from '@/lib/auth';
import { categoryNameFor, parseCategoryId } from '@/lib/materials';

export async function PUT(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const { id: guardProductId } = await context.params;
    if (authResult.auth) {
      const owned = await prisma.product.findFirst({ where: { id: guardProductId, providerId: authResult.auth.id }, select: { id: true } });
      if (!owned) return forbidden('You can only change your own products.');
    }

    const { id } = await context.params;
    const body = await request.json();
    const {
      name,
      description,
      categoryId,
      price_per_unit,
      unit_type,
      specifications,
      images,
      cost_price,
    } = body;

    const newCategoryId = parseCategoryId(categoryId);
    // A listing the admin rejected goes back to review after the partner edits it
    const current = await prisma.product.findUnique({ where: { id }, select: { status: true } });
    const backToReview = current?.status === 'Rejected';
    const product = await prisma.product.update({
      where: { id },
      data: {
        name,
        description,
        categoryId: newCategoryId,
        category: newCategoryId ? categoryNameFor(newCategoryId) : undefined,
        pricePerUnit: price_per_unit ? parseFloat(price_per_unit.toString()) : undefined,
        costPrice: cost_price !== undefined && cost_price !== null && cost_price !== '' ? (parseFloat(cost_price.toString()) || 0) : undefined,
        unitType: unit_type,
        images: images,
        specifications: specifications ? JSON.stringify(specifications) : undefined,
        ...(backToReview ? { status: 'Pending', rejectedReason: null } : {}),
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Product listing updated successfully',
      product,
    });
  } catch (error) {
    console.error('Update supplier product error:', error);
    return NextResponse.json({ error: 'Failed to update product listing' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const { id: guardProductId } = await context.params;
    if (authResult.auth) {
      const owned = await prisma.product.findFirst({ where: { id: guardProductId, providerId: authResult.auth.id }, select: { id: true } });
      if (!owned) return forbidden('You can only change your own products.');
    }

    const { id } = await context.params;

    // Soft delete product
    await prisma.product.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Product listing deleted successfully',
    });
  } catch (error) {
    console.error('Delete supplier product error:', error);
    return NextResponse.json({ error: 'Failed to delete product listing' }, { status: 500 });
  }
}
