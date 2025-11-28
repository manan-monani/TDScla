import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../providers/tds_provider.dart';
import '../models/party.dart';
import 'package:data_table_2/data_table_2.dart';

class PartyMasterScreen extends StatefulWidget {
  const PartyMasterScreen({super.key});

  @override
  State<PartyMasterScreen> createState() => _PartyMasterScreenState();
}

class _PartyMasterScreenState extends State<PartyMasterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<TDSProvider>().loadParties();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPartyForm([Party? party]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PartyFormDialog(party: party),
    );
  }

  void _deleteParty(Party party) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${party.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TDSProvider>().deleteParty(party.id!);
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
        title: const Text('Party Master'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _showPartyForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Add New Party',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search parties...',
                hintText: 'Search by name, PAN, or GSTIN',
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

          // Party List
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
                          onPressed: () => provider.loadParties(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final parties = provider.searchParties(_searchQuery);

                if (parties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No parties found. Add your first party!'
                              : 'No parties found matching "$_searchQuery"',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showPartyForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Party'),
                        ),
                      ],
                    ),
                  );
                }

                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  columns: const [
                    DataColumn2(label: Text('Party Name'), size: ColumnSize.L),
                    DataColumn2(label: Text('PAN'), size: ColumnSize.M),
                    DataColumn2(label: Text('GSTIN'), size: ColumnSize.M),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                  ],
                  rows: parties
                      .map(
                        (party) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                party.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(party.pan)),
                            DataCell(Text(party.gstin ?? 'N/A')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showPartyForm(party),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteParty(party),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPartyForm(),
        child: const Icon(Icons.add),
        tooltip: 'Add New Party',
      ),
    );
  }
}

class PartyFormDialog extends StatefulWidget {
  final Party? party;

  const PartyFormDialog({super.key, this.party});

  @override
  State<PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends State<PartyFormDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool get isEditing => widget.party != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Party' : 'Add New Party'),
      content: SizedBox(
        width: 600,
        child: FormBuilder(
          key: _formKey,
          initialValue: isEditing
              ? {
                  'name': widget.party!.name,
                  'pan': widget.party!.pan,
                  'gstin': widget.party!.gstin,
                }
              : {},
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'name',
                  decoration: const InputDecoration(
                    labelText: 'Party Name *',
                    hintText: 'Enter party name',
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(3),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'pan',
                  decoration: const InputDecoration(
                    labelText: 'PAN *',
                    hintText: 'ABCDE1234F',
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.match(
                      RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$'),
                      errorText: 'Invalid PAN format',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'gstin',
                  decoration: const InputDecoration(
                    labelText: 'GSTIN',
                    hintText: '22ABCDE1234F1Z5',
                  ),
                  validator: FormBuilderValidators.match(
                    RegExp(
                      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                    ),
                    errorText: 'Invalid GSTIN format',
                  ),
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

                        final party = Party(
                          id: isEditing ? widget.party!.id : null,
                          code: values['name']
                              .toString()
                              .toUpperCase()
                              .replaceAll(' ', '')
                              .substring(
                                0,
                                (values['name'].toString().length > 5
                                    ? 5
                                    : values['name'].toString().length),
                              ),
                          name: values['name'],
                          pan: values['pan'].toString().toUpperCase(),
                          gstin: values['gstin']?.toString().toUpperCase(),
                          address: null,
                          city: null,
                          state: null,
                          pin: null,
                          mobile: null,
                          email: null,
                          stateCode: null,
                          partyType: PartyType.company,
                          compType: CompType.firm,
                          createdAt: isEditing
                              ? widget.party!.createdAt
                              : DateTime.now(),
                          updatedAt: isEditing ? DateTime.now() : null,
                        );

                        try {
                          if (isEditing) {
                            await provider.updateParty(party);
                          } else {
                            await provider.addParty(party);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Party updated successfully'
                                      : 'Party added successfully',
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
