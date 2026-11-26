import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';
import { categoryNameFor } from '@/lib/materials';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    // Public endpoint: the partner sees everything (incl. cost price and pending/rejected items);
    // everyone else only sees live products, without the partner's buying price.
    const authResult = requireAuth(request);
    if (!authResult.ok) return authResult.response;
    const isOwner = authResult.auth?.role === 'PROVIDER' && authResult.auth.id === id;

    const products = await prisma.product.findMany({
      where: {
        providerId: id,
        deletedAt: null,
        ...(isOwner ? {} : { status: 'Approved' }),
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
      category: categoryNameFor(p.categoryId, p.category),
      category_name: categoryNameFor(p.categoryId, p.category),
      category_id: p.categoryId || 1,
      specifications: p.specifications ? JSON.parse(p.specifications) : {},
      ...(isOwner ? { cost_price: p.costPrice, rejected_reason: p.rejectedReason } : {}),
    }));

    return NextResponse.json({ success: true, products: formatted });
  } catch (error) {
    console.error('Fetch provider products error:', error);
    return NextResponse.json({ error: 'Failed to fetch provider products' }, { status: 500 });
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
