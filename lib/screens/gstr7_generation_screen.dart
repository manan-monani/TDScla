import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/tds_provider.dart';
import '../models/gstr7_return.dart';
import 'package:data_table_2/data_table_2.dart';

class GSTR7GenerationScreen extends StatefulWidget {
  const GSTR7GenerationScreen({super.key});

  @override
  State<GSTR7GenerationScreen> createState() => _GSTR7GenerationScreenState();
}

class _GSTR7GenerationScreenState extends State<GSTR7GenerationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormBuilderState>();

  List<GSTR7Entry> _gstr7Entries = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateGSTR7Data() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final values = _formKey.currentState!.value;
      final fromDate = values['fromDate'] as DateTime;
      final toDate = values['toDate'] as DateTime;

      final provider = context.read<TDSProvider>();

      // Filter transactions by date range
      final filteredTransactions = provider.transactions.where((transaction) {
        return transaction.paymentDate.isAfter(
              fromDate.subtract(const Duration(days: 1)),
            ) &&
            transaction.paymentDate.isBefore(
              toDate.add(const Duration(days: 1)),
            );
      }).toList();

      // Group transactions by party and generate GSTR7 entries
      final Map<String, GSTR7Entry> partyGrouped = {};

      for (final transaction in filteredTransactions) {
        final party = provider.getPartyById(transaction.partyId);
        if (party != null && party.gstin != null && party.gstin!.isNotEmpty) {
          final key = party.gstin!;

          if (partyGrouped.containsKey(key)) {
            final existing = partyGrouped[key]!;
            partyGrouped[key] = GSTR7Entry(
              gstin: existing.gstin,
              partyName: existing.partyName,
              taxableValue: existing.taxableValue + transaction.taxableAmount,
              centralTax: existing.centralTax + transaction.cgst,
              stateTax: existing.stateTax + transaction.sgst,
              integratedTax: existing.integratedTax + transaction.igst,
            );
          } else {
            partyGrouped[key] = GSTR7Entry(
              gstin: party.gstin!,
              partyName: party.name,
              taxableValue: transaction.taxableAmount,
              centralTax: transaction.cgst,
              stateTax: transaction.sgst,
              integratedTax: transaction.igst,
            );
          }
        }
      }

      setState(() {
        _gstr7Entries = partyGrouped.values.toList();
        _isGenerating = false;
      });

      // Switch to the results tab
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GSTR-7 data generated successfully for ${_gstr7Entries.length} parties',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating GSTR-7 data: $e')),
      );
    }
  }

  Future<void> _exportToExcel() async {
    if (_gstr7Entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No data to export. Please generate GSTR-7 data first.',
          ),
        ),
      );
      return;
    }

    try {
      // Create Excel file
      final excel = Excel.createExcel();

      // Remove default sheet and add custom sheets
      excel.delete('Sheet1');

      // Create 3TDS Sheet
      final tdsSheet = excel['3TDS'];
      _create3TDSSheet(tdsSheet);

      // Create 4Amend Sheet
      final amendSheet = excel['4Amend'];
      _create4AmendSheet(amendSheet);

      // Get downloads directory
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('${directory.path}/GSTR7_Return_$timestamp.xlsx');

        final bytes = excel.encode();
        await file.writeAsBytes(bytes!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file exported to: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting to Excel: $e')));
    }
  }

  void _create3TDSSheet(Sheet sheet) {
    // Add headers
    final headers = [
      'GSTIN',
      'Party Name',
      'Taxable Value',
      'Central Tax',
      'State Tax',
      'Integrated Tax',
      'Total Tax',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue300,
      );
    }

    // Add data rows
    for (int i = 0; i < _gstr7Entries.length; i++) {
      final entry = _gstr7Entries[i];
      final rowIndex = i + 1;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(
        entry.gstin,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(
        entry.partyName,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = DoubleCellValue(
        entry.taxableValue,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = DoubleCellValue(
        entry.centralTax,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = DoubleCellValue(
        entry.stateTax,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = DoubleCellValue(
        entry.integratedTax,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = DoubleCellValue(
        entry.totalTax,
      );
    }

    // Add totals row
    if (_gstr7Entries.isNotEmpty) {
      final totalRowIndex = _gstr7Entries.length + 1;

      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRowIndex),
          )
          .value = TextCellValue(
        'TOTAL',
      );

      final totalTaxableValue = _gstr7Entries.fold(
        0.0,
        (sum, entry) => sum + entry.taxableValue,
      );
      final totalCentralTax = _gstr7Entries.fold(
        0.0,
        (sum, entry) => sum + entry.centralTax,
      );
      final totalStateTax = _gstr7Entries.fold(
        0.0,
        (sum, entry) => sum + entry.stateTax,
      );
      final totalIntegratedTax = _gstr7Entries.fold(
        0.0,
        (sum, entry) => sum + entry.integratedTax,
      );
      final totalTax = _gstr7Entries.fold(
        0.0,
        (sum, entry) => sum + entry.totalTax,
      );

      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRowIndex),
          )
          .value = DoubleCellValue(
        totalTaxableValue,
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIndex),
          )
          .value = DoubleCellValue(
        totalCentralTax,
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex),
          )
          .value = DoubleCellValue(
        totalStateTax,
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex),
          )
          .value = DoubleCellValue(
        totalIntegratedTax,
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRowIndex),
          )
          .value = DoubleCellValue(
        totalTax,
      );
    }
  }

  void _create4AmendSheet(Sheet sheet) {
    // Amendment sheet with placeholder data
    final headers = [
      'Original GSTIN',
      'Original Party Name',
      'Original Return Period',
      'Amendment Type',
      'Amended Taxable Value',
      'Amended Central Tax',
      'Amended State Tax',
      'Amended Integrated Tax',
      'Reason for Amendment',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.orange300,
      );
    }

    // Add a note row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('Add amendment entries here if needed');
  }

  Future<void> _generateJSON() async {
    if (_gstr7Entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No data to export. Please generate GSTR-7 data first.',
          ),
        ),
      );
      return;
    }

    try {
      // Create JSON structure for GSTR-7
      final jsonData = {
        'gstin': context.read<TDSProvider>().selectedCompany?.name ?? '',
        'ret_period': DateFormat('MMyyyy').format(DateTime.now()),
        'tds': {
          'sup_details': _gstr7Entries
              .map(
                (entry) => {
                  'gstin': entry.gstin,
                  'trade_nm': entry.partyName,
                  'sup_det': [
                    {
                      'rt': 18, // Default rate, adjust as needed
                      'txval': entry.taxableValue,
                      'ctax': entry.centralTax,
                      'stax': entry.stateTax,
                      'itax': entry.integratedTax,
                    },
                  ],
                },
              )
              .toList(),
        },
      };

      // Save JSON file
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('${directory.path}/GSTR7_JSON_$timestamp.json');

        const encoder = JsonEncoder.withIndent('  ');
        final jsonString = encoder.convert(jsonData);
        await file.writeAsString(jsonString);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON file generated: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating JSON: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GSTR-7 Generation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Generate'),
            Tab(icon: Icon(Icons.table_chart), text: 'View Data'),
            Tab(icon: Icon(Icons.file_download), text: 'Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Generation Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GSTR-7 Return Period Selection',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Company: ${context.watch<TDSProvider>().selectedCompany?.name ?? 'Not Selected'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FormBuilderDateTimePicker(
                                  name: 'fromDate',
                                  inputType: InputType.date,
                                  decoration: const InputDecoration(
                                    labelText: 'From Date *',
                                    hintText: 'Select start date',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  initialValue: DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    1,
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FormBuilderDateTimePicker(
                                  name: 'toDate',
                                  inputType: InputType.date,
                                  decoration: const InputDecoration(
                                    labelText: 'To Date *',
                                    hintText: 'Select end date',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  initialValue: DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month + 1,
                                    0,
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: FormBuilderDropdown<String>(
                                  name: 'month',
                                  decoration: const InputDecoration(
                                    labelText: 'Return Month',
                                    prefixIcon: Icon(Icons.date_range),
                                  ),
                                  initialValue: DateFormat(
                                    'MMMM',
                                  ).format(DateTime.now()),
                                  items:
                                      [
                                            'January',
                                            'February',
                                            'March',
                                            'April',
                                            'May',
                                            'June',
                                            'July',
                                            'August',
                                            'September',
                                            'October',
                                            'November',
                                            'December',
                                          ]
                                          .map(
                                            (month) => DropdownMenuItem(
                                              value: month,
                                              child: Text(month),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FormBuilderDropdown<String>(
                                  name: 'year',
                                  decoration: const InputDecoration(
                                    labelText: 'Return Year',
                                    prefixIcon: Icon(Icons.today),
                                  ),
                                  initialValue: DateTime.now().year.toString(),
                                  items: List.generate(5, (index) {
                                    final year =
                                        DateTime.now().year - 2 + index;
                                    return DropdownMenuItem(
                                      value: year.toString(),
                                      child: Text(year.toString()),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating
                                  ? null
                                  : _generateGSTR7Data,
                              icon: _isGenerating
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.analytics),
                              label: Text(
                                _isGenerating
                                    ? 'Generating...'
                                    : 'Generate GSTR-7 Data',
                              ),
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
                ),

                const SizedBox(height: 16),

                // Quick stats
                if (_gstr7Entries.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            'Total Parties',
                            '${_gstr7Entries.length}',
                            Icons.business,
                          ),
                          _buildStatColumn(
                            'Total Taxable Value',
                            '₹${_gstr7Entries.fold(0.0, (sum, e) => sum + e.taxableValue).toStringAsFixed(2)}',
                            Icons.currency_rupee,
                          ),
                          _buildStatColumn(
                            'Total Tax',
                            '₹${_gstr7Entries.fold(0.0, (sum, e) => sum + e.totalTax).toStringAsFixed(2)}',
                            Icons.account_balance,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Data View Tab
          _gstr7Entries.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No GSTR-7 data generated yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Go to Generate tab to create GSTR-7 return data',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'GSTR-7 Return Data (${_gstr7Entries.length} entries)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 800,
                          columns: const [
                            DataColumn2(
                              label: Text('GSTIN'),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Party Name'),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Taxable Value'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Central Tax'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('State Tax'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Integrated Tax'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Total Tax'),
                              size: ColumnSize.M,
                            ),
                          ],
                          rows: _gstr7Entries
                              .map(
                                (entry) => DataRow(
                                  cells: [
                                    DataCell(
                                      SelectableText(
                                        entry.gstin,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(entry.partyName)),
                                    DataCell(
                                      Text(
                                        '₹${entry.taxableValue.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '₹${entry.centralTax.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '₹${entry.stateTax.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '₹${entry.integratedTax.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '₹${entry.totalTax.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

          // Export Tab
          Padding(
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
                          'Export Options',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (_gstr7Entries.isNotEmpty) ...[
                          Text(
                            'Data ready for export: ${_gstr7Entries.length} entries',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _exportToExcel,
                                  icon: const Icon(Icons.table_view),
                                  label: const Text('Export to Excel'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _generateJSON,
                                  icon: const Icon(Icons.code),
                                  label: const Text('Generate JSON'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text(
                            'No data available for export',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please generate GSTR-7 data first using the Generate tab',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: BoxBorder.fromBorderSide(
                              BorderSide(color: Colors.blue[200]!),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Information:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '• Excel file will contain 3TDS and 4Amend sheets',
                                style: TextStyle(fontSize: 13),
                              ),
                              const Text(
                                '• JSON file is compatible with government GSTR-7 portal',
                                style: TextStyle(fontSize: 13),
                              ),
                              const Text(
                                '• Files will be saved in Downloads folder',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
