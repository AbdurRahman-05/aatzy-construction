import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const provider = await prisma.provider.findUnique({ where: { id } });
    if (!provider) return NextResponse.json({ error: 'Provider not found' }, { status: 404 });

    const updatedProvider = await prisma.provider.update({
      where: { id },
      data: { isVerified: !provider.isVerified },
    });

    return NextResponse.json({ message: 'Provider status updated', provider: updatedProvider });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update provider status' }, { status: 500 });
  }
}
