import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendApprovalEmail } from '@/lib/mail';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const provider = await prisma.provider.update({
      where: { id },
      data: { isVerified: true },
    });

    // Send approval email asynchronously
    sendApprovalEmail(provider.email, provider.ownerName || provider.businessName, 'PROVIDER').catch(err => {
      console.error('Provider approval email error:', err);
    });

    return NextResponse.json({ message: 'Provider approved successfully', provider });
  } catch (error) {
    console.error('Approval error:', error);
    return NextResponse.json({ error: 'Failed to approve provider' }, { status: 500 });
  }
}
