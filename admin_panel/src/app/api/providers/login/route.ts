import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request) {
  try {
    const { email, password } = await request.json();

    if (!email || !password) {
      return NextResponse.json({ error: 'Missing email or password' }, { status: 400 });
    }

    const provider = await prisma.provider.findUnique({
      where: { email },
    });

    if (!provider || provider.password !== password) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    if (!provider.isVerified) {
      return NextResponse.json({ 
        error: 'Approval Pending', 
        message: 'Your provider account is currently under review by an admin. Please wait for approval before logging in.'
      }, { status: 403 });
    }

    return NextResponse.json({ 
      message: 'Login successful',
      provider: { 
        id: provider.id, 
        businessName: provider.businessName, 
        ownerName: provider.ownerName,
        email: provider.email 
      }
    }, { status: 200 });

  } catch (error) {
    console.error('Provider Login error:', error);
    return NextResponse.json({ error: 'Failed to login' }, { status: 500 });
  }
}
