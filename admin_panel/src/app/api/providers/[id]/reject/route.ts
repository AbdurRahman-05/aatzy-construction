import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const provider = await prisma.provider.update({
      where: { id },
      data: { 
        isRejected: true,
        isVerified: false 
      },
    });

    return NextResponse.json({ message: 'Provider rejected successfully', provider });
  } catch (error) {
    console.error('Rejection error:', error);
    return NextResponse.json({ error: 'Failed to reject provider' }, { status: 500 });
  }
}
