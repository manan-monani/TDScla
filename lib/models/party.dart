class Party {
  final String? id;
  final String code;
  final String name;
  final String pan;
  final String? gstin;
  final String? address;
  final String? city;
  final String? state;
  final String? pin;
  final String? mobile;
  final String? email;
  final String? stateCode;
  final PartyType partyType;
  final CompType compType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Party({
    this.id,
    required this.code,
    required this.name,
    required this.pan,
    this.gstin,
    this.address,
    this.city,
    this.state,
    this.pin,
    this.mobile,
    this.email,
    this.stateCode,
    required this.partyType,
    required this.compType,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'pan': pan,
      'gstin': gstin,
      'address': address,
      'city': city,
      'state': state,
      'pin': pin,
      'mobile': mobile,
      'email': email,
      'state_code': stateCode,
      'party_type': partyType.toString(),
      'comp_type': compType.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      pan: map['pan'],
      gstin: map['gstin'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      pin: map['pin'],
      mobile: map['mobile'],
      email: map['email'],
      stateCode: map['state_code'],
      partyType: PartyType.values.firstWhere(
        (e) => e.toString() == map['party_type'],
      ),
      compType: CompType.values.firstWhere(
        (e) => e.toString() == map['comp_type'],
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Party copyWith({
    String? id,
    String? code,
    String? name,
    String? pan,
    String? gstin,
    String? address,
    String? city,
    String? state,
    String? pin,
    String? mobile,
    String? email,
    String? stateCode,
    PartyType? partyType,
    CompType? compType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Party(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      pan: pan ?? this.pan,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pin: pin ?? this.pin,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      stateCode: stateCode ?? this.stateCode,
      partyType: partyType ?? this.partyType,
      compType: compType ?? this.compType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Party{id: $id, code: $code, name: $name, pan: $pan, gstin: $gstin}';
  }
}

enum PartyType { company, nonCompany, employee }

enum CompType { firm, individual, nonComp, trust, cooperative }
