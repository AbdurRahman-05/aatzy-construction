import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendApprovalEmail } from '@/lib/mail';
import { requireAdmin } from '@/lib/auth';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    
    const provider = await prisma.provider.update({
      where: { id },
      data: { isVerified: true, isRejected: false },
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
