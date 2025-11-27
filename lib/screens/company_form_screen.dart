import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/tds_provider.dart';
import '../models/company.dart';

class CompanyFormScreen extends StatefulWidget {
  const CompanyFormScreen({super.key});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedFinancialYear;

  final List<String> _financialYears = [
    '2023-24',
    '2024-25',
    '2025-26',
    '2026-27',
    '2027-28',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime(DateTime.now().year, 4, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime(DateTime.now().year + 1, 3, 31),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _saveCompany() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end dates')),
        );
        return;
      }

      final company = Company(
        name: _nameController.text.trim(),
        financialYear: _selectedFinancialYear!,
        startDate: _startDate!,
        endDate: _endDate!,
        createdAt: DateTime.now(),
      );

      try {
        await context.read<TDSProvider>().addCompany(company);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding company: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Company'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name *',
                          hintText: 'Enter company name',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Financial Year *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        value: _selectedFinancialYear,
                        items: _financialYears.map((year) {
                          return DropdownMenuItem<String>(
                            value: year,
                            child: Text(year),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFinancialYear = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select financial year';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Start Date *',
                          hintText: 'DD/MM/YYYY',
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        readOnly: true,
                        onTap: _selectStartDate,
                        validator: (value) {
                          if (_startDate == null) {
                            return 'Start date is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'End Date *',
                          hintText: 'DD/MM/YYYY',
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        readOnly: true,
                        onTap: _selectEndDate,
                        validator: (value) {
                          if (_endDate == null) {
                            return 'End date is required';
                          }
                          if (_startDate != null &&
                              _endDate!.isBefore(_startDate!)) {
                            return 'End date must be after start date';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<TDSProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton(
                          onPressed: provider.isLoading ? null : _saveCompany,
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Company'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
