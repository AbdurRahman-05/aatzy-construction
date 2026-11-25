import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, denyUnlessSelf } from '@/lib/auth';

export async function GET(request: Request) {
  try {
    const authResult = requireAuth(request, { roles: ['CONSUMER'] });
    if (!authResult.ok) return authResult.response;
    const notSelf = denyUnlessSelf(authResult.auth, new URL(request.url).searchParams.get('buyerId'));
    if (notSelf) return notSelf;

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
    const authResult = requireAuth(request, { roles: ['CONSUMER'] });
    if (!authResult.ok) return authResult.response;
    const guardBody = await request.clone().json().catch(() => ({}));
    const notSelf = denyUnlessSelf(authResult.auth, guardBody?.buyerId);
    if (notSelf) return notSelf;

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

    // Fetch buyer and supplier details to send notification emails & push notifications
    try {
      const [buyer, provider] = await Promise.all([
        prisma.user.findUnique({ where: { id: buyerId } }).catch(() => null),
        prisma.provider.findUnique({ where: { id: supplierId } }).catch(() => null),
      ]);

      const buyerName = buyer?.name || 'A customer';
      const locText = inquiry.location && inquiry.location !== 'none' && inquiry.location.toLowerCase() !== 'india'
        ? ` in ${inquiry.location}`
        : '';
      const bodyText = `${buyerName} requested ${inquiry.quantity} ${inquiry.unit}${locText}. Tap to quote.`;

      // Send push notification & create in-app notification for the supplier
      const { createNotification } = await import('@/lib/notifications');
      await createNotification({
        recipientId: supplierId,
        role: 'PROVIDER',
        title: `📦 New Material Request: ${inquiry.title}`,
        body: bodyText,
        type: 'NEW_LEAD',
        entityId: inquiry.id,
        route: '/b2b-materials',
      });

      // Send email if buyer and provider are found
      if (buyer && provider) {
        try {
          const { sendInquiryNotification } = await import('@/lib/mail');
          await sendInquiryNotification(inquiry, buyer, provider);
        } catch (mailErr) {
          console.error('Inquiry notification email error:', mailErr);
        }
      }
    } catch (notifErr) {
      console.error('Failed to dispatch inquiry notification:', notifErr);
    }

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
