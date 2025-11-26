// lib/screens/equipment_screen.dart
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Equipment Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search equipment...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                Provider.of<EquipmentProvider>(context, listen: false).searchEquipment(query);
              },
            ),
          ),

          Expanded(
            child: Consumer<EquipmentProvider>(
              builder: (context, equipmentProvider, child) {
                if (equipmentProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (equipmentProvider.equipmentList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No equipment found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: equipmentProvider.equipmentList.length,
                    itemBuilder: (context, index) {
                      final equipment = equipmentProvider.equipmentList[index];
                      final conditionColor = _getConditionColor(equipment.condition);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEquipmentScreen(equipment: equipment),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Icon Box
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center, // Generic icon or specific based on name
                                    color: Colors.blueGrey.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        equipment.equipmentName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Purchased: ${DateFormat('MMM d, yyyy').format(equipment.purchaseDate)}',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Condition & Action
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: conditionColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(_getConditionIcon(equipment.condition), size: 14, color: conditionColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            equipment.condition ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: conditionColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _confirmDelete(context, equipmentProvider, equipment),
                                      child: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEquipmentScreen(),
            ),
          );
        },
        label: const Text("New Equipment"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _confirmDelete(BuildContext context, EquipmentProvider equipmentProvider, Equipment equipment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Equipment?'),
          content: Text('Are you sure you want to delete "${equipment.equipmentName}"?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                equipmentProvider.deleteEquipment(equipment.equipmentId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${equipment.equipmentName} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}