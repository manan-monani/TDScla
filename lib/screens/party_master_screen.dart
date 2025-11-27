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
      context.read<TDSProvider>().loadParties();
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
                    DataColumn2(label: Text('Code'), size: ColumnSize.S),
                    DataColumn2(label: Text('Party Name'), size: ColumnSize.L),
                    DataColumn2(label: Text('PAN'), size: ColumnSize.M),
                    DataColumn2(label: Text('GSTIN'), size: ColumnSize.M),
                    DataColumn2(label: Text('Party Type'), size: ColumnSize.M),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                  ],
                  rows: parties
                      .map(
                        (party) => DataRow(
                          cells: [
                            DataCell(Text(party.code)),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    party.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (party.city != null)
                                    Text(
                                      party.city!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text(party.pan)),
                            DataCell(Text(party.gstin ?? 'N/A')),
                            DataCell(
                              Chip(
                                label: Text(
                                  party.partyType.toString().split('.').last,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: _getPartyTypeColor(
                                  party.partyType,
                                ),
                              ),
                            ),
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

  Color _getPartyTypeColor(PartyType type) {
    switch (type) {
      case PartyType.company:
        return Colors.blue.shade100;
      case PartyType.nonCompany:
        return Colors.green.shade100;
      case PartyType.employee:
        return Colors.orange.shade100;
    }
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
                  'code': widget.party!.code,
                  'name': widget.party!.name,
                  'pan': widget.party!.pan,
                  'gstin': widget.party!.gstin,
                  'address': widget.party!.address,
                  'city': widget.party!.city,
                  'state': widget.party!.state,
                  'pin': widget.party!.pin,
                  'mobile': widget.party!.mobile,
                  'email': widget.party!.email,
                  'stateCode': widget.party!.stateCode,
                  'partyType': widget.party!.partyType,
                  'compType': widget.party!.compType,
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
                        name: 'code',
                        decoration: const InputDecoration(
                          labelText: 'Party Code *',
                          hintText: 'Enter unique code',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(2),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FormBuilderTextField(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderTextField(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'address',
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter complete address',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'city',
                        decoration: const InputDecoration(
                          labelText: 'City',
                          hintText: 'Enter city',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'state',
                        decoration: const InputDecoration(
                          labelText: 'State',
                          hintText: 'Enter state',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'pin',
                        decoration: const InputDecoration(
                          labelText: 'PIN Code',
                          hintText: '123456',
                        ),
                        validator: FormBuilderValidators.match(
                          RegExp(r'^[1-9][0-9]{5}$'),
                          errorText: 'Invalid PIN code',
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
                        name: 'mobile',
                        decoration: const InputDecoration(
                          labelText: 'Mobile',
                          hintText: '9876543210',
                        ),
                        validator: FormBuilderValidators.match(
                          RegExp(r'^[6-9][0-9]{9}$'),
                          errorText: 'Invalid mobile number',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'email',
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'email@domain.com',
                        ),
                        validator: FormBuilderValidators.email(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderDropdown<PartyType>(
                        name: 'partyType',
                        decoration: const InputDecoration(
                          labelText: 'Party Type *',
                        ),
                        validator: FormBuilderValidators.required(),
                        items: PartyType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.toString().split('.').last),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderDropdown<CompType>(
                        name: 'compType',
                        decoration: const InputDecoration(
                          labelText: 'Company Type *',
                        ),
                        validator: FormBuilderValidators.required(),
                        items: CompType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.toString().split('.').last),
                              ),
                            )
                            .toList(),
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

                        final party = Party(
                          id: isEditing ? widget.party!.id : null,
                          code: values['code'],
                          name: values['name'],
                          pan: values['pan'].toUpperCase(),
                          gstin: values['gstin']?.toUpperCase(),
                          address: values['address'],
                          city: values['city'],
                          state: values['state'],
                          pin: values['pin'],
                          mobile: values['mobile'],
                          email: values['email'],
                          stateCode: values['stateCode'],
                          partyType: values['partyType'],
                          compType: values['compType'],
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
