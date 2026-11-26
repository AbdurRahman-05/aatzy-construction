import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';
import { categoryNameFor, parseCategoryId } from '@/lib/materials';

export async function GET(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const notSelf = denyUnlessSelf(authResult.auth, new URL(request.url).searchParams.get('supplierId'));
    if (notSelf) return notSelf;

    const { searchParams } = new URL(request.url);
    const supplierId = searchParams.get('supplierId');

    if (!supplierId) {
      return NextResponse.json({ error: 'Missing supplierId' }, { status: 400 });
    }

    const products = await prisma.product.findMany({
      where: {
        providerId: supplierId,
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
      category_name: categoryNameFor(p.categoryId, p.category),
      category_id: p.categoryId || 1,
      rejected_reason: p.rejectedReason,
      specifications: p.specifications ? JSON.parse(p.specifications) : {},
      cost_price: p.costPrice,
    }));

    return NextResponse.json({ success: true, products: formatted });
  } catch (error) {
    console.error('Fetch supplier products error:', error);
    return NextResponse.json({ error: 'Failed to fetch supplier products' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const guardBody = await request.clone().json().catch(() => ({}));
    const notSelf = denyUnlessSelf(authResult.auth, guardBody?.supplierId);
    if (notSelf) return notSelf;

    const body = await request.json();
    const {
      supplierId,
      name,
      description,
      categoryId,
      price_per_unit,
      unit_type,
      specifications,
      images,
      cost_price,
    } = body;

    if (!supplierId || !name || !description) {
      return NextResponse.json({ error: 'Missing supplierId, name or description' }, { status: 400 });
    }

    const product = await prisma.product.create({
      data: {
        providerId: supplierId,
        name,
        description,
        categoryId: parseCategoryId(categoryId) ?? 1,
        category: categoryNameFor(parseCategoryId(categoryId) ?? 1),
        pricePerUnit: parseFloat(price_per_unit || 0),
        costPrice: parseFloat(cost_price || 0) || 0,
        unitType: unit_type || 'Bag',
        images: images || [],
        specifications: specifications ? JSON.stringify(specifications) : '{}',
        status: 'Approved',
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Product listing added successfully',
      product,
    }, { status: 201 });
  } catch (error) {
    console.error('Create supplier product error:', error);
    return NextResponse.json({ error: 'Failed to add product listing' }, { status: 500 });
  }
}
