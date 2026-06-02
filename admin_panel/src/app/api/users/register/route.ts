import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request) {
  try {
    const { name, email, password, role } = await request.json();

    if (!name || !email || !password) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return NextResponse.json({ error: 'User already exists' }, { status: 400 });
    }

    // Default to false (Admin approval required)
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password, // In a real app, hash the password using bcrypt
        role: role || 'CONSUMER',
        isApproved: false, 
      },
    });

    return NextResponse.json({ 
      message: 'Registration successful! Please wait for admin approval.',
      user: { id: user.id, email: user.email, isApproved: user.isApproved }
    }, { status: 201 });
    
  } catch (error) {
    console.error('Register error:', error);
    return NextResponse.json({ error: 'Failed to register' }, { status: 500 });
  }
}
