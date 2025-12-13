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
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.equipment != null;

    final initialValues = isEditing
        ? {
            'equipment_name': widget.equipment!.equipmentName,
            'purchase_date': widget.equipment!.purchaseDate,
            'condition': widget.equipment!.condition,
          }
        : {
            'purchase_date': DateTime.now(),
            'condition': 'Good',
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // -----------------------------------------------------------------
      // PREMIUM APP BAR
      // -----------------------------------------------------------------
      appBar: AppBar(
        elevation: 8,
        backgroundColor: Colors.white,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(.15),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isEditing ? "Edit Equipment" : "Add Equipment",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("Equipment Details"),

              // -----------------------------------------------------------------
              // DETAILS CARD
              // -----------------------------------------------------------------
              Card(
                elevation: 3,
                shadowColor: Colors.black.withOpacity(.07),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'equipment_name',
                        decoration: _fieldDecoration(
                            'Equipment Name', Icons.fitness_center),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),

                      const SizedBox(height: 18),

                      FormBuilderDateTimePicker(
                        name: 'purchase_date',
                        decoration: _fieldDecoration(
                            'Purchase Date', Icons.calendar_today),
                        inputType: InputType.date,
                        format: DateFormat('yyyy-MM-dd'),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              _sectionHeader("Status & Condition"),

              // -----------------------------------------------------------------
              // CONDITION CARD
              // -----------------------------------------------------------------
              Card(
                elevation: 3,
                shadowColor: Colors.black.withOpacity(.07),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FormBuilderDropdown<String>(
                    name: 'condition',
                    decoration:
                        _fieldDecoration('Condition', Icons.health_and_safety),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                    items: const [
                      DropdownMenuItem(value: 'New', child: Text('New')),
                      DropdownMenuItem(value: 'Good', child: Text('Good')),
                      DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                      DropdownMenuItem(
                          value: 'Needs Repair', child: Text('Needs Repair')),
                      DropdownMenuItem(
                          value: 'Out of Service', child: Text('Out of Service')),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // -----------------------------------------------------------------
              // SUBMIT BUTTON
              // -----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final data = _formKey.currentState!.value;
                      final newEquipment = Equipment(
                        equipmentId:
                            isEditing ? widget.equipment!.equipmentId : null,
                        equipmentName: data['equipment_name'],
                        purchaseDate: data['purchase_date'],
                        condition: data['condition'],
                      );

                      try {
                        final provider = Provider.of<EquipmentProvider>(context,
                            listen: false);

                        if (isEditing) {
                          await provider.updateEquipment(newEquipment);
                          _showSnackBar("Equipment updated!");
                        } else {
                          await provider.addEquipment(newEquipment);
                          _showSnackBar("Equipment added!");
                        }

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        _showSnackBar("Error: $e", isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEditing ? "Save Changes" : "Add Equipment",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // SECTION HEADER
  // -----------------------------------------------------------------
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // SNACKBAR
  // -----------------------------------------------------------------
  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
