// lib/screens/add_equipment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/equipment.dart'; // Corrected import
import 'package:gym/providers/equipment_provider.dart'; // Corrected import
import 'package:intl/intl.dart';

class AddEquipmentScreen extends StatefulWidget {
  final Equipment? equipment; // Optional: for editing existing equipment

  const AddEquipmentScreen({super.key, this.equipment});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

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
        'condition': 'Good', // Default for new equipment
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Equipment' : 'Add New Equipment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'equipment_name',
                decoration: const InputDecoration(labelText: 'Equipment Name'),
                validator: (value) => value == null || value.isEmpty ? 'Equipment name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'purchase_date',
                decoration: const InputDecoration(labelText: 'Purchase Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Purchase date cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'condition',
                decoration: const InputDecoration(labelText: 'Condition'),
                validator: (value) => value == null || value.isEmpty ? 'Condition cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'New', child: Text('New')),
                  DropdownMenuItem(value: 'Good', child: Text('Good')),
                  DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                  DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
                  DropdownMenuItem(value: 'Out of Service', child: Text('Out of Service')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newEquipment = Equipment(
                      equipmentId: isEditing ? widget.equipment!.equipmentId : null,
                      equipmentName: data['equipment_name'],
                      purchaseDate: data['purchase_date'],
                      condition: data['condition'],
                    );

                    if (isEditing) {
                      await Provider.of<EquipmentProvider>(context, listen: false).updateEquipment(newEquipment);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newEquipment.equipmentName} updated successfully!')),
                      );
                    } else {
                      await Provider.of<EquipmentProvider>(context, listen: false).addEquipment(newEquipment);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newEquipment.equipmentName} added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Equipment' : 'Add Equipment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}