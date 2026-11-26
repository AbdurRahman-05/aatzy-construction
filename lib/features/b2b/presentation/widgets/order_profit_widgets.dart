/// Partner-only profit & loss widgets for material orders.
/// Nothing in this file is ever shown to customers.
library;

import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import '../../models/material_order_models.dart';
import '../../services/b2b_api_service.dart';
import '../../utils/order_profit.dart';

// -----------------------------------------------------------------------------
// 1. Inside the "Send quote" dialog
// -----------------------------------------------------------------------------

/// Purchase cost + extra costs + live profit / loss for the quote being written.
/// Styled for the (light) quote dialog.
class QuoteProfitPanel extends StatelessWidget {
  final LeadItem lead;
  final TextEditingController rateController;
  final TextEditingController costController;
  final TextEditingController extraController;
  final double gstPercent;
  final VoidCallback onChanged;

  const QuoteProfitPanel({
    super.key,
    required this.lead,
    required this.rateController,
    required this.costController,
    required this.extraController,
    required this.gstPercent,
    required this.onChanged,
  });

  static const _ink = Color(0xFF111318);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFECEAE6);

  @override
  Widget build(BuildContext context) {
    final rate = double.tryParse(rateController.text.trim()) ?? 0;
    final cost = double.tryParse(costController.text.trim());
    final extra = double.tryParse(extraController.text.trim()) ?? 0;
    final p = OrderProfit.calculate(
      quantity: lead.quantityVal,
      pricePerUnit: rate,
      costPerUnit: cost,
      extraCost: extra,
      gstPercent: gstPercent,
    );
    final qty = lead.quantityVal > 0 ? lead.quantityVal : 1.0;
    final belowBreakEven = p.breakEvenPerUnit != null && rate > 0 && rate < p.breakEvenPerUnit! - 0.004;
    final color = !p.known || rate <= 0 ? _muted : (p.isLoss ? Bento.red : Bento.green);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_rounded, size: 16, color: Color(0xFF0F766E)),
              SizedBox(width: 6),
              Expanded(
                child: Text('Your profit', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _ink)),
              ),
              Text('Only you see this', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field(costController, 'Purchase cost', '/ ${lead.unit}')),
              const SizedBox(width: 10),
              Expanded(child: _field(extraController, 'Extra costs', 'total', hint: 'Transport, loading')),
            ],
          ),

          // Markup shortcuts: fill the quoted rate from the cost
          if (cost != null && cost > 0) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kMarkupPresets.map((pct) {
                  // Spread extra costs over the units so the markup is on the full cost
                  final base = cost + (qty > 0 ? extra / qty : 0);
                  final target = priceWithMarkup(base, pct);
                  final selected = (rate - target).abs() < 0.01;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        rateController.text = target == target.roundToDouble() ? target.toStringAsFixed(0) : target.toStringAsFixed(2);
                        onChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF0D9488) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? const Color(0xFF0D9488) : _line),
                        ),
                        child: Text(
                          '+$pct%  ${formatMoney(target)}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : _ink),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          if (rate <= 0)
            const Text('Enter your rate above to see the profit on this order.', style: TextStyle(fontSize: 12, color: _muted))
          else if (!p.known)
            const Text(
              'Add your purchase cost to see profit or loss before you send the quote.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.35),
            )
          else ...[
            _row('Sales (${lead.quantity} × ${formatMoney(rate)})', formatMoney(p.sales)),
            _row('Purchase cost (${lead.quantity} × ${formatMoney(cost!)})', '- ${formatMoney(cost * qty)}'),
            if (extra > 0) _row('Extra costs', '- ${formatMoney(extra)}'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: _line)),
            Row(
              children: [
                Icon(p.isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded, size: 18, color: color),
                const SizedBox(width: 6),
                Text(p.isLoss ? 'Loss' : 'Profit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                const Spacer(),
                Text(formatMoney(p.profit!), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
                  child: Text(formatPct(p.marginPct),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
            if (belowBreakEven) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Bento.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Below break-even. Quote at least ${formatMoney(p.breakEvenPerUnit!)} / ${lead.unit} to cover your costs.',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'GST of ${formatMoney(p.gst)} is collected for the government - it is not counted as profit.',
              style: const TextStyle(fontSize: 10.5, color: _muted, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String suffix, {String? hint}) {
    return TextField(
      controller: c,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: _muted),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
        prefixText: '₹ ',
        suffixText: suffix,
        suffixStyle: const TextStyle(fontSize: 10.5, color: _muted),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12, color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink)),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// 2. On each partner order card
// -----------------------------------------------------------------------------

/// "Profit ₹1,200 · 14%" / "Loss ₹300" / "Add your cost" + an edit button.
class LeadProfitStrip extends StatelessWidget {
  final LeadItem lead;
  final VoidCallback onEditCosts;

  const LeadProfitStrip({super.key, required this.lead, required this.onEditCosts});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = lead.profit;
    final settled = lead.isClosedDeal;
    final word = settled ? (p.isLoss ? 'Loss' : 'Profit') : (p.isLoss ? 'Expected loss' : 'Expected profit');
    final color = !p.known ? Bento.muted(dark) : (p.isLoss ? Bento.red : Bento.green);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(Bento.radiusSm - 4),
      ),
      child: Row(
        children: [
          Icon(
            !p.known ? Icons.lock_outline_rounded : (p.isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded),
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: p.known
                ? Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '$word  '),
                      TextSpan(
                        text: formatMoney(p.profit!.abs()),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(text: '  ·  ${formatPct(p.marginPct)} margin', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                  )
                : Text(
                    'Add your cost to see the profit on this order',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bento.muted(dark)),
                  ),
          ),
          TextButton(
            onPressed: onEditCosts,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              foregroundColor: Bento.accentText(dark),
            ),
            child: Text(p.known ? 'Edit costs' : 'Add cost', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to enter / correct the costs on one order (any stage - e.g. once the
/// real transport bill is known). Returns true when saved.
Future<bool> showCostsEditorSheet(BuildContext context, LeadItem lead) async {
  String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final costC = TextEditingController(text: lead.effectiveUnitCost != null ? fmt(lead.effectiveUnitCost!) : '');
  final extraC = TextEditingController(text: lead.extraCost > 0 ? fmt(lead.extraCost) : '');
  var saving = false;
  String? error;

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      return StatefulBuilder(builder: (ctx, setSheet) {
        final cost = double.tryParse(costC.text.trim());
        final extra = double.tryParse(extraC.text.trim()) ?? 0;
        final p = OrderProfit.calculate(
          quantity: lead.quantityVal,
          pricePerUnit: lead.quotedPrice,
          costPerUnit: cost,
          extraCost: extra,
          gstPercent: lead.gstPercent,
        );
        final color = !p.known ? Bento.muted(dark) : (p.isLoss ? Bento.red : Bento.green);

        Future<void> save() async {
          if (cost == null || cost < 0) {
            setSheet(() => error = 'Enter your purchase cost per ${lead.unit}.');
            return;
          }
          setSheet(() {
            saving = true;
            error = null;
          });
          final res = await B2BApiService().put('/supplier/leads/${lead.id}/costs', data: {
            'unitCost': cost,
            'extraCost': extra,
          });
          if (res.success) {
            lead.unitCost = cost;
            lead.extraCost = extra;
            if (ctx.mounted) Navigator.pop(ctx, true);
          } else {
            setSheet(() {
              saving = false;
              error = (res.data is Map ? res.data['error'] : null)?.toString() ?? 'Could not save your costs.';
            });
          }
        }

        InputDecoration deco(String label, String suffix) => InputDecoration(
              labelText: label,
              prefixText: '₹ ',
              suffixText: suffix,
              filled: true,
              fillColor: Bento.surfaceAlt(dark),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            );

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Bento.surface(dark),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Bento.border(dark), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Your costs on this order',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Bento.text(dark))),
                  const SizedBox(height: 2),
                  Text(
                    '${lead.requirementTitle} · ${lead.quantity} · sold at ${formatMoney(lead.quotedPrice ?? 0)} / ${lead.unit}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: Bento.muted(dark)),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.lock_rounded, size: 13, color: Bento.accentText(dark)),
                    const SizedBox(width: 4),
                    Text('Private - the customer never sees this',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Bento.accentText(dark))),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costC,
                    autofocus: lead.effectiveUnitCost == null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setSheet(() {}),
                    decoration: deco('Purchase cost', 'per ${lead.unit}'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: extraC,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setSheet(() {}),
                    decoration: deco('Extra costs (transport, loading, labour)', 'total'),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: dark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: p.known
                        ? Row(
                            children: [
                              Icon(p.isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(p.isLoss ? 'Loss on this order' : 'Profit on this order',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                              ),
                              Text('${formatMoney(p.profit!)}  ·  ${formatPct(p.marginPct)}',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
                            ],
                          )
                        : Text('Enter your purchase cost to see profit or loss.',
                            style: TextStyle(fontSize: 12.5, color: Bento.muted(dark))),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Bento.red, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: saving
                        ? const Center(child: CircularProgressIndicator(color: Bento.accent))
                        : BentoButton(label: 'Save costs', icon: Icons.check_rounded, expand: true, onTap: save),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
  return saved ?? false;
}

// -----------------------------------------------------------------------------
// 3. Summary on top of "In progress" and "Closed"
// -----------------------------------------------------------------------------

enum ProfitPeriod { month, quarter, all }

extension on ProfitPeriod {
  String get label => switch (this) {
        ProfitPeriod.month => 'This month',
        ProfitPeriod.quarter => 'Last 3 months',
        ProfitPeriod.all => 'All time',
      };
}

bool _inPeriod(LeadItem l, ProfitPeriod period) {
  if (period == ProfitPeriod.all) return true;
  final d = DateTime.tryParse(l.finishedDate.isNotEmpty ? l.finishedDate : l.date);
  if (d == null) return false;
  final now = DateTime.now();
  if (period == ProfitPeriod.month) return d.year == now.year && d.month == now.month;
  return !d.isBefore(DateTime(now.year, now.month - 2, 1));
}

/// Net profit, sales, costs and margin across a set of orders.
/// [closed] = finished deals (with a period filter); otherwise = expected profit on orders in delivery.
class ProfitSummaryCard extends StatefulWidget {
  final List<LeadItem> leads;
  final bool closed;
  final VoidCallback? onOpenReport;

  const ProfitSummaryCard({super.key, required this.leads, required this.closed, this.onOpenReport});

  @override
  State<ProfitSummaryCard> createState() => _ProfitSummaryCardState();
}

class _ProfitSummaryCardState extends State<ProfitSummaryCard> {
  ProfitPeriod _period = ProfitPeriod.all;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final list = widget.closed ? widget.leads.where((l) => _inPeriod(l, _period)).toList() : widget.leads;
    final s = ProfitSummary.of(list);
    final loss = s.profit < 0;

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dark hero strip with the headline number
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: Bento.inkGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(Bento.radius)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.closed ? Icons.account_balance_wallet_rounded : Icons.hourglass_bottom_rounded,
                        size: 16, color: Bento.accentLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.closed ? 'PROFIT FROM CLOSED DEALS' : 'EXPECTED PROFIT ON ACTIVE ORDERS',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white70),
                      ),
                    ),
                    const Icon(Icons.lock_rounded, size: 13, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      s.ordersWithCost == 0 ? '—' : formatMoney(s.profit),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: s.ordersWithCost == 0 ? Colors.white : (loss ? const Color(0xFFFCA5A5) : Bento.accentLight),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (s.marginPct != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${formatPct(s.marginPct)} margin',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white70)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.closed) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ProfitPeriod.values.map((p) {
                        final sel = p == _period;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(p.label),
                            selected: sel,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _period = p),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: sel ? Colors.white : Bento.text(dark),
                            ),
                            selectedColor: Bento.accent,
                            backgroundColor: Bento.surfaceAlt(dark),
                            side: BorderSide(color: sel ? Bento.accent : Bento.border(dark)),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    _stat(dark, 'Sales', formatMoney(s.sales), 'before GST'),
                    _stat(dark, 'Costs', s.ordersWithCost == 0 ? '—' : formatMoney(s.cost), 'goods + extras'),
                    _stat(dark, 'Orders', '${s.orders}', s.lossOrders > 0 ? '${s.lossOrders} at a loss' : 'no losses'),
                  ],
                ),
                if (s.missingCost > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 15, color: Bento.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${s.missingCost} order${s.missingCost == 1 ? '' : 's'} without a cost ${s.missingCost == 1 ? 'is' : 'are'} not counted. Tap "Add cost" on ${s.missingCost == 1 ? 'it' : 'them'}.',
                          style: TextStyle(fontSize: 11.5, color: Bento.muted(dark), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.closed && widget.onOpenReport != null && widget.leads.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenReport,
                    icon: const Icon(Icons.insights_rounded, size: 17),
                    label: const Text('Profit by product & month', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Bento.accentText(dark),
                      side: BorderSide(color: Bento.border(dark)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(bool dark, String label, String value, String sub) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(color: Bento.surfaceAlt(dark), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Bento.muted(dark))),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Bento.text(dark))),
              ),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Bento.muted(dark))),
            ],
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// 4. Full report: last 6 months + per product
// -----------------------------------------------------------------------------

Future<void> showProfitReportSheet(BuildContext context, List<LeadItem> closedDeals) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProfitReport(leads: closedDeals),
  );
}

class _ProfitReport extends StatelessWidget {
  final List<LeadItem> leads;
  const _ProfitReport({required this.leads});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rows = profitByProduct(leads);

    // Profit per month for the last 6 months (orders with a known cost)
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));
    final monthProfit = List<double>.filled(6, 0);
    for (final l in leads) {
      final p = l.profit;
      if (!p.known) continue;
      final d = DateTime.tryParse(l.finishedDate.isNotEmpty ? l.finishedDate : l.date);
      if (d == null) continue;
      final idx = months.indexWhere((m) => m.year == d.year && m.month == d.month);
      if (idx >= 0) monthProfit[idx] += p.profit!;
    }
    final maxAbs = monthProfit.fold<double>(1, (m, v) => v.abs() > m ? v.abs() : m);
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: Bento.surface(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Bento.border(dark), borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Text('Profit report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Bento.text(dark))),
            Text('Closed material deals · before GST · only you see this',
                style: TextStyle(fontSize: 12, color: Bento.muted(dark))),
            const SizedBox(height: 18),

            Text('LAST 6 MONTHS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: Bento.muted(dark))),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (i) {
                  final v = monthProfit[i];
                  final h = (v.abs() / maxAbs * 100).clamp(v == 0 ? 2.0 : 6.0, 100.0);
                  final color = v < 0 ? Bento.red : Bento.accent;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            child: Text(v == 0 ? '' : formatMoney(v),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: v < 0 ? Bento.red : Bento.text(dark))),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: h.toDouble(),
                            decoration: BoxDecoration(
                              color: v == 0 ? Bento.border(dark) : color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(monthNames[months[i].month - 1],
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Bento.muted(dark))),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 22),

            Text('BY PRODUCT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: Bento.muted(dark))),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text('No priced orders yet.', style: TextStyle(color: Bento.muted(dark)))
            else
              ...rows.asMap().entries.map((e) {
                final r = e.value;
                final best = e.key == 0 && r.profit > 0;
                final color = r.anyUnknown && r.profit == 0 ? Bento.muted(dark) : (r.profit < 0 ? Bento.red : Bento.green);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Bento.surfaceAlt(dark),
                    borderRadius: BorderRadius.circular(16),
                    border: best ? Border.all(color: Bento.accent.withValues(alpha: 0.5)) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(
                                child: Text(r.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Bento.text(dark))),
                              ),
                              if (best) ...[
                                const SizedBox(width: 6),
                                const BentoPill(label: 'Top earner', color: Bento.accent, icon: Icons.emoji_events_rounded),
                              ],
                            ]),
                            const SizedBox(height: 2),
                            Text(
                              '${r.orders} order${r.orders == 1 ? '' : 's'} · sales ${formatMoney(r.sales)}${r.anyUnknown ? ' · some costs missing' : ''}',
                              style: TextStyle(fontSize: 11.5, color: Bento.muted(dark)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatMoney(r.profit), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: color)),
                          Text(formatPct(r.marginPct), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Bento.muted(dark))),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
