import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('categoryId') || searchParams.get('category');
    const query = searchParams.get('query');
    const location = searchParams.get('location');

    const products = await prisma.product.findMany({
      where: {
        deletedAt: null,
        status: 'Approved',
      },
      include: {
        provider: {
          select: {
            businessName: true,
            address: true,
            isVerified: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });


    // Apply code-level filtering
    let filtered = products;

    if (category && category !== 'All') {
      filtered = filtered.filter(p =>
        p.category?.toLowerCase().includes(category.toLowerCase())
      );
    }

    if (location && location !== 'All India') {
      filtered = filtered.filter(p =>
        p.provider.address?.toLowerCase().includes(location.toLowerCase())
      );
    }

    if (query) {
      const q = query.toLowerCase();
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        p.provider.businessName.toLowerCase().includes(q)
      );
    }

    // Map properties to match what Flutter expects
    const formatted = filtered.map(p => ({
      id: p.id,
      name: p.name,
      description: p.description,
      price_per_unit: p.pricePerUnit,
      unit_type: p.unitType,
      images: p.images,
      company_name: p.provider.businessName,
      location: p.provider.address || 'All India',
      category: p.category,
    }));

    return NextResponse.json({ success: true, products: formatted });
  } catch (error) {
    console.error('Fetch products list error:', error);
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 });
  }
}
