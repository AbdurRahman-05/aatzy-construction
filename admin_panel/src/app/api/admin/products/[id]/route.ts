import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAdmin } from '@/lib/auth';
import { createNotification } from '@/lib/notifications';

const ALLOWED_STATUSES = ['Approved', 'Rejected'];

/**
 * Admin product moderation.
 * Body: { status: 'Approved' | 'Rejected', rejectedReason?: string }
 * Rejected products are hidden from customers until the partner edits them (they go back to Pending).
 */
export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    const body = await request.json().catch(() => ({}));
    const status = String(body.status || '');
    const reason = typeof body.rejectedReason === 'string' ? body.rejectedReason.trim().slice(0, 300) : '';

    if (!ALLOWED_STATUSES.includes(status)) {
      return NextResponse.json({ error: 'status must be Approved or Rejected' }, { status: 400 });
    }
    if (status === 'Rejected' && !reason) {
      return NextResponse.json({ error: 'Please give a reason so the partner can fix the listing.' }, { status: 400 });
    }

    const existing = await prisma.product.findFirst({
      where: { id, deletedAt: null },
      select: { id: true, name: true, providerId: true },
    });
    if (!existing) {
      return NextResponse.json({ error: 'Product not found' }, { status: 404 });
    }

    const product = await prisma.product.update({
      where: { id },
      data: {
        status,
        rejectedReason: status === 'Rejected' ? reason : null,
      },
      select: { id: true, status: true, rejectedReason: true },
    });

    // Let the partner know (best effort)
    try {
      await createNotification({
        recipientId: existing.providerId,
        role: 'PROVIDER',
        title: status === 'Rejected' ? `⚠️ Product hidden: ${existing.name}` : `✅ Product approved: ${existing.name}`,
        body: status === 'Rejected'
          ? `Your listing was hidden from customers. Reason: ${reason}. Edit the product to send it for review again.`
          : 'Your listing is now visible to customers.',
        type: 'TASK_COMPLETED',
        entityId: existing.id,
        route: '/supplier-products',
      });
    } catch (notifyErr) {
      console.error('Product moderation notification error:', notifyErr);
    }

    return NextResponse.json({ success: true, product });
  } catch (error) {
    console.error('Admin product moderation error:', error);
    return NextResponse.json({ error: 'Failed to update product' }, { status: 500 });
  }
}
