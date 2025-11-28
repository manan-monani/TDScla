import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../models/company.dart';
import '../models/party.dart';
import '../models/gst_tds_transaction.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize sqflite for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop platforms, store in app documents directory
      final Directory appDocumentsDirectory =
          await getApplicationDocumentsDirectory();
      final String dbPath = join(appDocumentsDirectory.path, 'TDS Management');
      await Directory(dbPath).create(recursive: true);
      path = join(dbPath, 'tds_management.db');
    } else {
      path = join(await getDatabasesPath(), 'tds_management.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Companies table
    await db.execute('''
      CREATE TABLE companies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        financial_year TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Parties table
    await db.execute('''
      CREATE TABLE parties (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        pan TEXT NOT NULL,
        gstin TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        pin TEXT,
        mobile TEXT,
        email TEXT,
        state_code TEXT,
        party_type TEXT NOT NULL,
        comp_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // GST TDS Transactions table
    await db.execute('''
      CREATE TABLE gst_tds_transactions (
        id TEXT PRIMARY KEY,
        voucher_no TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        party_id TEXT NOT NULL,
        invoice_no TEXT,
        taxable_amount REAL NOT NULL,
        cgst REAL NOT NULL DEFAULT 0,
        sgst REAL NOT NULL DEFAULT 0,
        igst REAL NOT NULL DEFAULT 0,
        invoice_amount REAL NOT NULL,
        company_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (party_id) REFERENCES parties (id),
        FOREIGN KEY (company_id) REFERENCES companies (id)
      )
    ''');

    // GSTR7 Returns table
    await db.execute('''
      CREATE TABLE gstr7_returns (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        from_date TEXT NOT NULL,
        to_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (company_id) REFERENCES companies (id)
      )
    ''');

    // GSTR7 Entries table
    await db.execute('''
      CREATE TABLE gstr7_entries (
        id TEXT PRIMARY KEY,
        return_id TEXT NOT NULL,
        gstin TEXT NOT NULL,
        party_name TEXT NOT NULL,
        taxable_value REAL NOT NULL DEFAULT 0,
        central_tax REAL NOT NULL DEFAULT 0,
        state_tax REAL NOT NULL DEFAULT 0,
        integrated_tax REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (return_id) REFERENCES gstr7_returns (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_parties_pan ON parties (pan)');
    await db.execute('CREATE INDEX idx_parties_gstin ON parties (gstin)');
    await db.execute(
      'CREATE INDEX idx_transactions_party ON gst_tds_transactions (party_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_company ON gst_tds_transactions (company_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_date ON gst_tds_transactions (payment_date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // Company CRUD operations
  Future<String> insertCompany(Company company) async {
    final db = await database;
    final id = company.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final companyWithId = company.copyWith(id: id);
    await db.insert('companies', companyWithId.toMap());
    return id;
  }

  Future<List<Company>> getCompanies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('companies');
    return List.generate(maps.length, (i) => Company.fromMap(maps[i]));
  }

  Future<Company?> getCompany(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Company.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateCompany(Company company) async {
    final db = await database;
    await db.update(
      'companies',
      company.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  Future<void> deleteCompany(String id) async {
    final db = await database;
    await db.delete('companies', where: 'id = ?', whereArgs: [id]);
  }

  // Party CRUD operations
  Future<String> insertParty(Party party) async {
    final db = await database;
    final id = party.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final partyWithId = party.copyWith(id: id);
    await db.insert('parties', partyWithId.toMap());
    return id;
  }

  Future<List<Party>> getParties() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parties',
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => Party.fromMap(maps[i]));
  }

  Future<Party?> getParty(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parties',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Party.fromMap(maps.first);
    }
    return null;
  }

  Future<Party?> getPartyByPAN(String pan) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parties',
      where: 'pan = ?',
      whereArgs: [pan],
    );
    if (maps.isNotEmpty) {
      return Party.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateParty(Party party) async {
    final db = await database;
    await db.update(
      'parties',
      party.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [party.id],
    );
  }

  Future<void> deleteParty(String id) async {
    final db = await database;
    await db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  // GST TDS Transaction CRUD operations
  Future<String> insertGSTTDSTransaction(GSTTDSTransaction transaction) async {
    final db = await database;
    final id =
        transaction.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final transactionWithId = transaction.copyWith(id: id);
    await db.insert('gst_tds_transactions', transactionWithId.toMap());
    return id;
  }

  Future<List<GSTTDSTransaction>> getGSTTDSTransactions({
    String? companyId,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = companyId != null
        ? await db.query(
            'gst_tds_transactions',
            where: 'company_id = ?',
            whereArgs: [companyId],
            orderBy: 'payment_date DESC',
          )
        : await db.query('gst_tds_transactions', orderBy: 'payment_date DESC');
    return List.generate(
      maps.length,
      (i) => GSTTDSTransaction.fromMap(maps[i]),
    );
  }

  Future<List<GSTTDSTransaction>> getGSTTDSTransactionsByPeriod({
    required String companyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gst_tds_transactions',
      where: 'company_id = ? AND payment_date >= ? AND payment_date <= ?',
      whereArgs: [
        companyId,
        fromDate.toIso8601String(),
        toDate.toIso8601String(),
      ],
      orderBy: 'payment_date',
    );
    return List.generate(
      maps.length,
      (i) => GSTTDSTransaction.fromMap(maps[i]),
    );
  }

  Future<void> updateGSTTDSTransaction(GSTTDSTransaction transaction) async {
    final db = await database;
    await db.update(
      'gst_tds_transactions',
      transaction.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteGSTTDSTransaction(String id) async {
    final db = await database;
    await db.delete('gst_tds_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Bulk insert for Excel import
  Future<void> insertGSTTDSTransactionsBatch(
    List<GSTTDSTransaction> transactions,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (final transaction in transactions) {
      final id =
          transaction.id ??
          DateTime.now().millisecondsSinceEpoch.toString() +
              transactions.indexOf(transaction).toString();
      final transactionWithId = transaction.copyWith(id: id);
      batch.insert('gst_tds_transactions', transactionWithId.toMap());
    }

    await batch.commit();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
