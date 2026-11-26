import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { categoryNameFor } from '@/lib/materials';

/** Turns a free-text address into a short place name, e.g. "12, Anna Nagar, Madurai - 625020" -> "Madurai". */
function placeFromAddress(address: string | null | undefined): string | null {
  if (!address) return null;
  const parts = address
    .split(/[,\n]/)
    .map(p => p.replace(/[-–]?\s*\d{6}\b/g, '').replace(/\b\d+[\w/-]*\b/g, '').trim())
    .filter(p => p.length >= 3 && !/^(india|tamil ?nadu|kerala|karnataka|andhra pradesh|telangana|maharashtra)$/i.test(p));
  if (parts.length === 0) return null;
  const place = parts[parts.length - 1];
  return place.charAt(0).toUpperCase() + place.slice(1);
}

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
            id: true,
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

    const withCategory = products.map(p => ({ ...p, categoryName: categoryNameFor(p.categoryId, p.category) }));

    // Location choices come from the suppliers that actually have products
    const locationSet = new Map<string, string>();
    for (const p of withCategory) {
      const place = placeFromAddress(p.provider.address);
      if (place && !locationSet.has(place.toLowerCase())) locationSet.set(place.toLowerCase(), place);
    }
    const locations = Array.from(locationSet.values()).sort((a, b) => a.localeCompare(b));

    let filtered = withCategory;

    if (category && category !== 'All') {
      const wanted = category.toLowerCase();
      filtered = filtered.filter(p => p.categoryName.toLowerCase() === wanted);
    }

    if (location && location !== 'All India') {
      const wanted = location.toLowerCase();
      filtered = filtered.filter(p => p.provider.address?.toLowerCase().includes(wanted));
    }

    if (query) {
      const q = query.toLowerCase();
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        p.categoryName.toLowerCase().includes(q) ||
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
      supplier_id: p.provider.id,
      company_name: p.provider.businessName,
      is_verified: p.provider.isVerified,
      location: placeFromAddress(p.provider.address) || p.provider.address || 'All India',
      category: p.categoryName,
    }));

    return NextResponse.json({ success: true, products: formatted, locations });
  } catch (error) {
    console.error('Fetch products list error:', error);
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 });
  }
}
