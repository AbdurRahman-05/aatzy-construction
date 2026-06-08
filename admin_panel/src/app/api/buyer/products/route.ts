import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('categoryId') || searchParams.get('category');
    const query = searchParams.get('query');
    const location = searchParams.get('location');

    let products = await prisma.product.findMany({
      where: {
        deletedAt: null,
        status: 'Approved',
      },
      include: {
        provider: {
          select: {
            businessName: true,
            address: true,
            isVerified: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Seed sample products if none exist
    if (products.length === 0) {
      let provider = await prisma.provider.findFirst();
      if (!provider) {
        // Create a default mock provider to host products
        provider = await prisma.provider.create({
          data: {
            businessName: 'UltraTech Build Solutions',
            ownerName: 'Rajesh Kumar',
            email: 'rajesh@ultratech.com',
            password: 'password_hash_dummy',
            phone: '+919876543210',
            category: 'Materials & Supply',
            experience: 12,
            address: 'Mumbai, Maharashtra',
            bio: 'Leading manufacturer of structural cement and concrete solutions in India.',
            isVerified: true,
          },
        });
      }

      await prisma.product.createMany({
        data: [
          {
            providerId: provider.id,
            category: 'Materials & Supply',
            name: 'UltraTech Premium Cement',
            description: 'High-strength Portland Pozzolana Cement (PPC) ideal for structural concrete, plastering, and brickwork.',
            images: ['https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400'],
            pricePerUnit: 420.00,
            unitType: 'Bag',
            costPrice: 310.00,
            status: 'Approved',
          },
          {
            providerId: provider.id,
            category: 'Materials & Supply',
            name: 'Tata Tiscon TMT Steel Rebar (12mm)',
            description: 'Fe 550D grade high-strength thermo-mechanically treated steel reinforcement bars for high-rise slabs and foundations.',
            images: ['https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&q=80&w=400'],
            pricePerUnit: 58000.00,
            unitType: 'Ton',
            costPrice: 49000.00,
            status: 'Approved',
          },
          {
            providerId: provider.id,
            category: 'Materials & Supply',
            name: 'Red Clay Bricks (Class I)',
            description: 'Premium quality kiln-burnt clay bricks with high crushing strength and low water absorption.',
            images: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400'],
            pricePerUnit: 7.50,
            unitType: 'Piece',
            costPrice: 5.00,
            status: 'Approved',
          },
          {
            providerId: provider.id,
            category: 'Materials & Supply',
            name: 'Vitrified Floor Tiles (600x600mm)',
            description: 'Double charged glossy finish vitrified floor tiles, scratch-resistant and highly durable.',
            images: ['https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&q=80&w=400'],
            pricePerUnit: 45.00,
            unitType: 'Sq Ft',
            costPrice: 32.00,
            status: 'Approved',
          },
        ],
      });

      products = await prisma.product.findMany({
        where: {
          deletedAt: null,
          status: 'Approved',
        },
        include: {
          provider: {
            select: {
              businessName: true,
              address: true,
              isVerified: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });
    }

    // Apply code-level filtering
    let filtered = products;

    if (category && category !== 'All') {
      filtered = filtered.filter(p =>
        p.category?.toLowerCase().includes(category.toLowerCase())
      );
    }

    if (location && location !== 'All India') {
      filtered = filtered.filter(p =>
        p.provider.address?.toLowerCase().includes(location.toLowerCase())
      );
    }

    if (query) {
      const q = query.toLowerCase();
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        p.provider.businessName.toLowerCase().includes(q)
      );
    }

    // Map properties to match what Flutter expects
    const formatted = filtered.map(p => ({
      id: p.id,
      name: p.name,
      description: p.description,
      price_per_unit: p.pricePerUnit,
      unit_type: p.unitType,
      images: p.images,
      company_name: p.provider.businessName,
      location: p.provider.address || 'All India',
      category: p.category,
    }));

    return NextResponse.json({ success: true, products: formatted });
  } catch (error) {
    console.error('Fetch products list error:', error);
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 });
  }
}
