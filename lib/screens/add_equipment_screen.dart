// lib/screens/add_equipment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/equipment.dart';
import 'package:gym/providers/equipment_provider.dart';
import 'package:intl/intl.dart';

class AddEquipmentScreen extends StatefulWidget {
  final Equipment? equipment; 

  const AddEquipmentScreen({super.key, this.equipment});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.equipment != null;

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'equipment_name': widget.equipment!.equipmentName,
        'purchase_date': widget.equipment!.purchaseDate,
        'condition': widget.equipment!.condition,
      };
    } else {
      initialValues = {
        'purchase_date': DateTime.now(),
        'condition': 'Good', 
      };
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Equipment' : 'Add Equipment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FormBuilder(
            key: _formKey,
            initialValue: initialValues,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Equipment Details'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          name: 'equipment_name',
                          decoration: _fieldDecoration('Equipment Name', Icons.fitness_center),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        FormBuilderDateTimePicker(
                          name: 'purchase_date',
                          decoration: _fieldDecoration('Purchase Date', Icons.calendar_today),
                          inputType: InputType.date,
                          format: DateFormat('yyyy-MM-dd'),
                          validator: (value) => value == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Status & Condition'),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FormBuilderDropdown<String>(
                      name: 'condition',
                      decoration: _fieldDecoration('Condition', Icons.health_and_safety),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      items: const [
                        DropdownMenuItem(value: 'New', child: Text('New')),
                        DropdownMenuItem(value: 'Good', child: Text('Good')),
                        DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                        DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
                        DropdownMenuItem(value: 'Out of Service', child: Text('Out of Service')),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.saveAndValidate() ?? false) {
                        final data = _formKey.currentState!.value;
                        final newEquipment = Equipment(
                          equipmentId: isEditing ? widget.equipment!.equipmentId : null,
                          equipmentName: data['equipment_name'],
                          purchaseDate: data['purchase_date'],
                          condition: data['condition'],
                        );

                        try {
                          if (isEditing) {
                            await Provider.of<EquipmentProvider>(context, listen: false).updateEquipment(newEquipment);
                            if (context.mounted) _showSnackBar('Equipment updated successfully!');
                          } else {
                            await Provider.of<EquipmentProvider>(context, listen: false).addEquipment(newEquipment);
                            if (context.mounted) _showSnackBar('Equipment added successfully!');
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (context.mounted) _showSnackBar('Error: $e', isError: true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add Equipment',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}