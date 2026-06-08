import { NextResponse } from 'next/server';

export async function GET() {
  const clientId = process.env.GOOGLE_CLIENT_ID || '';
  return NextResponse.json({ clientId });
}
