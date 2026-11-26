import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';
import '../../../core/services/location_service.dart';
import 'product_list_screen.dart' show formatRupees;

class InquiryFormScreen extends ConsumerStatefulWidget {
  final String? supplierId;
  final String? productId;
  final String? productName;
  final String? productImage;
  final String? supplierName;

  /// The product's own selling unit (e.g. "Bundle") - pre-selected in the form.
  final String? unit;

  /// Listed price per unit, used for the estimate only.
  final double? price;

  const InquiryFormScreen({
    super.key,
    this.supplierId,
    this.productId,
    this.productName,
    this.productImage,
    this.supplierName,
    this.unit,
    this.price,
  });

  @override
  ConsumerState<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends ConsumerState<InquiryFormScreen> {
  static const double _estimateGstPercent = 18;
  static const List<String> _standardUnits = [
    'Pieces', 'Bags', 'Bundles', 'Metric Tons', 'Kg', 'Meters', 'Sq. Ft', 'Liters', 'Cubic Meters', 'Loads',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  final _locController = TextEditingController();
  late final List<String> _units;
  late String _selectedUnit;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.productName != null ? 'Requirement for ${widget.productName}' : '',
    );

    final productUnit = widget.unit?.trim();
    _units = [
      if (productUnit != null && productUnit.isNotEmpty) productUnit,
      ..._standardUnits.where((u) => u.toLowerCase() != productUnit?.toLowerCase()),
    ];
    _selectedUnit = _units.first;

    _qtyController.addListener(() => setState(() {}));
    LocationService().getSavedLocation().then((loc) {
      if (mounted && loc.isNotEmpty && _locController.text.isEmpty) {
        _locController.text = loc;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _locController.dispose();
    super.dispose();
  }

  /// The estimate only makes sense in the product's own unit.
  bool get _canEstimate =>
      (widget.price ?? 0) > 0 &&
      widget.unit != null &&
      _selectedUnit.toLowerCase() == widget.unit!.trim().toLowerCase();

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to request a quote')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await B2BApiService().post('/buyer/inquiries', data: {
        'buyerId': auth.id,
        'supplierId': widget.supplierId,
        'productId': widget.productId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'quantity': double.parse(_qtyController.text.trim()),
        'unit': _selectedUnit,
        'location': _locController.text.trim(),
        'images': (widget.productImage != null && widget.productImage!.isNotEmpty) ? [widget.productImage] : [],
      });

      if (!mounted) return;
      if (res.success) {
        await _showSuccessSheet();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['error'] ?? 'Failed to send your request')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send your request. Check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccessSheet() async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            color: Bento.surface(dark),
            borderRadius: BorderRadius.circular(Bento.radius + 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BentoIconBubble(icon: Icons.check_rounded, color: Bento.green, size: 64),
              const SizedBox(height: 14),
              Text('Request sent!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Bento.text(dark))),
              const SizedBox(height: 6),
              Text(
                '${widget.supplierName?.isNotEmpty == true ? widget.supplierName : 'The supplier'} will review it and send you a quote. '
                'We\'ll notify you as soon as it arrives.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.45, color: Bento.muted(dark)),
              ),
              const SizedBox(height: 20),
              BentoButton(
                label: 'Track my request',
                icon: Icons.receipt_long_rounded,
                expand: true,
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) context.pushReplacement('/b2b-my-inquiries');
  }

  InputDecoration _input(String label, {String? hint, IconData? icon, bool dark = false}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Bento.muted(dark)) : null,
      filled: true,
      fillColor: Bento.surfaceAlt(dark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Bento.border(dark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Bento.accent, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    final subtotal = qty * (widget.price ?? 0);
    final gst = subtotal * _estimateGstPercent / 100;

    return Scaffold(
      appBar: BentoAppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Get a quote'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (widget.productName != null)
              BentoCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const BentoIconBubble(icon: Icons.inventory_2_rounded, color: Bento.accent, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Bento.text(dark)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (widget.supplierName?.isNotEmpty == true) widget.supplierName!,
                              if ((widget.price ?? 0) > 0) '${formatRupees(widget.price!)} / ${widget.unit ?? 'unit'}',
                            ].join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Bento.gap),

            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('How much do you need?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Bento.text(dark))),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: _input('Quantity', hint: 'e.g. 100', dark: dark),
                          validator: (value) {
                            final v = double.tryParse(value?.trim() ?? '');
                            return v == null || v <= 0 ? 'Enter a quantity' : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedUnit,
                          decoration: _input('Unit', dark: dark),
                          items: _units
                              .map((unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUnit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_canEstimate && qty > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Bento.accent.withValues(alpha: dark ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(Bento.radiusSm),
                        border: Border.all(color: Bento.accent.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        children: [
                          _estimateRow('Material (${_trimNumber(qty)} × ${formatRupees(widget.price!)})', formatRupees(subtotal), dark),
                          const SizedBox(height: 6),
                          _estimateRow('GST (about ${_estimateGstPercent.toStringAsFixed(0)}%)', formatRupees(gst), dark),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Bento.accent.withValues(alpha: 0.25)),
                          ),
                          _estimateRow('Estimated total', formatRupees(subtotal + gst), dark, bold: true),
                          const SizedBox(height: 8),
                          Text(
                            'Estimate from the listed price. The supplier confirms the final price, GST and delivery in the quote.',
                            style: TextStyle(fontSize: 11, height: 1.35, color: Bento.muted(dark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Bento.gap),

            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Details for the supplier',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Bento.text(dark))),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: _input('Title', icon: Icons.title_rounded, dark: dark),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Add a short title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: _input(
                      'Requirement',
                      hint: 'Brand / grade / size, when you need it, site access…',
                      dark: dark,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Tell the supplier what you need' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locController,
                    decoration: _input('Delivery location', hint: 'e.g. Anna Nagar, Madurai', icon: Icons.location_on_rounded, dark: dark),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Where should it be delivered?' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: _submitting
                ? const Center(child: CircularProgressIndicator(color: Bento.accent))
                : BentoButton(
                    label: 'Send request',
                    icon: Icons.send_rounded,
                    expand: true,
                    onTap: _submitInquiry,
                  ),
          ),
        ),
      ),
    );
  }

  String _trimNumber(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Widget _estimateRow(String label, String value, bool dark, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? Bento.text(dark) : Bento.muted(dark),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 17 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: bold ? Bento.accentText(dark) : Bento.text(dark),
          ),
        ),
      ],
    );
  }
}
