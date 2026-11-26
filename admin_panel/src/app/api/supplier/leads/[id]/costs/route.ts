import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAuth, forbidden } from '@/lib/auth';
import { orderProfit, parseCost } from '@/lib/materials';

/**
 * PATCH /api/supplier/leads/:id/costs  { unitCost?, extraCost? }
 *
 * Partner-only bookkeeping: what the partner paid per unit and any extra costs
 * (transport, loading, labour) for this order. Allowed at any stage - even after the
 * order is completed - because it is private and changes nothing for the buyer.
 * No status log, no notifications.
 */
export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const authResult = requireAuth(request, { roles: ['PROVIDER'] });
    if (!authResult.ok) return authResult.response;
    const { id } = await context.params;

    const inquiry = await prisma.inquiry.findUnique({
      where: { id },
      select: { id: true, providerId: true, quantity: true, quotedPrice: true, product: { select: { costPrice: true } } },
    });
    if (!inquiry) return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    if (authResult.auth && inquiry.providerId !== authResult.auth.id) {
      return forbidden('This order is not assigned to you.');
    }

    const body = await request.json().catch(() => ({}));
    const unitCost = parseCost(body.unitCost);
    const extraCost = parseCost(body.extraCost);
    if (!unitCost.ok) return NextResponse.json({ error: unitCost.error }, { status: 400 });
    if (!extraCost.ok) return NextResponse.json({ error: extraCost.error }, { status: 400 });
    if (unitCost.value === undefined && extraCost.value === undefined) {
      return NextResponse.json({ error: 'Nothing to update.' }, { status: 400 });
    }

    const updated = await prisma.inquiry.update({
      where: { id },
      data: {
        unitCost: unitCost.value,
        extraCost: extraCost.value === null ? 0 : extraCost.value,
      },
      select: { unitCost: true, extraCost: true },
    });

    const pnl = orderProfit({
      quantity: inquiry.quantity,
      quotedPrice: inquiry.quotedPrice,
      unitCost: updated.unitCost,
      extraCost: updated.extraCost,
      productCostPrice: inquiry.product?.costPrice,
    });

    return NextResponse.json({
      success: true,
      unit_cost: updated.unitCost,
      extra_cost: updated.extraCost,
      profit: pnl.profit,
    });
  } catch (error) {
    console.error('Update lead costs error:', error);
    return NextResponse.json({ error: 'Failed to save costs' }, { status: 500 });
  }
}

/** The partner app sends PUT (its API client has no PATCH). */
export const PUT = PATCH;
