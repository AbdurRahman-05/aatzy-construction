import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const { status, notes, quotedPrice, deliveryStatus, gstPercent } = body;

    const inquiry = await prisma.inquiry.findFirst({
      where: { id },
    });

    if (!inquiry) {
      return NextResponse.json({ error: 'Inquiry not found' }, { status: 404 });
    }

    const updated = await prisma.inquiry.update({
      where: { id },
      data: {
        status: status || undefined,
        quotedPrice: (quotedPrice !== undefined && quotedPrice !== null) ? parseFloat(quotedPrice.toString()) : undefined,
        deliveryStatus: (deliveryStatus !== undefined && deliveryStatus !== null) ? deliveryStatus : undefined,
        gstPercent: (gstPercent !== undefined && gstPercent !== null) ? parseFloat(gstPercent.toString()) : undefined,
      },
    });

    await prisma.inquiryStatusLog.create({
      data: {
        inquiryId: id,
        status: status || inquiry.status,
        notes: notes || `Lead status updated to: ${status || inquiry.status}`,
      },
    });

    // Notify status change asynchronously via email
    const { notifyInquiryStatusChange } = require('@/lib/mail');
    notifyInquiryStatusChange(id).catch((err: any) => {
      console.error('Lead status change email notification error:', err);
    });

    // Send push notification & in-app notification to buyer
    try {
      const { createNotification } = await import('@/lib/notifications');
      let notifTitle = `📦 Material Update: ${inquiry.title}`;
      let notifBody = `Order status updated to: ${status || inquiry.status}`;

      if (deliveryStatus) {
        if (deliveryStatus === 'Packed') {
          notifTitle = `📦 Material Packed: ${inquiry.title}`;
          notifBody = `Your order of ${inquiry.quantity} ${inquiry.unit} has been packed and prepared for dispatch.`;
        } else if (deliveryStatus === 'Dispatched') {
          notifTitle = `🚚 Material Dispatched: ${inquiry.title}`;
          notifBody = `Your order of ${inquiry.quantity} ${inquiry.unit} is on the way to ${inquiry.location}.`;
        } else if (deliveryStatus === 'Delivered') {
          notifTitle = `✅ Material Delivered: ${inquiry.title}`;
          notifBody = `Your order of ${inquiry.quantity} ${inquiry.unit} has arrived! Please confirm receipt.`;
        } else {
          notifTitle = `📦 Shipment Status: ${deliveryStatus}`;
          notifBody = `${inquiry.title} (${inquiry.quantity} ${inquiry.unit}) is now ${deliveryStatus}.`;
        }
      } else if (status === 'Quote Sent' || (quotedPrice !== undefined && quotedPrice !== null)) {
        notifTitle = `💰 New Quotation: ₹${quotedPrice}/${inquiry.unit}`;
        notifBody = `Supplier submitted a wholesale quote for ${inquiry.title}. Tap to review and accept.`;
      } else if (status === 'Lead Rejected') {
        notifTitle = `❌ Material Request Declined: ${inquiry.title}`;
        notifBody = `Supplier could not fulfill your inquiry at this time.`;
      }

      await createNotification({
        recipientId: inquiry.buyerId,
        role: 'CONSUMER',
        title: notifTitle,
        body: notifBody,
        type: 'TASK_COMPLETED',
        entityId: inquiry.id,
        route: '/b2b-my-inquiries',
      });
    } catch (notifErr) {
      console.error('Error dispatching material push notification to buyer:', notifErr);
    }

    return NextResponse.json({
      success: true,
      message: 'Lead status updated successfully',
      inquiry: updated,
    });
  } catch (error) {
    console.error('Update supplier lead status error:', error);
    return NextResponse.json({ error: 'Failed to update lead status' }, { status: 500 });
  }
}
