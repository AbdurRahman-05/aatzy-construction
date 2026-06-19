import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendApprovalEmail } from '@/lib/mail';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const provider = await prisma.provider.findUnique({ where: { id } });
    if (!provider) return NextResponse.json({ error: 'Provider not found' }, { status: 404 });

    const newStatus = !provider.isVerified;
    const updatedProvider = await prisma.provider.update({
      where: { id },
      data: { isVerified: newStatus },
    });

    // If toggled from false to true, send approval email
    if (newStatus) {
      sendApprovalEmail(updatedProvider.email, updatedProvider.ownerName || updatedProvider.businessName, 'PROVIDER').catch(err => {
        console.error('Provider approval email error (toggle):', err);
      });
    }

    return NextResponse.json({ message: 'Provider status updated', provider: updatedProvider });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update provider status' }, { status: 500 });
  }
}
