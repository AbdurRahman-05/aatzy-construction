import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;

    const inquiry = await prisma.inquiry.findUnique({
      where: { id },
      include: {
        provider: {
          select: {
            businessName: true,
            address: true,
          },
        },
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
          },
        },
        statusLogs: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!inquiry) {
      return NextResponse.json({ error: 'Inquiry not found' }, { status: 404 });
    }

    const formattedInquiry = {
      id: inquiry.id,
      buyer_id: inquiry.buyerId,
      supplier_id: inquiry.providerId,
      product_id: inquiry.productId,
      title: inquiry.title,
      description: inquiry.description,
      quantity: inquiry.quantity,
      unit: inquiry.unit,
      location: inquiry.location,
      images: inquiry.images,
      status: inquiry.status,
      quoted_price: inquiry.quotedPrice,
      delivery_status: inquiry.deliveryStatus,
      gst_percent: inquiry.gstPercent,
      rating: inquiry.rating,
      review_text: inquiry.reviewText,
      created_at: inquiry.createdAt,
      updated_at: inquiry.updatedAt,
      supplier_name: inquiry.provider.businessName,
      supplier_location: inquiry.provider.address || 'All India',
      product_name: inquiry.product?.name || null,
    };

    const timeline = inquiry.statusLogs.map(log => ({
      id: log.id,
      inquiry_id: log.inquiryId,
      status: log.status,
      notes: log.notes,
      changed_by_user_id: log.changedByUserId,
      created_at: log.createdAt,
      changed_by_name: log.changedByUserId === inquiry.buyerId ? inquiry.buyer.name : inquiry.provider.businessName,
    }));

    return NextResponse.json({
      success: true,
      inquiry: formattedInquiry,
      timeline,
    });
  } catch (error) {
    console.error('Fetch inquiry detail error:', error);
    return NextResponse.json({ error: 'Failed to fetch inquiry detail' }, { status: 500 });
  }
}
