/// Data models for material orders (B2B inquiries), shared by the customer
/// ("My orders") and partner ("Leads") views of the materials screen.
library;

String _dateOnly(dynamic value) => value == null ? '' : value.toString().split('T')[0];

String _formatQty(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

double? _toDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());

/// A material request as seen by the customer who sent it.
class InquiryModel {
  final String id;
  final String date;
  final String supplierId;
  final String supplierName;
  final String productName;
  final String productImage;
  final double quantityVal;
  final String unit;
  final String quantity;
  final String location;
  final String status;
  final double? quotedPrice;
  final String deliveryStatus;
  final double gstPercent;
  final int? rating;
  final String? reviewText;
  final List<String> images;
  final String finishedDate;

  InquiryModel({
    required this.id,
    required this.date,
    this.supplierId = '',
    required this.supplierName,
    required this.productName,
    this.productImage = '',
    required this.quantityVal,
    this.unit = 'Units',
    required this.quantity,
    this.location = '',
    required this.status,
    this.quotedPrice,
    required this.deliveryStatus,
    required this.gstPercent,
    this.rating,
    this.reviewText,
    required this.images,
    required this.finishedDate,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    final qtyVal = _toDouble(json['quantity']) ?? 0.0;
    final unit = json['unit']?.toString() ?? 'Units';
    return InquiryModel(
      id: json['id'] ?? '',
      date: _dateOnly(json['created_at']),
      supplierId: json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name'] ?? 'Supplier',
      productName: json['product_name'] ?? json['title'] ?? 'Material request',
      productImage: json['product_image']?.toString() ?? '',
      quantityVal: qtyVal,
      unit: unit,
      quantity: '${_formatQty(qtyVal)} $unit',
      location: json['location']?.toString() ?? '',
      status: json['status'] ?? 'New',
      quotedPrice: _toDouble(json['quoted_price']),
      deliveryStatus: json['delivery_status'] ?? 'Pending',
      gstPercent: _toDouble(json['gst_percent']) ?? 18.0,
      rating: json['rating'] != null ? int.tryParse(json['rating'].toString()) : null,
      reviewText: json['review_text'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      finishedDate: _dateOnly(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

/// A material request as seen by the partner (supplier) who received it.
class LeadItem {
  final String id;
  final String date;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String requirementTitle;
  final String requirementDesc;
  final String productImage;
  final String quantity;
  final double quantityVal;
  final String unit;
  final String location;
  String status;
  double? quotedPrice;
  String deliveryStatus;
  double gstPercent;
  final double productCost;

  /// Private to the partner: purchase cost per unit saved with the quote (null = not entered).
  double? unitCost;

  /// Private to the partner: transport / loading / labour for the whole order.
  double extraCost;
  final List<String> images;
  final String finishedDate;

  LeadItem({
    required this.id,
    required this.date,
    this.buyerId = '',
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.requirementTitle,
    required this.requirementDesc,
    this.productImage = '',
    required this.quantity,
    required this.quantityVal,
    required this.unit,
    required this.location,
    required this.status,
    this.quotedPrice,
    required this.deliveryStatus,
    required this.gstPercent,
    this.productCost = 0,
    this.unitCost,
    this.extraCost = 0,
    required this.images,
    required this.finishedDate,
  });

  factory LeadItem.fromJson(Map<String, dynamic> json) {
    final qtyVal = _toDouble(json['quantity']) ?? 0.0;
    final unitStr = json['unit']?.toString() ?? 'Units';
    return LeadItem(
      id: json['id'] ?? '',
      date: _dateOnly(json['created_at']),
      buyerId: json['buyer_id']?.toString() ?? '',
      buyerName: json['buyer_name'] ?? 'Customer',
      buyerPhone: json['buyer_phone'] ?? '',
      buyerEmail: json['buyer_email'] ?? '',
      requirementTitle: json['title'] ?? json['product_name'] ?? 'Material requirement',
      requirementDesc: json['description'] ?? '',
      productImage: json['product_image']?.toString() ?? '',
      quantity: '${_formatQty(qtyVal)} $unitStr',
      quantityVal: qtyVal,
      unit: unitStr,
      location: json['location'] ?? '',
      status: json['status'] ?? 'New',
      quotedPrice: _toDouble(json['quoted_price']),
      deliveryStatus: json['delivery_status'] ?? 'Pending',
      gstPercent: _toDouble(json['gst_percent']) ?? 18.0,
      productCost: _toDouble(json['product_cost']) ?? 0,
      unitCost: _toDouble(json['unit_cost']),
      extraCost: _toDouble(json['extra_cost']) ?? 0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      finishedDate: _dateOnly(json['updated_at'] ?? json['updatedAt']),
    );
  }
}
