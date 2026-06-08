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
      email = 'mock.user@gmail.com';
      name = 'Mock Google User';
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
            // If GOOGLE_CLIENT_ID is defined in .env, verify against it
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

    // Check if user already exists
    let user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      // Register new user (Consumer)
      user = await prisma.user.create({
        data: {
          email,
          name: name || email.split('@')[0],
          password: `google_oauth_placeholder_${Math.random().toString(36).substring(7)}`,
          role: 'CONSUMER',
          isApproved: true,
        },
      });
    }

    return NextResponse.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    }, { status: 200 });

  } catch (error) {
    console.error('Google login API error:', error);
    return NextResponse.json({ error: 'Failed to process Google login' }, { status: 500 });
  }
}
