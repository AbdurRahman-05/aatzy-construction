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
        quotedPrice: quotedPrice !== undefined ? parseFloat(quotedPrice.toString()) : undefined,
        deliveryStatus: deliveryStatus || undefined,
        gstPercent: gstPercent !== undefined ? parseFloat(gstPercent.toString()) : undefined,
      },
    });

    await prisma.inquiryStatusLog.create({
      data: {
        inquiryId: id,
        status: status || inquiry.status,
        notes: notes || `Lead status updated to: ${status || inquiry.status}`,
      },
    });

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
