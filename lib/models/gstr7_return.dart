class GSTR7Return {
  final String? id;
  final String companyId;
  final int month;
  final int year;
  final DateTime fromDate;
  final DateTime toDate;
  final List<GSTR7Entry> entries;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GSTR7Return({
    this.id,
    required this.companyId,
    required this.month,
    required this.year,
    required this.fromDate,
    required this.toDate,
    required this.entries,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'month': month,
      'year': year,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'entries': entries.map((e) => e.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory GSTR7Return.fromMap(Map<String, dynamic> map) {
    return GSTR7Return(
      id: map['id'],
      companyId: map['company_id'],
      month: map['month'],
      year: map['year'],
      fromDate: DateTime.parse(map['from_date']),
      toDate: DateTime.parse(map['to_date']),
      entries:
          (map['entries'] as List?)
              ?.map((e) => GSTR7Entry.fromMap(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  GSTR7Return copyWith({
    String? id,
    String? companyId,
    int? month,
    int? year,
    DateTime? fromDate,
    DateTime? toDate,
    List<GSTR7Entry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GSTR7Return(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      month: month ?? this.month,
      year: year ?? this.year,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GSTR7Entry {
  final String gstin;
  final String partyName;
  final double taxableValue;
  final double centralTax;
  final double stateTax;
  final double integratedTax;

  GSTR7Entry({
    required this.gstin,
    required this.partyName,
    required this.taxableValue,
    required this.centralTax,
    required this.stateTax,
    required this.integratedTax,
  });

  Map<String, dynamic> toMap() {
    return {
      'gstin': gstin,
      'party_name': partyName,
      'taxable_value': taxableValue,
      'central_tax': centralTax,
      'state_tax': stateTax,
      'integrated_tax': integratedTax,
    };
  }

  factory GSTR7Entry.fromMap(Map<String, dynamic> map) {
    return GSTR7Entry(
      gstin: map['gstin'],
      partyName: map['party_name'],
      taxableValue: map['taxable_value']?.toDouble() ?? 0.0,
      centralTax: map['central_tax']?.toDouble() ?? 0.0,
      stateTax: map['state_tax']?.toDouble() ?? 0.0,
      integratedTax: map['integrated_tax']?.toDouble() ?? 0.0,
    );
  }

  double get totalTax => centralTax + stateTax + integratedTax;

  @override
  String toString() {
    return 'GSTR7Entry{gstin: $gstin, partyName: $partyName, taxableValue: $taxableValue, totalTax: $totalTax}';
  }
}
