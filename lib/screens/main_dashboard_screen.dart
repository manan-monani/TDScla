import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tds_provider.dart';
import '../widgets/sidebar.dart';
import 'party_master_screen.dart';
import 'transaction_entry_screen.dart';
import 'gstr7_generation_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    const DashboardHomeWidget(),
    const PartyMasterScreen(),
    const TransactionEntryScreen(),
    const GSTR7GenerationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 250,
            child: TDSSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
          ),

          // Main content
          Expanded(child: screens[selectedIndex]),
        ],
      ),
    );
  }
}

class DashboardHomeWidget extends StatelessWidget {
  const DashboardHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TDSProvider>(
      builder: (context, provider, child) {
        final company = provider.selectedCompany;

        return Scaffold(
          appBar: AppBar(
            title: Text(company?.name ?? 'TDS Management System'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (company != null) ...[
                          Text('Company: ${company.name}'),
                          Text('Financial Year: ${company.financialYear}'),
                          Text(
                            'Period: ${company.startDate.day}/${company.startDate.month}/${company.startDate.year} - ${company.endDate.day}/${company.endDate.month}/${company.endDate.year}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                    final childAspectRatio = constraints.maxWidth > 800
                        ? 1.2
                        : 1.0;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildStatCard(
                          context,
                          'Total Parties',
                          '${provider.parties.length}',
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          context,
                          'Total Transactions',
                          '${provider.transactions.length}',
                          Icons.receipt_long,
                          Colors.green,
                        ),
                        _buildStatCard(
                          context,
                          'Total Invoice Amount',
                          '₹${provider.getTotalTransactionAmount().toStringAsFixed(2)}',
                          Icons.currency_rupee,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          context,
                          'Total Tax Amount',
                          '₹${provider.getTotalTaxAmount().toStringAsFixed(2)}',
                          Icons.account_balance,
                          Colors.purple,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
