// lib/screens/add_class_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/class.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:intl/intl.dart';

class AddClassScreen extends StatefulWidget {
  final GymClass? gymClass; // Optional: for editing existing class

  const AddClassScreen({super.key, this.gymClass});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.gymClass != null;
    final trainerProvider = Provider.of<TrainerProvider>(context, listen: false);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'trainer_id': widget.gymClass!.trainerId,
        'class_name': widget.gymClass!.className,
        'schedule_time': widget.gymClass!.scheduleTime,
        'duration_minutes': widget.gymClass!.durationMinutes.toString(),
      };
    } else {
      initialValues = {
        'schedule_time': DateTime.now().add(const Duration(hours: 1)), // Default to 1 hour from now
        'duration_minutes': '60', // Default 60 minutes
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Class' : 'Add New Class'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'class_name',
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) => value == null || value.isEmpty ? 'Class name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'trainer_id',
                decoration: const InputDecoration(labelText: 'Trainer (Optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned')), // Option for no trainer
                  ...trainerProvider.trainers
                      .map((trainer) => DropdownMenuItem<String>(
                            value: trainer.trainerId,
                            child: Text('${trainer.firstName} ${trainer.lastName}'),
                          ))
                      .toList(),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'schedule_time',
                decoration: const InputDecoration(labelText: 'Schedule Time'),
                inputType: InputType.both,
                format: DateFormat('yyyy-MM-dd HH:mm'),
                validator: (value) => value == null ? 'Schedule time cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'duration_minutes',
                decoration: const InputDecoration(labelText: 'Duration (minutes)', hintText: 'e.g., 60'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Duration cannot be empty';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  if (int.parse(value) <= 0) return 'Duration must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newClass = GymClass(
                      classId: isEditing ? widget.gymClass!.classId : null,
                      className: data['class_name'],
                      trainerId: data['trainer_id'],
                      scheduleTime: data['schedule_time'],
                      durationMinutes: int.parse(data['duration_minutes']),
                    );

                    if (isEditing) {
                      await Provider.of<ClassProvider>(context, listen: false).updateGymClass(newClass);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newClass.className} updated successfully!')),
                      );
                    } else {
                      await Provider.of<ClassProvider>(context, listen: false).addGymClass(newClass);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newClass.className} added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Class' : 'Add Class'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}