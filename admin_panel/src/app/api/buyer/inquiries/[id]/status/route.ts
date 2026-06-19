import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const { status, notes, rating, reviewText, buyerId, images } = body;

    const inquiry = await prisma.inquiry.findUnique({
      where: { id },
    });

    if (!inquiry) {
      return NextResponse.json({ error: 'Inquiry not found' }, { status: 404 });
    }

    const updateData: any = {};
    let logStatus = inquiry.status;
    let logNotes = notes;

    if (status) {
      updateData.status = status;
      logStatus = status;
      if (!logNotes) {
        logNotes = `Inquiry status updated to ${status} by buyer.`;
      }
    }

    if (images && Array.isArray(images)) {
      updateData.images = images;
    }

    if (rating !== undefined && rating !== null) {
      updateData.rating = parseInt(rating.toString());
      updateData.reviewText = reviewText || null;
      if (!logNotes) {
        logNotes = `Buyer rated supplier: ${rating} Stars. ${reviewText ? `Review: "${reviewText}"` : ''}`;
      }
    }

    const updated = await prisma.inquiry.update({
      where: { id },
      data: updateData,
    });

    // Write to status logs
    await prisma.inquiryStatusLog.create({
      data: {
        inquiryId: id,
        status: logStatus,
        notes: logNotes || 'Status updated.',
        changedByUserId: buyerId || inquiry.buyerId,
      },
    });

    // Notify status change asynchronously
    const { notifyInquiryStatusChange } = require('@/lib/mail');
    notifyInquiryStatusChange(id).catch((err: any) => {
      console.error('Inquiry status change email notification error:', err);
    });

    return NextResponse.json({
      success: true,
      message: 'Inquiry status updated successfully',
      inquiry: updated,
    });
  } catch (error) {
    console.error('Update inquiry status error:', error);
    return NextResponse.json({ error: 'Failed to update inquiry status' }, { status: 500 });
  }
}
