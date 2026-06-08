import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET() {
  try {
    let news = await prisma.materialNews.findMany({
      orderBy: { publishedAt: 'desc' },
    });

    if (news.length === 0) {
      // Seed default mock news
      await prisma.materialNews.createMany({
        data: [
          {
            title: 'Steel prices surge 5% in Indian retail markets',
            content: 'Retail prices for TMT steel rebars have surged across major metro hubs due to increased raw iron ore costs and seasonal infrastructure spikes.',
            category: 'Steel',
          },
          {
            title: 'Monsoon season prompts cement price reductions',
            content: 'In anticipation of the construction slowdown during heavy rains, top manufacturers like UltraTech and ACC have revised rates downward.',
            category: 'Cement',
          },
          {
            title: 'Green building guidelines: Mandatory fly-ash usage',
            content: 'The Ministry of Housing has released guidelines making fly-ash brick blends mandatory for new government-sponsored housing blocks.',
            category: 'Policy',
          },
        ],
      });
      news = await prisma.materialNews.findMany({
        orderBy: { publishedAt: 'desc' },
      });
    }

    return NextResponse.json({ success: true, news });
  } catch (error) {
    console.error('Fetch news error:', error);
    return NextResponse.json({ error: 'Failed to fetch news' }, { status: 500 });
  }
}
