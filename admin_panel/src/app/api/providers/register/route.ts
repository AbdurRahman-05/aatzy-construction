import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendProviderWelcomeEmail } from '@/lib/mail';
import { isAuthEnforced, isValidPhoneVerificationToken } from '@/lib/auth';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      businessName, ownerName, email, password, phone, category, experience,
      address, bio, aadharCard, panCard, portfolioImage, portfolioImages,
      profileCompletion, isGoogleSignUp, phoneVerificationToken,
    } = body;

    if (!email || !password || !businessName || !phone) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Phone must be OTP-verified (same as consumer registration).
    // The app gets `phoneVerificationToken` from /api/auth/verify-otp.
    if (phoneVerificationToken) {
      if (!isValidPhoneVerificationToken(phoneVerificationToken, phone)) {
        return NextResponse.json(
          { error: 'Phone verification expired or does not match this number. Please verify your phone again.', code: 'PHONE_NOT_VERIFIED' },
          { status: 400 }
        );
      }
    } else if (isAuthEnforced()) {
      return NextResponse.json(
        { error: 'Please verify your phone number with OTP before registering.', code: 'PHONE_NOT_VERIFIED' },
        { status: 400 }
      );
    } else {
      // Older app versions (no OTP proof) are still allowed until AUTH_ENFORCE=true
      console.warn(`[providers/register] Legacy registration without phone verification for ${email}`);
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

    // Save uploaded portfolio image(s) from registration
    const incomingPortfolio: string[] = [];
    if (typeof portfolioImage === 'string' && portfolioImage.trim().length > 0) {
      incomingPortfolio.push(portfolioImage.trim());
    }
    if (Array.isArray(portfolioImages)) {
      for (const img of portfolioImages) {
        if (typeof img === 'string' && img.trim().length > 0) {
          incomingPortfolio.push(img.trim());
        } else if (img && typeof img.imageData === 'string' && img.imageData.trim().length > 0) {
          incomingPortfolio.push(img.imageData.trim());
        }
      }
    }
    if (incomingPortfolio.length > 0) {
      await prisma.portfolioImage.createMany({
        data: incomingPortfolio.map((imageData, idx) => ({
          providerId: provider.id,
          title: incomingPortfolio.length > 1 ? `Project Showcase ${idx + 1}` : 'Project Showcase',
          description: 'Uploaded during partner registration',
          imageData,
        })),
      });
    }

    // Send welcome email with details asynchronously
    sendProviderWelcomeEmail(provider).catch(err => {
      console.error('Welcome email send error:', err);
    });

    return NextResponse.json({ 
      message: 'Registration successful!',
      provider: { 
        id: provider.id, 
        businessName: provider.businessName, 
        ownerName: provider.ownerName, 
        email: provider.email, 
        gstNumber: provider.gstNumber,
        isVerified: provider.isVerified 
      }
    }, { status: 201 });
    
  } catch (error) {
    console.error('Provider Register error:', error);
    return NextResponse.json({ error: 'Failed to register provider' }, { status: 500 });
  }
}
