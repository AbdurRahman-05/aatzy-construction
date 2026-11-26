import 'package:flutter_test/flutter_test.dart';
import 'package:construction_app/features/b2b/models/material_order_models.dart';
import 'package:construction_app/features/b2b/utils/order_profit.dart';

LeadItem lead({
  double qty = 100,
  double? price = 420,
  double? unitCost,
  double extra = 0,
  double productCost = 0,
  String status = 'Completed',
  String delivery = 'Delivered',
  String title = 'Cement',
  String finished = '2026-11-20',
}) =>
    LeadItem(
      id: 'x',
      date: '2026-11-01',
      buyerName: 'B',
      buyerPhone: '',
      buyerEmail: '',
      requirementTitle: title,
      requirementDesc: '',
      quantity: '$qty Bag',
      quantityVal: qty,
      unit: 'Bag',
      location: '',
      status: status,
      quotedPrice: price,
      deliveryStatus: delivery,
      gstPercent: 18,
      productCost: productCost,
      unitCost: unitCost,
      extraCost: extra,
      images: const [],
      finishedDate: finished,
    );

void main() {
  test('profit = sales - (cost x qty) - extra costs, GST excluded', () {
    final p = OrderProfit.calculate(quantity: 100, pricePerUnit: 420, costPerUnit: 380, extraCost: 1500, gstPercent: 18);
    expect(p.sales, 42000);
    expect(p.cost, 38000 + 1500);
    expect(p.profit, 2500);
    expect(p.gst, closeTo(7560, 0.001));
    expect(p.marginPct, closeTo(2500 / 42000 * 100, 0.0001));
    expect(p.breakEvenPerUnit, 395); // (38000 + 1500) / 100
    expect(p.isLoss, isFalse);
  });

  test('selling below cost is a loss', () {
    final p = OrderProfit.calculate(quantity: 10, pricePerUnit: 90, costPerUnit: 100);
    expect(p.profit, -100);
    expect(p.isLoss, isTrue);
  });

  test('unknown cost gives no profit instead of a fake 100% margin', () {
    final p = OrderProfit.calculate(quantity: 10, pricePerUnit: 90, costPerUnit: null);
    expect(p.known, isFalse);
    expect(p.profit, isNull);
    expect(p.marginPct, isNull);
  });

  test('order cost snapshot wins over the product cost', () {
    expect(lead(unitCost: 400, productCost: 350).effectiveUnitCost, 400);
    expect(lead(productCost: 350).effectiveUnitCost, 350);
    expect(lead().effectiveUnitCost, isNull);
  });

  test('summary counts only orders with a cost in profit and margin', () {
    final s = ProfitSummary.of([
      lead(unitCost: 400), // profit 2000 on 42000
      lead(unitCost: 430), // loss -1000 on 42000
      lead(), // no cost - excluded from profit
      lead(price: null), // no quote - ignored
    ]);
    expect(s.orders, 3);
    expect(s.ordersWithCost, 2);
    expect(s.missingCost, 1);
    expect(s.sales, 126000);
    expect(s.profit, 1000);
    expect(s.lossOrders, 1);
    expect(s.marginPct, closeTo(1000 / 84000 * 100, 0.0001));
  });

  test('profit by product groups by name and sorts best first', () {
    final rows = profitByProduct([
      lead(title: 'Cement', unitCost: 400),
      lead(title: 'cement ', unitCost: 410),
      lead(title: 'Sand', unitCost: 300),
    ]);
    expect(rows.first.name, 'Sand');
    expect(rows.first.profit, 12000);
    expect(rows[1].orders, 2);
    expect(rows[1].profit, 2000 + 1000);
  });

  test('markup and money formatting', () {
    expect(priceWithMarkup(380, 15), 437);
    expect(formatMoney(-1500), '-₹1,500');
    expect(formatMoney(125000), '₹1,25,000');
    expect(formatMoney(4.5), '₹4.50');
    expect(formatPct(5.95), '6.0%');
    expect(formatPct(12.4), '12%');
  });
}
