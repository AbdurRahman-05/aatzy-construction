import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type') || 'ledger'; // 'tax' or 'ledger'

    const inquiries = await prisma.inquiry.findMany({
      where: {
        providerId: id,
        status: 'Closed',
      },
      include: {
        buyer: { select: { name: true } },
        product: { select: { name: true, costPrice: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });

    let csvContent = '';

    if (type === 'tax') {
      csvContent = 'Date,Buyer Name,Product/Service,Quantity,Unit,Quoted Price (INR),Taxable Value (INR),GST %,GST Amount (INR),Total Billing (INR)\n';
      for (const r of inquiries) {
        const dateStr = r.updatedAt.toISOString().split('T')[0];
        const name = r.product?.name || r.title || 'Inquiry';
        const qty = r.quantity || 0;
        const price = r.quotedPrice || 0;
        const gstPercent = r.gstPercent || 18.0;
        const taxable = qty * price;
        const gstAmount = taxable * (gstPercent / 100);
        const total = taxable + gstAmount;

        csvContent += `"${dateStr}","${r.buyer.name}","${name.replace(/"/g, '""')}",${qty},"${r.unit}",${price},${taxable.toFixed(2)},${gstPercent},${gstAmount.toFixed(2)},${total.toFixed(2)}\n`;
      }
    } else {
      // default: ledger
      csvContent = 'Date,Transaction ID,Buyer Name,Product/Service,Quantity,Revenue (INR),COGS (INR),Net Profit (INR),Margin %\n';
      for (const r of inquiries) {
        const dateStr = r.updatedAt.toISOString().split('T')[0];
        const name = r.product?.name || r.title || 'Inquiry';
        const qty = r.quantity || 0;
        const price = r.quotedPrice || 0;
        const cost = r.product?.costPrice || 310.00;
        const revenue = qty * price;
        const cogs = qty * cost;
        const profit = revenue - cogs;
        const margin = revenue > 0 ? ((profit / revenue) * 100).toFixed(1) : '0.0';

        csvContent += `"${dateStr}","${r.id}","${r.buyer.name}","${name.replace(/"/g, '""')}",${qty},${revenue.toFixed(2)},${cogs.toFixed(2)},${profit.toFixed(2)},${margin}\n`;
      }
    }

    return new Response(csvContent, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': `attachment; filename=buildmart_${type}_report.csv`,
      },
    });
  } catch (error) {
    console.error('Export report error:', error);
    return NextResponse.json({ error: 'Failed to export report' }, { status: 500 });
  }
}
