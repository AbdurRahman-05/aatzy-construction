import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { categoryNameFor } from '@/lib/materials';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        provider: {
          include: {
            reviews: {
              select: {
                rating: true,
              },
            },
          },
        },
      },
    });

    if (!product || product.deletedAt || product.status !== 'Approved') {
      return NextResponse.json({ error: 'Product not found' }, { status: 404 });
    }

    // Supplier rating = project reviews + ratings from completed material orders
    const materialRatings = await prisma.inquiry.findMany({
      where: { providerId: product.providerId, rating: { not: null } },
      select: { rating: true },
    });
    const allRatings = [
      ...product.provider.reviews.map(r => r.rating),
      ...materialRatings.map(r => r.rating as number),
    ];
    const avgRating = allRatings.length > 0
      ? parseFloat((allRatings.reduce((sum, r) => sum + r, 0) / allRatings.length).toFixed(1))
      : 0.0;

    // Get related products
    const related = await prisma.product.findMany({
      where: {
        ...(product.categoryId ? { categoryId: product.categoryId } : { category: product.category }),
        id: { not: id },
        status: 'Approved',
        deletedAt: null,
      },
      take: 4,
    });

    const relatedFormatted = related.map(p => ({
      id: p.id,
      name: p.name,
      images: p.images,
      price_per_unit: p.pricePerUnit,
      unit_type: p.unitType,
    }));

    const formattedProduct = {
      id: product.id,
      name: product.name,
      description: product.description,
      specifications: product.specifications ? JSON.parse(product.specifications) : {},
      images: product.images,
      price_per_unit: product.pricePerUnit,
      unit_type: product.unitType,
      supplier_id: product.providerId,
      company_name: product.provider.businessName,
      supplier_description: product.provider.bio || '',
      supplier_location: product.provider.address || 'All India',
      category: categoryNameFor(product.categoryId, product.category),
      is_verified: product.provider.isVerified,
      business_type: product.provider.businessType || 'Supplier',
      website: product.provider.website || '',
      logo_url: product.provider.profileImage || '',
      avg_rating: avgRating,
      total_reviews: allRatings.length,
    };

    return NextResponse.json({
      success: true,
      product: formattedProduct,
      relatedProducts: relatedFormatted,
    });
  } catch (error) {
    console.error('Fetch product detail error:', error);
    return NextResponse.json({ error: 'Failed to fetch product detail' }, { status: 500 });
  }
}
