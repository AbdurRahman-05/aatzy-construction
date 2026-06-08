import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const inquiries = await prisma.inquiry.findMany({
      where: { providerId: id },
      include: {
        buyer: {
          select: {
            name: true,
            email: true,
          },
        },
        product: {
          select: {
            name: true,
            images: true,
            costPrice: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const formatted = inquiries.map(i => ({
      id: i.id,
      buyer_id: i.buyerId,
      supplier_id: i.providerId,
      product_id: i.productId,
      title: i.title,
      description: i.description,
      quantity: i.quantity,
      unit: i.unit,
      location: i.location,
      images: i.images,
      status: i.status,
      quoted_price: i.quotedPrice,
      delivery_status: i.deliveryStatus,
      gst_percent: i.gstPercent,
      rating: i.rating,
      review_text: i.reviewText,
      created_at: i.createdAt,
      updated_at: i.updatedAt,
      buyer_name: i.buyer.name,
      buyer_email: i.buyer.email,
      buyer_phone: '', // User schema doesn't store phone, so use empty or email
      product_name: i.product?.name || null,
      product_image: i.product?.images && i.product.images.length > 0 ? i.product.images[0] : null,
      product_cost: i.product?.costPrice || 0,
    }));

    return NextResponse.json({ success: true, leads: formatted });
  } catch (error) {
    console.error('Fetch provider leads error:', error);
    return NextResponse.json({ error: 'Failed to fetch leads' }, { status: 500 });
  }
}
