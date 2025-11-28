import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/tds_provider.dart';
import '../models/gst_tds_transaction.dart';
import '../utils/extensions.dart';
import 'package:data_table_2/data_table_2.dart';

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      if (mounted) {
        final provider = context.read<TDSProvider>();
        provider.loadTransactions();
        provider.loadParties();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);

        final transactions = <GSTTDSTransaction>[];
        final provider = context.read<TDSProvider>();

        for (var table in excel.tables.keys) {
          final sheet = excel.tables[table]!;

          // Skip header row (assuming first row is header)
          for (int i = 1; i < sheet.maxRows; i++) {
            final row = sheet.rows[i];

            try {
              // Parse Excel data (adjust column indices based on your Excel format)
              final voucherNo = row[0]?.value?.toString() ?? '';
              final paymentDateStr = row[1]?.value?.toString() ?? '';
              final partyCode = row[2]?.value?.toString() ?? '';
              final invoiceNo = row[3]?.value?.toString();
              final taxableAmount =
                  double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0;
              final cgst =
                  double.tryParse(row[5]?.value?.toString() ?? '0') ?? 0.0;
              final sgst =
                  double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0;
              final igst =
                  double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
              final invoiceAmount =
                  double.tryParse(row[8]?.value?.toString() ?? '0') ?? 0.0;

              if (voucherNo.isNotEmpty &&
                  paymentDateStr.isNotEmpty &&
                  partyCode.isNotEmpty) {
                // Find party by code
                final party = provider.parties
                    .where((p) => p.code == partyCode)
                    .firstOrNull;
                if (party != null) {
                  final transaction = GSTTDSTransaction(
                    voucherNo: voucherNo,
                    paymentDate: DateFormat('dd/MM/yyyy').parse(paymentDateStr),
                    partyId: party.id!,
                    invoiceNo: invoiceNo,
                    taxableAmount: taxableAmount,
                    cgst: cgst,
                    sgst: sgst,
                    igst: igst,
                    invoiceAmount: invoiceAmount,
                    companyId: provider.selectedCompany!.id!,
                    createdAt: DateTime.now(),
                  );
                  transactions.add(transaction);
                }
              }
            } catch (e) {
              // Skip invalid rows
              print('Error parsing row $i: $e');
            }
          }
        }

        if (transactions.isNotEmpty) {
          await provider.importTransactionsFromExcel(transactions);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully imported ${transactions.length} transactions',
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No valid transactions found in the file'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing Excel: $e')));
      }
    }
  }

  void _showTransactionForm([GSTTDSTransaction? transaction]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransactionFormDialog(transaction: transaction),
    );
  }

  void _deleteTransaction(GSTTDSTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete transaction ${transaction.voucherNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TDSProvider>().deleteTransaction(transaction.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST-TDS Transaction Entry'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Transactions'),
            Tab(icon: Icon(Icons.add), text: 'Manual Entry'),
            Tab(icon: Icon(Icons.table_view), text: 'Excel Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Transaction List Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search transactions...',
                    hintText: 'Search by voucher number or invoice number',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Consumer<TDSProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text('Error: ${provider.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.loadTransactions(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final transactions = provider.searchTransactions(
                      _searchQuery,
                    );

                    if (transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No transactions found. Add your first transaction!'
                                  : 'No transactions found matching \"$_searchQuery\"',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _tabController.animateTo(1);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Transaction'),
                            ),
                          ],
                        ),
                      );
                    }

                    return DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 1200,
                      columns: const [
                        DataColumn2(
                          label: Text('Voucher No'),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(label: Text('Date'), size: ColumnSize.S),
                        DataColumn2(label: Text('Party'), size: ColumnSize.L),
                        DataColumn2(
                          label: Text('Invoice No'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text('Taxable Amount'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(label: Text('CGST'), size: ColumnSize.S),
                        DataColumn2(label: Text('SGST'), size: ColumnSize.S),
                        DataColumn2(label: Text('IGST'), size: ColumnSize.S),
                        DataColumn2(
                          label: Text('Total Amount'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                      ],
                      rows: transactions.map((transaction) {
                        final party = provider.getPartyById(
                          transaction.partyId,
                        );
                        return DataRow(
                          cells: [
                            DataCell(Text(transaction.voucherNo)),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(transaction.paymentDate),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    party?.name ?? 'Unknown Party',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    party?.pan ?? 'No PAN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(transaction.invoiceNo ?? 'N/A')),
                            DataCell(
                              Text(
                                '₹${transaction.taxableAmount.toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text('₹${transaction.cgst.toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Text('₹${transaction.sgst.toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Text('₹${transaction.igst.toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Text(
                                '₹${transaction.invoiceAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () =>
                                        _showTransactionForm(transaction),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () =>
                                        _deleteTransaction(transaction),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),

          // Manual Entry Tab
          const TransactionManualEntryWidget(),

          // Excel Import Tab
          ExcelImportWidget(onImport: _importFromExcel),
        ],
      ),
    );
  }
}

class TransactionManualEntryWidget extends StatefulWidget {
  const TransactionManualEntryWidget({super.key});

  @override
  State<TransactionManualEntryWidget> createState() =>
      _TransactionManualEntryWidgetState();
}

class _TransactionManualEntryWidgetState
    extends State<TransactionManualEntryWidget> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'voucherNo',
                            decoration: const InputDecoration(
                              labelText: 'Voucher No *',
                              hintText: 'Enter voucher number',
                            ),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'paymentDate',
                            inputType: InputType.date,
                            decoration: const InputDecoration(
                              labelText: 'Payment Date *',
                              hintText: 'Select payment date',
                            ),
                            initialValue: DateTime.now(),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Consumer<TDSProvider>(
                            builder: (context, provider, child) {
                              return FormBuilderDropdown<String>(
                                name: 'partyId',
                                decoration: const InputDecoration(
                                  labelText: 'Select Party *',
                                ),
                                validator: FormBuilderValidators.required(),
                                items: provider.parties
                                    .map(
                                      (party) => DropdownMenuItem(
                                        value: party.id,
                                        child: Text(
                                          '${party.name} (${party.pan})',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'invoiceNo',
                            decoration: const InputDecoration(
                              labelText: 'Invoice No',
                              hintText: 'Enter invoice number',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'taxableAmount',
                            decoration: const InputDecoration(
                              labelText: 'Taxable Amount *',
                              hintText: '0.00',
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.numeric(),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'cgst',
                            decoration: const InputDecoration(
                              labelText: 'CGST',
                              hintText: '0.00',
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'sgst',
                            decoration: const InputDecoration(
                              labelText: 'SGST',
                              hintText: '0.00',
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'igst',
                            decoration: const InputDecoration(
                              labelText: 'IGST',
                              hintText: '0.00',
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'invoiceAmount',
                      decoration: const InputDecoration(
                        labelText: 'Total Invoice Amount *',
                        hintText: '0.00',
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _formKey.currentState?.reset(),
                    child: const Text('Reset Form'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<TDSProvider>(
                    builder: (context, provider, child) {
                      return ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState?.saveAndValidate() ??
                                    false) {
                                  final values = _formKey.currentState!.value;

                                  final transaction = GSTTDSTransaction(
                                    voucherNo: values['voucherNo'],
                                    paymentDate: values['paymentDate'],
                                    partyId: values['partyId'],
                                    invoiceNo: values['invoiceNo'],
                                    taxableAmount:
                                        double.tryParse(
                                          values['taxableAmount'],
                                        ) ??
                                        0.0,
                                    cgst:
                                        double.tryParse(values['cgst']) ?? 0.0,
                                    sgst:
                                        double.tryParse(values['sgst']) ?? 0.0,
                                    igst:
                                        double.tryParse(values['igst']) ?? 0.0,
                                    invoiceAmount:
                                        double.tryParse(
                                          values['invoiceAmount'],
                                        ) ??
                                        0.0,
                                    companyId: provider.selectedCompany!.id!,
                                    createdAt: DateTime.now(),
                                  );

                                  try {
                                    await provider.addTransaction(transaction);
                                    if (mounted) {
                                      _formKey.currentState?.reset();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Transaction added successfully',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Transaction'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExcelImportWidget extends StatelessWidget {
  final VoidCallback onImport;

  const ExcelImportWidget({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excel Import Instructions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Excel Format Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Column A: Voucher Number'),
                  const Text('Column B: Payment Date (DD/MM/YYYY)'),
                  const Text('Column C: Party Code'),
                  const Text('Column D: Invoice Number'),
                  const Text('Column E: Taxable Amount'),
                  const Text('Column F: CGST Amount'),
                  const Text('Column G: SGST Amount'),
                  const Text('Column H: IGST Amount'),
                  const Text('Column I: Total Invoice Amount'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: BoxBorder.fromBorderSide(
                        BorderSide(color: Colors.orange[200]!),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Note: First row should contain column headers and will be skipped during import. Make sure party codes exist in the system before importing.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onImport,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select Excel File to Import'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionFormDialog extends StatefulWidget {
  final GSTTDSTransaction? transaction;

  const TransactionFormDialog({super.key, this.transaction});

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool get isEditing => widget.transaction != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Transaction' : 'Add New Transaction'),
      content: SizedBox(
        width: 600,
        child: FormBuilder(
          key: _formKey,
          initialValue: isEditing
              ? {
                  'voucherNo': widget.transaction!.voucherNo,
                  'paymentDate': widget.transaction!.paymentDate,
                  'partyId': widget.transaction!.partyId,
                  'invoiceNo': widget.transaction!.invoiceNo,
                  'taxableAmount': widget.transaction!.taxableAmount.toString(),
                  'cgst': widget.transaction!.cgst.toString(),
                  'sgst': widget.transaction!.sgst.toString(),
                  'igst': widget.transaction!.igst.toString(),
                  'invoiceAmount': widget.transaction!.invoiceAmount.toString(),
                }
              : {},
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'voucherNo',
                        decoration: const InputDecoration(
                          labelText: 'Voucher No *',
                        ),
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'paymentDate',
                        inputType: InputType.date,
                        decoration: const InputDecoration(
                          labelText: 'Payment Date *',
                        ),
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<TDSProvider>(
                  builder: (context, provider, child) {
                    return FormBuilderDropdown<String>(
                      name: 'partyId',
                      decoration: const InputDecoration(
                        labelText: 'Select Party *',
                      ),
                      validator: FormBuilderValidators.required(),
                      items: provider.parties
                          .map(
                            (party) => DropdownMenuItem(
                              value: party.id,
                              child: Text('${party.name} (${party.pan})'),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'invoiceNo',
                  decoration: const InputDecoration(labelText: 'Invoice No'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'taxableAmount',
                        decoration: const InputDecoration(
                          labelText: 'Taxable Amount *',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'invoiceAmount',
                        decoration: const InputDecoration(
                          labelText: 'Invoice Amount *',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'cgst',
                        decoration: const InputDecoration(
                          labelText: 'CGST',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.numeric(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'sgst',
                        decoration: const InputDecoration(
                          labelText: 'SGST',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.numeric(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'igst',
                        decoration: const InputDecoration(
                          labelText: 'IGST',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.numeric(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer<TDSProvider>(
          builder: (context, provider, child) {
            return ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.saveAndValidate() ?? false) {
                        final values = _formKey.currentState!.value;

                        final transaction = GSTTDSTransaction(
                          id: isEditing ? widget.transaction!.id : null,
                          voucherNo: values['voucherNo'],
                          paymentDate: values['paymentDate'],
                          partyId: values['partyId'],
                          invoiceNo: values['invoiceNo'],
                          taxableAmount:
                              double.tryParse(values['taxableAmount']) ?? 0.0,
                          cgst: double.tryParse(values['cgst']) ?? 0.0,
                          sgst: double.tryParse(values['sgst']) ?? 0.0,
                          igst: double.tryParse(values['igst']) ?? 0.0,
                          invoiceAmount:
                              double.tryParse(values['invoiceAmount']) ?? 0.0,
                          companyId: provider.selectedCompany!.id!,
                          createdAt: isEditing
                              ? widget.transaction!.createdAt
                              : DateTime.now(),
                          updatedAt: isEditing ? DateTime.now() : null,
                        );

                        try {
                          if (isEditing) {
                            await provider.updateTransaction(transaction);
                          } else {
                            await provider.addTransaction(transaction);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Transaction updated successfully'
                                      : 'Transaction added successfully',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
              child: provider.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update' : 'Save'),
            );
          },
        ),
      ],
    );
  }
}
