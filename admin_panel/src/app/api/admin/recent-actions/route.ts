import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { getRecentActions } from '@/lib/recentActions';

export const dynamic = 'force-dynamic';

export async function GET(req: Request) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

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
