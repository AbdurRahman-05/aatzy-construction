import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PUT(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
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
    } = body;

    const product = await prisma.product.update({
      where: { id },
      data: {
        name,
        description,
        categoryId: categoryId ? parseInt(categoryId.toString()) : undefined,
        pricePerUnit: price_per_unit ? parseFloat(price_per_unit.toString()) : undefined,
        unitType: unit_type,
        images: images,
        specifications: specifications ? JSON.stringify(specifications) : undefined,
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
