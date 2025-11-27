import 'package:flutter/foundation.dart';
import '../models/company.dart';
import '../models/party.dart';
import '../models/gst_tds_transaction.dart';
import '../services/database_service.dart';

class TDSProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Company? _selectedCompany;
  List<Company> _companies = [];
  List<Party> _parties = [];
  List<GSTTDSTransaction> _transactions = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  Company? get selectedCompany => _selectedCompany;
  List<Company> get companies => _companies;
  List<Party> get parties => _parties;
  List<GSTTDSTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Company operations
  Future<void> loadCompanies() async {
    _setLoading(true);
    _setError(null);
    try {
      _companies = await _dbService.getCompanies();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load companies: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCompany(Company company) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertCompany(company);
      await loadCompanies();
    } catch (e) {
      _setError('Failed to add company: $e');
    } finally {
      _setLoading(false);
    }
  }

  void selectCompany(Company company) {
    _selectedCompany = company;
    notifyListeners();
    // Load related data when company is selected
    loadParties();
    loadTransactions();
  }

  // Party operations
  Future<void> loadParties() async {
    _setLoading(true);
    _setError(null);
    try {
      _parties = await _dbService.getParties();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load parties: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addParty(Party party) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertParty(party);
      await loadParties();
    } catch (e) {
      _setError('Failed to add party: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateParty(Party party) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateParty(party);
      await loadParties();
    } catch (e) {
      _setError('Failed to update party: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteParty(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteParty(id);
      await loadParties();
    } catch (e) {
      _setError('Failed to delete party: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Transaction operations
  Future<void> loadTransactions() async {
    if (_selectedCompany == null) return;

    _setLoading(true);
    _setError(null);
    try {
      _transactions = await _dbService.getGSTTDSTransactions(
        companyId: _selectedCompany!.id!,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTransaction(GSTTDSTransaction transaction) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertGSTTDSTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      _setError('Failed to add transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransaction(GSTTDSTransaction transaction) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateGSTTDSTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      _setError('Failed to update transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteGSTTDSTransaction(id);
      await loadTransactions();
    } catch (e) {
      _setError('Failed to delete transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importTransactionsFromExcel(
    List<GSTTDSTransaction> transactions,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertGSTTDSTransactionsBatch(transactions);
      await loadTransactions();
    } catch (e) {
      _setError('Failed to import transactions from Excel: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search functions
  List<Party> searchParties(String query) {
    if (query.isEmpty) return _parties;
    return _parties
        .where(
          (party) =>
              party.name.toLowerCase().contains(query.toLowerCase()) ||
              party.pan.toLowerCase().contains(query.toLowerCase()) ||
              (party.gstin?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();
  }

  List<GSTTDSTransaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    return _transactions
        .where(
          (transaction) =>
              transaction.voucherNo.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (transaction.invoiceNo?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  // Helper functions
  Party? getPartyById(String id) {
    try {
      return _parties.firstWhere((party) => party.id == id);
    } catch (e) {
      return null;
    }
  }

  double getTotalTransactionAmount() {
    return _transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.invoiceAmount,
    );
  }

  double getTotalTaxAmount() {
    return _transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.totalGST,
    );
  }

  void clearError() {
    _setError(null);
  }
}
