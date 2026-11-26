/// Profit & loss maths for material orders - partner side only.
///
/// Everything is calculated **before GST**: GST is collected from the customer
/// and paid to the government, so it is never counted as income or profit.
library;

import '../models/material_order_models.dart';

class OrderProfit {
  /// Selling price × quantity (before GST).
  final double sales;

  /// Purchase cost × quantity + extra costs. Null when the partner has not entered a cost.
  final double? cost;

  /// Extra costs for the whole order (transport, loading, labour...).
  final double extraCost;

  /// GST the customer pays on top - shown separately, never profit.
  final double gst;

  /// Lowest price per unit that still covers every cost.
  final double? breakEvenPerUnit;

  const OrderProfit({
    required this.sales,
    required this.cost,
    required this.extraCost,
    required this.gst,
    required this.breakEvenPerUnit,
  });

  bool get known => cost != null;
  double? get profit => cost == null ? null : sales - cost!;
  bool get isLoss => (profit ?? 0) < 0;

  /// Profit as a % of sales (margin). Null when unknown or nothing sold.
  double? get marginPct => (profit == null || sales <= 0) ? null : profit! / sales * 100;

  static OrderProfit calculate({
    required double quantity,
    required double? pricePerUnit,
    required double? costPerUnit,
    double extraCost = 0,
    double gstPercent = 18,
  }) {
    final qty = quantity > 0 ? quantity : 1.0;
    final price = pricePerUnit ?? 0;
    final sales = price * qty;
    final hasCost = costPerUnit != null && costPerUnit > 0;
    final cost = hasCost ? costPerUnit * qty + extraCost : null;
    return OrderProfit(
      sales: sales,
      cost: cost,
      extraCost: extraCost,
      gst: sales * gstPercent / 100,
      breakEvenPerUnit: hasCost ? (costPerUnit * qty + extraCost) / qty : null,
    );
  }
}

/// Markup presets used to fill a selling price from the purchase cost.
const List<int> kMarkupPresets = [10, 15, 20, 25, 30];

double priceWithMarkup(double cost, int markupPct) => (cost * (1 + markupPct / 100) * 100).roundToDouble() / 100;

extension LeadProfit on LeadItem {
  /// Cost per unit for this order: the snapshot saved with the quote, else the product's cost.
  double? get effectiveUnitCost {
    if (unitCost != null && unitCost! > 0) return unitCost;
    if (productCost > 0) return productCost;
    return null;
  }

  OrderProfit get profit => OrderProfit.calculate(
        quantity: quantityVal,
        pricePerUnit: quotedPrice,
        costPerUnit: effectiveUnitCost,
        extraCost: extraCost,
        gstPercent: gstPercent,
      );

  bool get isClosedDeal => status == 'Completed' || (status == 'Closed' && deliveryStatus == 'Delivered');
  bool get isInProgress => status == 'Accepted' || (status == 'Closed' && deliveryStatus != 'Delivered');
}

/// Totals across many orders (closed deals, or orders still being delivered).
class ProfitSummary {
  final int orders;
  final int ordersWithCost;
  final double sales; // all orders, before GST
  final double salesWithCost; // only orders whose cost is known (for an honest margin)
  final double cost;
  final double profit;
  final int lossOrders;

  const ProfitSummary({
    required this.orders,
    required this.ordersWithCost,
    required this.sales,
    required this.salesWithCost,
    required this.cost,
    required this.profit,
    required this.lossOrders,
  });

  int get missingCost => orders - ordersWithCost;
  double? get marginPct => salesWithCost > 0 ? profit / salesWithCost * 100 : null;

  factory ProfitSummary.of(Iterable<LeadItem> leads) {
    var orders = 0, withCost = 0, losses = 0;
    double sales = 0, salesWithCost = 0, cost = 0, profit = 0;
    for (final l in leads) {
      if (l.quotedPrice == null || l.quotedPrice! <= 0) continue;
      final p = l.profit;
      orders++;
      sales += p.sales;
      if (p.known) {
        withCost++;
        salesWithCost += p.sales;
        cost += p.cost!;
        profit += p.profit!;
        if (p.isLoss) losses++;
      }
    }
    return ProfitSummary(
      orders: orders,
      ordersWithCost: withCost,
      sales: sales,
      salesWithCost: salesWithCost,
      cost: cost,
      profit: profit,
      lossOrders: losses,
    );
  }
}

/// One row of the per-product profit report.
class ProductProfitRow {
  final String name;
  int orders = 0;
  double sales = 0;
  double profit = 0;
  bool anyUnknown = false;
  ProductProfitRow(this.name);
  double? get marginPct => sales > 0 && !anyUnknown ? profit / sales * 100 : null;
}

List<ProductProfitRow> profitByProduct(Iterable<LeadItem> leads) {
  final map = <String, ProductProfitRow>{};
  for (final l in leads) {
    if (l.quotedPrice == null || l.quotedPrice! <= 0) continue;
    final key = l.requirementTitle.trim().isEmpty ? 'Other' : l.requirementTitle.trim();
    final row = map.putIfAbsent(key.toLowerCase(), () => ProductProfitRow(key));
    final p = l.profit;
    row.orders++;
    row.sales += p.sales;
    if (p.known) {
      row.profit += p.profit!;
    } else {
      row.anyUnknown = true;
    }
  }
  final rows = map.values.toList()..sort((a, b) => b.profit.compareTo(a.profit));
  return rows;
}

/// ₹ with Indian digit grouping. Handles negatives (losses) and keeps paise for small amounts.
String formatMoney(double value, {bool showSign = false}) {
  final negative = value < 0;
  final abs = value.abs();
  String body;
  if (abs < 1000 && abs != abs.roundToDouble()) {
    body = abs.toStringAsFixed(2);
  } else {
    final whole = abs.round().toString();
    if (whole.length <= 3) {
      body = whole;
    } else {
      final last3 = whole.substring(whole.length - 3);
      var rest = whole.substring(0, whole.length - 3);
      final groups = <String>[];
      while (rest.length > 2) {
        groups.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) groups.insert(0, rest);
      body = '${groups.join(',')},$last3';
    }
  }
  final sign = negative ? '-' : (showSign && value > 0 ? '+' : '');
  return '$sign₹$body';
}

String formatPct(double? pct) => pct == null ? '—' : '${pct.toStringAsFixed(pct.abs() >= 10 ? 0 : 1)}%';
