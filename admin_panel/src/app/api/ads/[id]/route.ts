import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await request.json();

    const ad = await (prisma as any).ad.update({
      where: { id },
      data: body,
    });

    return NextResponse.json({ success: true, ad });
  } catch (error) {
    console.error('Update ad error:', error);
    return NextResponse.json({ error: 'Failed to update ad' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
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
