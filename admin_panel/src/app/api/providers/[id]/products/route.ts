import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const products = await prisma.product.findMany({
      where: {
        providerId: id,
        deletedAt: null,
      },
      orderBy: { createdAt: 'desc' },
    });

    const formatted = products.map(p => ({
      id: p.id,
      name: p.name,
      description: p.description,
      price_per_unit: p.pricePerUnit,
      unit_type: p.unitType,
      images: p.images,
      status: p.status,
      category: p.category,
      specifications: p.specifications ? JSON.parse(p.specifications) : {},
      cost_price: p.costPrice,
    }));

    return NextResponse.json({ success: true, products: formatted });
  } catch (error) {
    console.error('Fetch provider products error:', error);
    return NextResponse.json({ error: 'Failed to fetch provider products' }, { status: 500 });
  }
}

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
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

    if (!name || !description) {
      return NextResponse.json({ error: 'Missing product name or description' }, { status: 400 });
    }

    const product = await prisma.product.create({
      data: {
        providerId: id,
        name,
        description,
        category: category || 'Materials & Supply',
        pricePerUnit: parseFloat(pricePerUnit || 0),
        unitType: unitType || 'Bag',
        costPrice: parseFloat(costPrice || 0),
        images: images || [],
        specifications: specifications ? JSON.stringify(specifications) : '{}',
        status: 'Approved', // auto-approve listings
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Product listing added successfully',
      product,
    }, { status: 201 });
  } catch (error) {
    console.error('Create provider product error:', error);
    return NextResponse.json({ error: 'Failed to add product listing' }, { status: 500 });
  }
}
