import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { OAuth2Client } from 'google-auth-library';

export async function POST(request: Request) {
  try {
    const { idToken } = await request.json();

    if (!idToken) {
      return NextResponse.json({ error: 'Missing idToken' }, { status: 400 });
    }

    let email: string | undefined;
    let name: string | undefined;

    // Handle mock token for web testing and development simulator
    if (idToken === 'mock_development_google_id_token' || idToken.startsWith('mock_')) {
      email = 'mock.provider@gmail.com';
      name = 'Mock Google Provider';
    }

    // Try verifying using Google Tokeninfo endpoint if not mock
    if (!email) {
      try {
        const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
        if (response.ok) {
          const payload = await response.json();
          email = payload.email;
          name = payload.name;
        }
      } catch (err) {
        console.warn('Google tokeninfo fetch failed, falling back to local verification:', err);
      }

      // Fallback: Verify locally using google-auth-library if CLIENT_ID is configured
      if (!email) {
        const client = new OAuth2Client();
        try {
          const ticket = await client.verifyIdToken({
            idToken: idToken,
            audience: process.env.GOOGLE_CLIENT_ID, 
          });
          const payload = ticket.getPayload();
          email = payload?.email;
          name = payload?.name;
        } catch (err) {
          console.error('Local token verification failed:', err);
        }
      }
    }

    if (!email) {
      return NextResponse.json({ error: 'Invalid Google ID Token' }, { status: 401 });
    }

    // Check if provider already exists
    let provider = await prisma.provider.findUnique({
      where: { email },
    });

    if (provider) {
      // Auto-verify provider signed in via Google to bypass admin approval permission
      if (!provider.isVerified) {
        provider = await prisma.provider.update({
          where: { email },
          data: { isVerified: true },
        });
      }

      return NextResponse.json({
        message: 'Login successful',
        exists: true,
        provider: {
          id: provider.id,
          businessName: provider.businessName,
          ownerName: provider.ownerName,
          email: provider.email,
          gstNumber: provider.gstNumber,
        },
      }, { status: 200 });
    } else {
      return NextResponse.json({
        message: 'Provider not found, proceed to registration',
        exists: false,
        email,
        name: name || email.split('@')[0],
      }, { status: 200 });
    }

  } catch (error) {
    console.error('Google provider login API error:', error);
    return NextResponse.json({ error: 'Failed to process Google login for provider' }, { status: 500 });
  }
}
