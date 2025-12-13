import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/equipment_provider.dart';
import 'package:gym/models/equipment.dart';
import 'package:gym/screens/add_equipment_screen.dart';
import 'package:intl/intl.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'new': return Colors.blue;
      case 'good': return Colors.green;
      case 'fair': return Colors.orange;
      case 'needs repair': return Colors.deepOrange;
      case 'out of service': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getConditionIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'new': return Icons.fiber_new;
      case 'good': return Icons.check_circle_outline;
      case 'fair': return Icons.warning_amber;
      case 'needs repair': return Icons.build;
      case 'out of service': return Icons.block;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ░░░ APP BAR (Dark Back Button) ░░░
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        shadowColor: Colors.black26,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Equipment Inventory",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: Column(
        children: [
          // ░░░ SEARCH BAR ░░░
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search equipment...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                Provider.of<EquipmentProvider>(context, listen: false)
                    .searchEquipment(query);
              },
            ),
          ),

          const SizedBox(height: 8),

          // ░░░ LIST VIEW ░░░
          Expanded(
            child: Consumer<EquipmentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.equipmentList.isEmpty) {
                  return _emptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.equipmentList.length,
                  itemBuilder: (context, index) {
                    final equipment = provider.equipmentList[index];
                    final conditionColor =
                        _getConditionColor(equipment.condition);

                    return _equipmentCard(
                      context,
                      provider,
                      equipment,
                      conditionColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ░░░ ADD EQUIPMENT BUTTON ░░░
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        label: const Text("New Equipment"),
        icon: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEquipmentScreen(),
            ),
          );
        },
      ),
    );
  }

  // ░░░ EMPTY STATE ░░░
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No equipment found",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ░░░ EQUIPMENT CARD UI ░░░
  Widget _equipmentCard(
    BuildContext context,
    EquipmentProvider provider,
    Equipment equipment,
    Color conditionColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON BADGE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center,
                color: Colors.blueGrey.shade700, size: 28),
          ),

          const SizedBox(width: 14),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.equipmentName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      "Purchased: ${DateFormat('MMM d, yyyy').format(equipment.purchaseDate)}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CONDITION + DELETE
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: conditionColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getConditionIcon(equipment.condition),
                      size: 14,
                      color: conditionColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      equipment.condition ?? "Unknown",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: conditionColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: () =>
                    _confirmDelete(context, provider, equipment),
                child: Icon(Icons.delete_outline,
                    size: 22, color: Colors.grey[500]),
              )
            ],
          ),
        ],
      ),
    );
  }

  // ░░░ CONFIRM DELETE ░░░
  void _confirmDelete(
      BuildContext context, EquipmentProvider provider, Equipment equipment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Equipment?"),
        content: Text(
            'Are you sure you want to delete "${equipment.equipmentName}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteEquipment(equipment.equipmentId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text("${equipment.equipmentName} deleted successfully")),
              );
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
