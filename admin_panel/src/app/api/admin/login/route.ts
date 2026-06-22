import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { password } = await request.json();
    const correctPassword = process.env.ADMIN_PASSWORD || 'admin123';

    if (!password) {
      return NextResponse.json({ error: 'Password is required' }, { status: 400 });
    }

    if (password !== correctPassword) {
      return NextResponse.json({ error: 'Incorrect administrator password' }, { status: 401 });
    }

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Admin login API error:', error);
    return NextResponse.json({ error: 'Failed to process admin login' }, { status: 500 });
  }
}
