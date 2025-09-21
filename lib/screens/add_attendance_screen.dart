// lib/screens/add_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/models/attendance.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/customer_provider.dart'; // To select customers

class AddAttendanceScreen extends StatefulWidget {
  final Attendance? attendance; // Optional: for editing existing attendance

  const AddAttendanceScreen({super.key, this.attendance});

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.attendance != null;
    final customerProvider = Provider.of<CustomerProvider>(context);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'member_id': widget.attendance!.memberId,
        'checkin_time': widget.attendance!.checkinTime,
        'checkout_time': widget.attendance!.checkoutTime,
        'date': widget.attendance!.date,
        'facility_used': widget.attendance!.facilityUsed,
      };
    } else {
      initialValues = {
        'checkin_time': DateTime.now(),
        'date': DateTime.now(), // Default to today
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Attendance' : 'Add New Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          enabled: !customerProvider.isLoading, // Disable form if customers are loading
          child: ListView(
            children: [
              // Customer Selection
              FormBuilderDropdown<String>(
                name: 'member_id',
                decoration: const InputDecoration(labelText: 'Customer'),
                validator: (value) => value == null ? 'Please select a customer' : null,
                items: customerProvider.customers
                    .map((customer) => DropdownMenuItem<String>(
                          value: customer.customerId,
                          child: Text('${customer.firstName} ${customer.lastName} (${customer.email})'),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Check-in Time
              FormBuilderDateTimePicker(
                name: 'checkin_time',
                decoration: const InputDecoration(labelText: 'Check-in Time'),
                inputType: InputType.both,
                format: DateFormat('yyyy-MM-dd HH:mm'),
                validator: (value) => value == null ? 'Check-in time cannot be empty' : null,
                onChanged: (DateTime? newValue) {
                  // If check-in time changes, update the 'date' field to match its date part
                  if (newValue != null) {
                    _formKey.currentState?.fields['date']?.didChange(
                      DateTime(newValue.year, newValue.month, newValue.day),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              // Checkout Time (Optional)
              FormBuilderDateTimePicker(
                name: 'checkout_time',
                decoration: const InputDecoration(labelText: 'Check-out Time (Optional)'),
                inputType: InputType.both,
                format: DateFormat('yyyy-MM-dd HH:mm'),
                validator: (value) {
                  final checkin = _formKey.currentState?.fields['checkin_time']?.value as DateTime?;
                  if (value != null && checkin != null && value.isBefore(checkin)) {
                    return 'Check-out time cannot be before check-in time';
                  }
                  return null;
                },
              ),
              // Hidden Date field derived from checkin_time
              FormBuilderField(
                name: 'date',
                builder: (FormFieldState<DateTime?> field) => const SizedBox.shrink(), // Render nothing
                validator: (value) => value == null ? 'Date is required' : null,
              ),
              const SizedBox(height: 16),
              // Facility Used (Optional)
              FormBuilderTextField(
                name: 'facility_used',
                decoration: const InputDecoration(labelText: 'Facility Used (Optional)'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newAttendance = Attendance(
                      attendanceId: isEditing ? widget.attendance!.attendanceId : null,
                      memberId: data['member_id'],
                      checkinTime: data['checkin_time'],
                      checkoutTime: data['checkout_time'],
                      // 'date' is automatically derived in the model constructor from checkinTime,
                      // or explicitly passed if it was set in initialValues for editing.
                      date: data['date'],
                      facilityUsed: data['facility_used'],
                    );

                    if (isEditing) {
                      await Provider.of<AttendanceProvider>(context, listen: false).updateAttendance(newAttendance);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance record updated successfully!')),
                      );
                    } else {
                      await Provider.of<AttendanceProvider>(context, listen: false).addAttendance(newAttendance);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance record added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Attendance' : 'Add Attendance'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}