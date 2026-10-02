import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { getRecentActions } from '@/lib/recentActions';

export const dynamic = 'force-dynamic';

export async function GET(req: Request) {
  try {
    const cookieStore = await cookies();
    const adminSession = cookieStore.get('admin_session')?.value;
    const correctPassword = process.env.ADMIN_PASSWORD || 'admin123';

    if (adminSession !== correctPassword) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(req.url);
    const limitParam = searchParams.get('limit');
    const limit = limitParam ? parseInt(limitParam, 10) : 50;

    const actions = await getRecentActions(limit);

    return NextResponse.json({
      success: true,
      actions,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Failed to fetch recent actions:', error);
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}
