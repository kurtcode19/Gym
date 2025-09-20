// lib/screens/add_trainer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:intl/intl.dart';

class AddTrainerScreen extends StatefulWidget {
  final Trainer? trainer; // Optional: for editing existing trainer

  const AddTrainerScreen({super.key, this.trainer});

  @override
  State<AddTrainerScreen> createState() => _AddTrainerScreenState();
}

class _AddTrainerScreenState extends State<AddTrainerScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

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
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Trainer' : 'Add Trainer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'first_name',
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.isEmpty ? 'First name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'last_name',
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.isEmpty ? 'Last name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'email',
                decoration: const InputDecoration(labelText: 'Email (Optional)'),
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
                decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'hire_date',
                decoration: const InputDecoration(labelText: 'Hire Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Hire date cannot be empty' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
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

                    if (isEditing) {
                      await Provider.of<TrainerProvider>(context, listen: false).updateTrainer(newTrainer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newTrainer.firstName} updated successfully!')),
                      );
                    } else {
                      await Provider.of<TrainerProvider>(context, listen: false).addTrainer(newTrainer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newTrainer.firstName} added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Trainer' : 'Add Trainer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}