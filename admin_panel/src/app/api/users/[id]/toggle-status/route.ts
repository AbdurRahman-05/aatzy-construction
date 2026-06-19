import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendApprovalEmail } from '@/lib/mail';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return NextResponse.json({ error: 'User not found' }, { status: 404 });

    const newStatus = !user.isApproved;
    const updatedUser = await prisma.user.update({
      where: { id },
      data: { isApproved: newStatus },
    });

    // If toggled from false to true, send approval email
    if (newStatus) {
      sendApprovalEmail(updatedUser.email, updatedUser.name, 'CONSUMER').catch(err => {
        console.error('User approval email error (toggle):', err);
      });
    }

    return NextResponse.json({ message: 'User status updated', user: updatedUser });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update user status' }, { status: 500 });
  }
}
