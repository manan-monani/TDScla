class GSTTDSTransaction {
  final String? id;
  final String voucherNo;
  final DateTime paymentDate;
  final String partyId;
  final String? invoiceNo;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double invoiceAmount;
  final String companyId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GSTTDSTransaction({
    this.id,
    required this.voucherNo,
    required this.paymentDate,
    required this.partyId,
    this.invoiceNo,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.invoiceAmount,
    required this.companyId,
    required this.createdAt,
    this.updatedAt,
  });

  double get totalGST => cgst + sgst + igst;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucher_no': voucherNo,
      'payment_date': paymentDate.toIso8601String(),
      'party_id': partyId,
      'invoice_no': invoiceNo,
      'taxable_amount': taxableAmount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'invoice_amount': invoiceAmount,
      'company_id': companyId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory GSTTDSTransaction.fromMap(Map<String, dynamic> map) {
    return GSTTDSTransaction(
      id: map['id'],
      voucherNo: map['voucher_no'],
      paymentDate: DateTime.parse(map['payment_date']),
      partyId: map['party_id'],
      invoiceNo: map['invoice_no'],
      taxableAmount: map['taxable_amount']?.toDouble() ?? 0.0,
      cgst: map['cgst']?.toDouble() ?? 0.0,
      sgst: map['sgst']?.toDouble() ?? 0.0,
      igst: map['igst']?.toDouble() ?? 0.0,
      invoiceAmount: map['invoice_amount']?.toDouble() ?? 0.0,
      companyId: map['company_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  GSTTDSTransaction copyWith({
    String? id,
    String? voucherNo,
    DateTime? paymentDate,
    String? partyId,
    String? invoiceNo,
    double? taxableAmount,
    double? cgst,
    double? sgst,
    double? igst,
    double? invoiceAmount,
    String? companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GSTTDSTransaction(
      id: id ?? this.id,
      voucherNo: voucherNo ?? this.voucherNo,
      paymentDate: paymentDate ?? this.paymentDate,
      partyId: partyId ?? this.partyId,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'GSTTDSTransaction{id: $id, voucherNo: $voucherNo, paymentDate: $paymentDate, partyId: $partyId, invoiceAmount: $invoiceAmount}';
  }
}
