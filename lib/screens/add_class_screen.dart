// lib/screens/add_class_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/class.dart';
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

  bool _isRecurring = false;
  List<int> _selectedWeekdays = [];
  DateTime? _recurrenceEndDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.gymClass == null) {
      _recurrenceEndDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  // ---------------------------------------------------------
  // PREMIUM INPUT DECORATION
  // ---------------------------------------------------------
  InputDecoration _premiumField(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.gymClass != null;
    final trainerProvider = Provider.of<TrainerProvider>(context);

    final initialValues = isEditing
        ? {
            "class_name": widget.gymClass!.className,
            "trainer_id": widget.gymClass!.trainerId,
            "schedule_time": widget.gymClass!.scheduleTime,
            "duration_minutes": widget.gymClass!.durationMinutes.toString(),
          }
        : {
            "schedule_time": DateTime.now()
                .add(const Duration(hours: 1))
                .copyWith(minute: 0, second: 0, millisecond: 0),
            "duration_minutes": "60",
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(.08),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isEditing ? "Edit Class Session" : "Schedule Class",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(isEditing),
              const SizedBox(height: 24),

              _sectionTitle("Class Details"),
              _classDetails(trainerProvider),

              const SizedBox(height: 24),

              _sectionTitle("Timing"),
              _timingInputs(isEditing),

              const SizedBox(height: 24),

              if (!isEditing) _recurringToggle(),
              if (!isEditing) _recurringOptions(),

              const SizedBox(height: 32),

              _submitButton(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // HEADER CARD
  // ---------------------------------------------------------
  Widget _header(bool isEditing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFE9F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: const Icon(Icons.schedule,
                size: 40, color: Colors.blueAccent),
          ),
          const SizedBox(height: 12),
          Text(
            isEditing ? "Update Class Session" : "Create New Class",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // CLASS DETAILS
  // ---------------------------------------------------------
  Widget _classDetails(TrainerProvider trainerProvider) {
    return _premiumCard(
      Column(
        children: [
          FormBuilderTextField(
            name: "class_name",
            decoration: _premiumField("Class Name", Icons.fitness_center),
            validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),

          FormBuilderDropdown<String>(
            name: "trainer_id",
            decoration: _premiumField("Trainer", Icons.person),
            items: [
              const DropdownMenuItem(value: null, child: Text("Unassigned")),
              ...trainerProvider.trainers.map(
                (t) => DropdownMenuItem(
                  value: t.trainerId,
                  child: Text("${t.firstName} ${t.lastName}"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // TIMING
  // ---------------------------------------------------------
  Widget _timingInputs(bool isEditing) {
    return _premiumCard(
      Column(
        children: [
          FormBuilderDateTimePicker(
            name: "schedule_time",
            inputType: InputType.both,
            decoration: _premiumField("Date & Time", Icons.calendar_today),
            format: DateFormat("EEE, MMM d, yyyy - h:mm a"),
            validator: (v) {
              if (v == null) return "Required";
              if (!isEditing && v.isBefore(DateTime.now())) {
                return "Must be in the future";
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          FormBuilderTextField(
            name: "duration_minutes",
            keyboardType: TextInputType.number,
            decoration: _premiumField("Duration (min)", Icons.timer),
            validator: (v) {
              if (v == null || v.isEmpty) return "Required";
              final val = int.tryParse(v);
              if (val == null) return "Invalid number";
              if (val < 30) return "Min 30 minutes";
              if (val > 300) return "Max 300 minutes";
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // RECURRING SWITCH
  // ---------------------------------------------------------
  Widget _recurringToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle("Recurring Schedule?"),
        Switch(
          value: _isRecurring,
          activeColor: Colors.blueAccent,
          onChanged: (v) => setState(() => _isRecurring = v),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // RECURRING OPTIONS
  // ---------------------------------------------------------
  Widget _recurringOptions() {
    if (!_isRecurring) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _premiumCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Repeat on days:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 10,
              children: [
                _dayChip("M", DateTime.monday),
                _dayChip("T", DateTime.tuesday),
                _dayChip("W", DateTime.wednesday),
                _dayChip("Th", DateTime.thursday),
                _dayChip("F", DateTime.friday),
                _dayChip("Sa", DateTime.saturday),
                _dayChip("Su", DateTime.sunday),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              "Until:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            FormBuilderDateTimePicker(
              name: "recurrence_end",
              inputType: InputType.date,
              decoration: _premiumField("End Date", Icons.event_repeat),
              validator: (v) {
                if (_isRecurring && v == null) return "Required";
                return null;
              },
              onChanged: (v) => _recurrenceEndDate = v,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // DAY CHIP
  // ---------------------------------------------------------
  Widget _dayChip(String label, int weekday) {
    final selected = _selectedWeekdays.contains(weekday);

    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: Colors.blueAccent,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (v) {
        setState(() {
          if (v) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
    );
  }

  // ---------------------------------------------------------
  // SUBMIT BUTTON
  // ---------------------------------------------------------
  Widget _submitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _handleSave(isEditing),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isEditing
                    ? "Update Session"
                    : (_isRecurring ? "Generate Classes" : "Schedule Class"),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------
  // SAVE LOGIC (NOW FULLY CONFLICT-AWARE)
  // ---------------------------------------------------------
  Future<void> _handleSave(bool isEditing) async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final data = _formKey.currentState!.value;
    final provider = Provider.of<ClassProvider>(context, listen: false);

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        // ---------- SINGLE UPDATE ----------
        final updated = GymClass(
          classId: widget.gymClass!.classId,
          className: data["class_name"],
          trainerId: data["trainer_id"],
          scheduleTime: data["schedule_time"],
          durationMinutes: int.parse(data["duration_minutes"]),
        );

        final conflict = provider.validateFullConflict(
          updated,
          excludeId: updated.classId,
        );

        if (conflict != null) {
          _showErrorDialog(conflict);
          setState(() => _isSaving = false);
          return;
        }

        await provider.updateGymClass(updated);
        _showSnack("Class updated!");
        Navigator.pop(context);
      } else {
        // ---------- NEW CLASS / RECURRING ----------
        List<GymClass> sessions = [];

        final base = GymClass(
          classId: const Uuid().v4(),
          className: data["class_name"],
          trainerId: data["trainer_id"],
          scheduleTime: data["schedule_time"],
          durationMinutes: int.parse(data["duration_minutes"]),
        );

        if (!_isRecurring) {
          sessions.add(base);
        } else {
          DateTime start = data["schedule_time"];
          DateTime end = data["recurrence_end"];

          if (end.isBefore(start)) end = start;

          DateTime pointer = start;

          while (!pointer.isAfter(end)) {
            if (_selectedWeekdays.contains(pointer.weekday)) {
              sessions.add(GymClass(
                classId: const Uuid().v4(),
                className: base.className,
                trainerId: base.trainerId,
                scheduleTime: pointer,
                durationMinutes: base.durationMinutes,
              ));
            }
            pointer = pointer.add(const Duration(days: 1));
          }
        }

        // Validate all at once
        final conflicts = provider.validateBatchSchedule(sessions);
        if (conflicts.isNotEmpty) {
          _showErrorDialog(conflicts.first);
          setState(() => _isSaving = false);
          return;
        }

        await provider.addBatchGymClasses(sessions);
        _showSnack("Classes created!");
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack("Error: $e", true);
    }

    setState(() => _isSaving = false);
  }

  // ---------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------
  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 10),
            Text("Schedule Conflict"),
          ],
        ),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------
  // PREMIUM CARD
  // ---------------------------------------------------------
  Widget _premiumCard(Widget child) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }

  // ---------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
