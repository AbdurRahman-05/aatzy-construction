import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    // In Next.js 15, route segment params are Promises
    const user = await prisma.user.update({
      where: { id },
      data: { isApproved: true },
    });

    return NextResponse.json({ message: 'User approved successfully', user });
  } catch (error) {
    console.error('Approval error:', error);
    return NextResponse.json({ error: 'Failed to approve user' }, { status: 500 });
  }
}
