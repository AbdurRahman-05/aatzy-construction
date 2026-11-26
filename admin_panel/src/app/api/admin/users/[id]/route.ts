import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { requireAdmin } from '@/lib/auth';
import { userDeleteImpact } from '@/lib/adminImpact';

/** Customer profile for the admin side panel. */
export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const notAdmin = await requireAdmin();
    if (notAdmin) return notAdmin;

    const { id } = await context.params;
    const url = new URL(request.url);

    if (url.searchParams.get('impact') === '1') {
      const exists = await prisma.user.findUnique({ where: { id }, select: { id: true } });
      if (!exists) return NextResponse.json({ error: 'Customer not found' }, { status: 404 });
      return NextResponse.json({ impact: await userDeleteImpact(id) });
    }

    const u = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true, name: true, email: true, phone: true, role: true, isApproved: true,
        profileImage: true, createdAt: true, updatedAt: true,
        projects: {
          select: {
            id: true, title: true, type: true, location: true, budget: true, currentStage: true, createdAt: true,
            quotes: { where: { isAccepted: true }, select: { provider: { select: { id: true, businessName: true } } } },
            _count: { select: { quotes: true } },
          },
          orderBy: { createdAt: 'desc' },
        },
        inquiries: {
          select: { id: true, title: true, status: true, quantity: true, unit: true, quotedPrice: true, createdAt: true, provider: { select: { businessName: true } } },
          orderBy: { createdAt: 'desc' },
          take: 8,
        },
        _count: { select: { inquiries: true, reviews: true } },
      },
    });
    if (!u) return NextResponse.json({ error: 'Customer not found' }, { status: 404 });

    return NextResponse.json({
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      role: u.role,
      isApproved: u.isApproved,
      profileImage: u.profileImage,
      createdAt: u.createdAt.toISOString(),
      updatedAt: u.updatedAt.toISOString(),
      stats: {
        projects: u.projects.length,
        budget: u.projects.reduce((s, p) => s + (p.budget || 0), 0),
        orders: u._count.inquiries,
        reviews: u._count.reviews,
      },
      projects: u.projects.map(p => ({
        id: p.id,
        title: p.title,
        type: p.type,
        location: p.location,
        budget: p.budget,
        stage: p.currentStage,
        createdAt: p.createdAt.toISOString(),
        quotes: p._count.quotes,
        partner: p.quotes[0]?.provider ?? null,
      })),
      orders: u.inquiries.map(i => ({
        id: i.id,
        title: i.title,
        status: i.status,
        quantity: i.quantity,
        unit: i.unit,
        quotedPrice: i.quotedPrice,
        supplier: i.provider?.businessName ?? '',
        createdAt: i.createdAt.toISOString(),
      })),
    });
  } catch (error) {
    console.error('Admin user detail error:', error);
    return NextResponse.json({ error: 'Failed to load customer' }, { status: 500 });
  }
}
