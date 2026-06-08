import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PUT(
  request: Request,
  context: { params: Promise<{ id: string; productId: string }> }
) {
  try {
    const { id, productId } = await context.params;
    const body = await request.json();
    const {
      name,
      description,
      category,
      pricePerUnit,
      unitType,
      costPrice,
      images,
      specifications,
    } = body;

    const check = await prisma.product.findFirst({
      where: { id: productId, providerId: id },
    });

    if (!check) {
      return NextResponse.json({ error: 'Product not found or not owned by you' }, { status: 404 });
    }

    const updated = await prisma.product.update({
      where: { id: productId },
      data: {
        name: name !== undefined ? name : undefined,
        description: description !== undefined ? description : undefined,
        category: category !== undefined ? category : undefined,
        pricePerUnit: pricePerUnit !== undefined ? parseFloat(pricePerUnit) : undefined,
        unitType: unitType !== undefined ? unitType : undefined,
        costPrice: costPrice !== undefined ? parseFloat(costPrice) : undefined,
        images: images !== undefined ? images : undefined,
        specifications: specifications !== undefined ? JSON.stringify(specifications) : undefined,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Product updated successfully',
      product: updated,
    });
  } catch (error) {
    console.error('Update product error:', error);
    return NextResponse.json({ error: 'Failed to update product' }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string; productId: string }> }
) {
  try {
    const { id, productId } = await context.params;

    const check = await prisma.product.findFirst({
      where: { id: productId, providerId: id },
    });

    if (!check) {
      return NextResponse.json({ error: 'Product not found or not owned by you' }, { status: 404 });
    }

    await prisma.product.update({
      where: { id: productId },
      data: { deletedAt: new Date() },
    });

    return NextResponse.json({
      success: true,
      message: 'Product listing deleted successfully',
    });
  } catch (error) {
    console.error('Delete product error:', error);
    return NextResponse.json({ error: 'Failed to delete product' }, { status: 500 });
  }
}
