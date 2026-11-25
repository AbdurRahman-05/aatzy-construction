import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAdmin } from '@/lib/auth';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    const body = await request.json();

    // Only allow known ad fields to be updated
    const editable = [
      'title', 'desc', 'badge', 'icon', 'gradient', 'imageUrl', 'mediaType',
      'videoUrl', 'targetSide', 'placement', 'actionUrl', 'actionText', 'isActive',
    ];
    const data: Record<string, unknown> = {};
    for (const key of editable) {
      if (body[key] !== undefined) data[key] = body[key];
    }
    if (data.placement !== undefined) {
      const p = String(data.placement).toUpperCase();
      if (!['POPUP', 'HOME', 'BOTH'].includes(p)) {
        return NextResponse.json({ error: 'placement must be POPUP, HOME or BOTH' }, { status: 400 });
      }
      data.placement = p;
    }

    const ad = await (prisma as any).ad.update({
      where: { id },
      data,
    });

    return NextResponse.json({ success: true, ad });
  } catch (error) {
    console.error('Update ad error:', error);
    return NextResponse.json({ error: 'Failed to update ad' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;

    await (prisma as any).ad.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Ad deleted successfully' });
  } catch (error) {
    console.error('Delete ad error:', error);
    return NextResponse.json({ error: 'Failed to delete ad' }, { status: 500 });
  }
}
