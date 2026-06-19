import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendWelcomeEmail } from '@/lib/mail';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { 
      businessName, ownerName, email, password, phone, category, experience,
      address, bio, aadharCard, panCard, profileCompletion 
    } = body;

    if (!email || !password || !businessName) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Check if provider already exists
    const existingProvider = await prisma.provider.findUnique({
      where: { email },
    });

    if (existingProvider) {
      return NextResponse.json({ error: 'Provider with this email already exists' }, { status: 400 });
    }

    // Default to false (Admin approval required)
    const provider = await prisma.provider.create({
      data: {
        businessName,
        ownerName: ownerName || '',
        email,
        password, // In a real app, hash this
        phone: phone || '',
        category: category || 'General',
        experience: experience ? parseInt(experience) : 0,
        address: address || null,
        bio: bio || null,
        aadharCard: aadharCard || null,
        panCard: panCard || null,
        profileCompletion: profileCompletion ? parseInt(profileCompletion) : 0,
        isVerified: false, 
      },
    });

    // Send welcome email asynchronously
    sendWelcomeEmail(provider.email, provider.ownerName || provider.businessName, 'PROVIDER').catch(err => {
      console.error('Welcome email send error:', err);
    });

    return NextResponse.json({ 
      message: 'Registration successful! Please wait for admin approval.',
      provider: { id: provider.id, email: provider.email, isVerified: provider.isVerified }
    }, { status: 201 });
    
  } catch (error) {
    console.error('Provider Register error:', error);
    return NextResponse.json({ error: 'Failed to register provider' }, { status: 500 });
  }
}
