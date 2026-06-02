import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const provider = await prisma.provider.update({
      where: { id },
      data: { isVerified: true },
    });

    return NextResponse.json({ message: 'Provider approved successfully', provider });
  } catch (error) {
    console.error('Approval error:', error);
    return NextResponse.json({ error: 'Failed to approve provider' }, { status: 500 });
  }
}
