// lib/screens/add_class_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/class.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddClassScreen extends StatefulWidget {
  final GymClass? gymClass;

  const AddClassScreen({super.key, this.gymClass});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  
  // Recurrence State
  bool _isRecurring = false;
  List<int> _selectedWeekdays = []; // 1 = Mon, 7 = Sun
  DateTime? _recurrenceEndDate;
  bool _isSaving = false;

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
  void initState() {
    super.initState();
    // Disable recurrence editing if we are editing an existing specific class
    if (widget.gymClass != null) {
      _isRecurring = false;
    } else {
      _recurrenceEndDate = DateTime.now().add(const Duration(days: 30)); // Default 1 month
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.gymClass != null;
    final trainerProvider = Provider.of<TrainerProvider>(context);

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
        'schedule_time': DateTime.now().add(const Duration(hours: 1)).copyWith(minute: 0, second: 0, millisecond: 0),
        'duration_minutes': '60',
      };
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Class Session' : 'Schedule Class'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Basic Info
              _buildSectionHeader('Class Details'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'class_name',
                        decoration: _fieldDecoration('Class Name', Icons.fitness_center),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<String>(
                        name: 'trainer_id',
                        decoration: _fieldDecoration('Trainer', Icons.person),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Unassigned')), 
                          ...trainerProvider.trainers.map((t) => DropdownMenuItem(value: t.trainerId, child: Text('${t.firstName} ${t.lastName}'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              // 2. Schedule
              _buildSectionHeader('Timing'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // If recurring, this acts as "Start Date/Time"
                      FormBuilderDateTimePicker(
                        name: 'schedule_time',
                        decoration: _fieldDecoration(
                          _isRecurring ? 'First Class Date & Time' : 'Date & Time', 
                          Icons.calendar_today
                        ),
                        inputType: InputType.both,
                        format: DateFormat('EEE, MMM d, yyyy - h:mm a'),
                        validator: (value) {
                          if (value == null) return 'Required';
                          if (value.isBefore(DateTime.now()) && !isEditing) return 'Must be in future';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'duration_minutes',
                        decoration: _fieldDecoration('Duration (min)', Icons.timer),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final val = int.tryParse(value);
                          if (val == null) return 'Invalid number';
                          // ERROR TRAPPING: Range check
                          if (val < 30) return 'Min 30 mins';
                          if (val > 120) return 'Max 120 mins';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Recurrence Options (Only for new classes)
              if (!isEditing) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Recurring Schedule?'),
                    Switch(
                      value: _isRecurring, 
                       inactiveThumbColor: Colors.grey[700], // Color of the circle when inactive
      inactiveTrackColor: Colors.grey[300], // Color of the track when inactive
                      activeColor: Colors.blue,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                  ],
                ),
                
                if (_isRecurring)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      elevation: 0,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.shade100)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Repeat on days:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildDayChip('M', 1),
                                _buildDayChip('T', 2),
                                _buildDayChip('W', 3),
                                _buildDayChip('T', 4),
                                _buildDayChip('F', 5),
                                _buildDayChip('S', 6),
                                _buildDayChip('S', 7),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text("Until:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            FormBuilderDateTimePicker(
                              name: 'recurrence_end',
                              initialValue: _recurrenceEndDate,
                              inputType: InputType.date,
                              decoration: _fieldDecoration('End Date', Icons.event_repeat),
                              validator: (val) {
                                if (_isRecurring && val == null) return 'End date required';
                                return null;
                              },
                              onChanged: (val) => _recurrenceEndDate = val,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _handleSave(isEditing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'Update Session' : (_isRecurring ? 'Generate Classes' : 'Schedule Class'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int weekday) {
    final isSelected = _selectedWeekdays.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
      checkmarkColor: Colors.white,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }

  Future<void> _handleSave(bool isEditing) async {
    if (!_formKey.currentState!.saveAndValidate()) return;
    
    if (_isRecurring && _selectedWeekdays.isEmpty) {
      _showSnackBar('Please select at least one day for recurrence.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final data = _formKey.currentState!.value;
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    
    try {
      if (isEditing) {
        // --- SINGLE UPDATE LOGIC ---
        final updatedClass = GymClass(
          classId: widget.gymClass!.classId,
          className: data['class_name'],
          trainerId: data['trainer_id'],
          scheduleTime: data['schedule_time'],
          durationMinutes: int.parse(data['duration_minutes']),
        );

        final error = classProvider.validateClassSchedule(updatedClass);
        if (error != null) {
          _showErrorDialog(error);
          setState(() => _isSaving = false);
          return;
        }

        await classProvider.updateGymClass(updatedClass);
        if (mounted) {
          _showSnackBar('Class updated!');
          Navigator.pop(context);
        }
      } else {
        // --- CREATE LOGIC (Single or Recurring) ---
        List<GymClass> classesToCreate = [];
        
        if (!_isRecurring) {
          // Single Class
          classesToCreate.add(GymClass(
            classId: const Uuid().v4(),
            className: data['class_name'],
            trainerId: data['trainer_id'],
            scheduleTime: data['schedule_time'],
            durationMinutes: int.parse(data['duration_minutes']),
          ));
        } else {
          // Recurring Logic
          DateTime current = data['schedule_time'];
          DateTime end = data['recurrence_end'];
          // Ensure we don't go into infinite loop if dates are wrong
          if (end.isBefore(current)) end = current; 

          // Loop through days
          while (current.isBefore(end.add(const Duration(days: 1)))) {
            if (_selectedWeekdays.contains(current.weekday)) {
              classesToCreate.add(GymClass(
                classId: const Uuid().v4(),
                className: data['class_name'],
                trainerId: data['trainer_id'],
                scheduleTime: current,
                durationMinutes: int.parse(data['duration_minutes']),
              ));
            }
            current = current.add(const Duration(days: 1));
          }
        }

        if (classesToCreate.isEmpty) {
           _showSnackBar('No dates matched your selection.', isError: true);
           setState(() => _isSaving = false);
           return;
        }

        // Validate Batch
        final errors = classProvider.validateBatchSchedule(classesToCreate);
        if (errors.isNotEmpty) {
          // Show just the first few errors
          _showErrorDialog("Conflicts found:\n${errors.take(3).join('\n')}${errors.length > 3 ? '\n...and ${errors.length - 3} more' : ''}");
          setState(() => _isSaving = false);
          return;
        }

        // Save Batch
        await classProvider.addBatchGymClasses(classesToCreate);
        if (mounted) {
          _showSnackBar('Scheduled ${classesToCreate.length} class sessions!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text("Schedule Conflict")]),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
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