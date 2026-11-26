import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, forbidden } from '@/lib/auth';
import { checkSupplierUpdate } from '@/lib/materials';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const { id: guardInquiryId } = await context.params;
    if (authResult.auth) {
      const owned = await prisma.inquiry.findFirst({ where: { id: guardInquiryId, providerId: authResult.auth.id }, select: { id: true } });
      if (!owned) return forbidden('This lead is not assigned to you.');
    }

    const { id } = await context.params;
    const body = await request.json();
    const { status, notes, quotedPrice, deliveryStatus, gstPercent } = body;

    const inquiry = await prisma.inquiry.findFirst({
      where: { id },
    });

    if (!inquiry) {
      return NextResponse.json({ error: 'Inquiry not found' }, { status: 404 });
    }

    const nextPrice = (quotedPrice !== undefined && quotedPrice !== null && quotedPrice !== '') ? parseFloat(quotedPrice.toString()) : undefined;
    const nextGst = (gstPercent !== undefined && gstPercent !== null && gstPercent !== '') ? parseFloat(gstPercent.toString()) : undefined;
    const nextDelivery = (deliveryStatus !== undefined && deliveryStatus !== null && deliveryStatus !== '') ? String(deliveryStatus) : undefined;
    const nextStatus = status ? String(status) : undefined;

    // Locked price after acceptance, no self-accepting, delivery only after acceptance, etc.
    const rule = checkSupplierUpdate(inquiry, {
      status: nextStatus,
      // Re-sending the same price/GST on an accepted order is harmless - only real changes count
      quotedPrice: nextPrice !== undefined && nextPrice !== inquiry.quotedPrice ? nextPrice : undefined,
      gstPercent: nextGst !== undefined && nextGst !== inquiry.gstPercent ? nextGst : undefined,
      deliveryStatus: nextDelivery,
    });
    if (!rule.ok) {
      return NextResponse.json({ error: rule.error, code: rule.code }, { status: 409 });
    }

    const updated = await prisma.inquiry.update({
      where: { id },
      data: {
        status: nextStatus,
        quotedPrice: nextPrice,
        deliveryStatus: nextDelivery,
        gstPercent: nextGst,
      },
    });

    await prisma.inquiryStatusLog.create({
      data: {
        inquiryId: id,
        status: status || inquiry.status,
        notes: notes || `Lead status updated to: ${status || inquiry.status}`,
        changedByUserId: inquiry.providerId,
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
