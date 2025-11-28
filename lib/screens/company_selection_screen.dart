import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/tds_provider.dart';
import '../models/company.dart';
import 'main_dashboard_screen.dart';
import 'company_form_screen.dart';

class CompanySelectionScreen extends StatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  Company? selectedCompany;
  String? selectedFinancialYear;

  @override
  void initState() {
    super.initState();
    // Load companies when screen initializes
    Future.microtask(() {
      if (mounted) {
        context.read<TDSProvider>().loadCompanies();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Icon(
                  Icons.business,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'TDS Management System',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select Company & Financial Year',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Company Selection
                Consumer<TDSProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const CircularProgressIndicator();
                    }

                    if (provider.error != null) {
                      return Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${provider.error}',
                            style: TextStyle(color: Colors.red[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.loadCompanies(),
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Company Dropdown
                        DropdownButtonFormField<Company>(
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          value: selectedCompany,
                          items: provider.companies.map((company) {
                            return DropdownMenuItem<Company>(
                              value: company,
                              child: Text(
                                company.name,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (Company? value) {
                            setState(() {
                              selectedCompany = value;
                              selectedFinancialYear = value?.financialYear;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a company';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Financial Year Display (read-only when company is selected)
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Financial Year',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          initialValue: selectedFinancialYear ?? '',
                          readOnly: true,
                          style: TextStyle(
                            color: selectedCompany != null
                                ? Colors.black
                                : Colors.grey[400],
                          ),
                        ),

                        if (selectedCompany != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Period Details:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'From: ${DateFormat('dd/MM/yyyy').format(selectedCompany!.startDate)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'To: ${DateFormat('dd/MM/yyyy').format(selectedCompany!.endDate)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CompanyFormScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add New Company'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: selectedCompany != null
                                    ? () {
                                        // Select company and navigate to main dashboard
                                        provider.selectCompany(
                                          selectedCompany!,
                                        );
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MainDashboardScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.login),
                                label: const Text('Login'),
                              ),
                            ),
                          ],
                        ),

                        // Show companies count
                        if (provider.companies.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            '${provider.companies.length} companies available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
