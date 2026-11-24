import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    status: 'online',
    message: 'Connectzy Construction API is operational',
    timestamp: new Date().toISOString(),
  });
}
