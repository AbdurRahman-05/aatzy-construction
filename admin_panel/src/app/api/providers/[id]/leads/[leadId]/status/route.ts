import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(
  request: Request,
  context: { params: Promise<{ id: string; leadId: string }> }
) {
  try {
    const { id, leadId } = await context.params;
    const body = await request.json();
    const { status, notes, quotedPrice, deliveryStatus, gstPercent } = body;

    const inquiry = await prisma.inquiry.findFirst({
      where: { id: leadId, providerId: id },
    });

    if (!inquiry) {
      return NextResponse.json({ error: 'Lead not found or not assigned to you' }, { status: 404 });
    }

    const updated = await prisma.inquiry.update({
      where: { id: leadId },
      data: {
        status: status || undefined,
        quotedPrice: (quotedPrice !== undefined && quotedPrice !== null) ? parseFloat(quotedPrice.toString()) : undefined,
        deliveryStatus: (deliveryStatus !== undefined && deliveryStatus !== null) ? deliveryStatus : undefined,
        gstPercent: (gstPercent !== undefined && gstPercent !== null) ? parseFloat(gstPercent.toString()) : undefined,
      },
    });

    // Create a status log
    await prisma.inquiryStatusLog.create({
      data: {
        inquiryId: leadId,
        status: status || inquiry.status,
        notes: notes || `Lead status updated to: ${status || inquiry.status}`,
        changedByUserId: id,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Lead status updated successfully',
      inquiry: updated,
    });
  } catch (error) {
    console.error('Update lead status error:', error);
    return NextResponse.json({ error: 'Failed to update lead status' }, { status: 500 });
  }
}
