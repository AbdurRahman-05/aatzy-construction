import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const buyerId = searchParams.get('buyerId');

    if (!buyerId) {
      return NextResponse.json({ error: 'buyerId query parameter is required' }, { status: 400 });
    }

    const inquiries = await prisma.inquiry.findMany({
      where: { buyerId },
      include: {
        provider: {
          select: {
            businessName: true,
            profileImage: true,
          },
        },
        product: {
          select: {
            name: true,
            images: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const formatted = inquiries.map(i => {
      const productImage = i.product?.images && i.product.images.length > 0
        ? i.product.images[0]
        : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400';

      return {
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
        supplier_name: i.provider.businessName,
        supplier_logo: i.provider.profileImage,
        product_name: i.product?.name || null,
        product_image: productImage,
      };
    });

    return NextResponse.json({ success: true, inquiries: formatted });
  } catch (error) {
    console.error('Fetch inquiries error:', error);
    return NextResponse.json({ error: 'Failed to fetch inquiries' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      buyerId,
      supplierId,
      productId,
      title,
      description,
      quantity,
      unit,
      location,
      images,
    } = body;

    if (!buyerId || !supplierId || !title || !description || quantity === undefined) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const inquiry = await prisma.inquiry.create({
      data: {
        buyerId,
        providerId: supplierId,
        productId: productId || null,
        title,
        description,
        quantity: parseFloat(quantity),
        unit: unit || 'Units',
        location: location || 'India',
        images: images || [],
        status: 'New',
        deliveryStatus: 'Pending',
        quotedPrice: null,
      },
    });

    // Create status log
    await prisma.inquiryStatusLog.create({
      data: {
        inquiryId: inquiry.id,
        status: 'New',
        notes: 'Inquiry submitted by buyer.',
        changedByUserId: buyerId,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Inquiry submitted successfully',
      inquiry,
    }, { status: 201 });
  } catch (error) {
    console.error('Create inquiry error:', error);
    return NextResponse.json({ error: 'Failed to submit inquiry' }, { status: 500 });
  }
}
