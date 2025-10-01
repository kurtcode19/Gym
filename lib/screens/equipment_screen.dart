// lib/screens/equipment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/equipment_provider.dart'; // Corrected import
import 'package:gym/models/equipment.dart'; // Corrected import
import 'package:gym/screens/add_equipment_screen.dart'; // Corrected import
import 'package:intl/intl.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'good':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'needs repair':
        return Colors.deepOrange;
      case 'out of service':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Equipment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search equipment...',
                prefixIcon: Icon(Icons.search),
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
                  return const Center(child: Text('No equipment found.'));
                } else {
                  return ListView.builder(
                    itemCount: equipmentProvider.equipmentList.length,
                    itemBuilder: (context, index) {
                      final equipment = equipmentProvider.equipmentList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getConditionColor(equipment.condition),
                            child: Text(
                              equipment.equipmentName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(equipment.equipmentName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Condition: ${equipment.condition ?? 'N/A'}'),
                              Text('Purchase Date: ${DateFormat('MMM d, yyyy').format(equipment.purchaseDate)}'),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEquipmentScreen(equipment: equipment),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, equipmentProvider, equipment);
                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEquipmentScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EquipmentProvider equipmentProvider, Equipment equipment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Equipment'),
          content: Text('Are you sure you want to delete "${equipment.equipmentName}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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