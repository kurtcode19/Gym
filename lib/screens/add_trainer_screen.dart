// lib/screens/add_trainer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:intl/intl.dart';

class AddTrainerScreen extends StatefulWidget {
  final Trainer? trainer; 

  const AddTrainerScreen({super.key, this.trainer});

  @override
  State<AddTrainerScreen> createState() => _AddTrainerScreenState();
}

class _AddTrainerScreenState extends State<AddTrainerScreen> {
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
    final isEditing = widget.trainer != null;

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'first_name': widget.trainer!.firstName,
        'last_name': widget.trainer!.lastName,
        'email': widget.trainer!.email,
        'phone_number': widget.trainer!.phoneNumber,
        'hire_date': widget.trainer!.hireDate,
      };
    } else {
      initialValues = {
        'hire_date': DateTime.now(),
      };
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Profile' : 'New Trainer'),
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
                _buildSectionHeader('Personal Information'),
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
                          name: 'first_name',
                          decoration: _fieldDecoration('First Name', Icons.person),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'last_name',
                          decoration: _fieldDecoration('Last Name', Icons.person_outline),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        FormBuilderDateTimePicker(
                          name: 'hire_date',
                          decoration: _fieldDecoration('Date Hired', Icons.date_range),
                          inputType: InputType.date,
                          format: DateFormat('yyyy-MM-dd'),
                          validator: (value) => value == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Contact Details'),
                
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
                          name: 'email',
                          decoration: _fieldDecoration('Email Address', Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'phone_number',
                          decoration: _fieldDecoration('Phone Number', Icons.phone),
                          keyboardType: TextInputType.phone,
                        ),
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
                        final newTrainer = Trainer(
                          trainerId: isEditing ? widget.trainer!.trainerId : null,
                          firstName: data['first_name'],
                          lastName: data['last_name'],
                          email: data['email'],
                          phoneNumber: data['phone_number'],
                          hireDate: data['hire_date'],
                        );

                        try {
                          if (isEditing) {
                            await Provider.of<TrainerProvider>(context, listen: false).updateTrainer(newTrainer);
                            if (context.mounted) _showSnackBar('Trainer updated successfully!');
                          } else {
                            await Provider.of<TrainerProvider>(context, listen: false).addTrainer(newTrainer);
                            if (context.mounted) _showSnackBar('Trainer added successfully!');
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
                      isEditing ? 'Save Changes' : 'Add Trainer',
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