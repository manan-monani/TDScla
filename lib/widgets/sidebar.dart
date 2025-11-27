import 'package:flutter/material.dart';

class TDSSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const TDSSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            height: 60,
            color: Theme.of(context).primaryColor,
            child: const Center(
              child: Text(
                'TDS Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(context, 'Dashboard', Icons.dashboard, 0),
                _buildMenuItem(context, 'Party Master', Icons.people, 1),
                _buildMenuItem(context, 'GST-TDS Entry', Icons.receipt, 2),
                _buildMenuItem(
                  context,
                  'GSTR-7 Generation',
                  Icons.file_download,
                  3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    int index,
  ) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () => onItemSelected(index),
    );
  }
}
