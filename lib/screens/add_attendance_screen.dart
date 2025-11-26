// lib/screens/add_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/models/attendance.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_provider.dart'; // Import

class AddAttendanceScreen extends StatefulWidget {
  final Attendance? attendance; 

  const AddAttendanceScreen({super.key, this.attendance});

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  // Auto-select logic for the full screen form
  void _onCustomerSelected(String? customerId) {
    if (customerId == null) return;

    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    
    final hasActiveMembership = membershipProvider.memberships.any((m) => 
      m.membership.customerId == customerId && 
      m.membership.status.toLowerCase() == 'active' &&
      m.membership.endDate.isAfter(DateTime.now())
    );

    if (hasActiveMembership) {
      _formKey.currentState?.fields['type']?.didChange('Member');
      _formKey.currentState?.fields['amount_paid']?.didChange('0.00');
    } else {
      _formKey.currentState?.fields['type']?.didChange('Walk-In');
      _formKey.currentState?.fields['amount_paid']?.didChange('15.00');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.attendance != null;
    final customerProvider = Provider.of<CustomerProvider>(context);
    
    // Ensure memberships available for logic
    Provider.of<MembershipProvider>(context); 

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'member_id': widget.attendance!.memberId,
        'checkin_time': widget.attendance!.checkinTime,
        'checkout_time': widget.attendance!.checkoutTime,
        'date': widget.attendance!.date,
        'facility_used': widget.attendance!.facilityUsed,
        'type': widget.attendance!.type,
        'amount_paid': widget.attendance!.amountPaid.toStringAsFixed(2),
      };
    } else {
      initialValues = {
        'checkin_time': DateTime.now(),
        'date': DateTime.now(),
        'type': 'Member',
        'amount_paid': '0.00',
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
          enabled: !customerProvider.isLoading,
          child: ListView(
            children: [
              // 1. Customer Selection
              FormBuilderDropdown<String>(
                name: 'member_id',
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null ? 'Please select a customer' : null,
                items: customerProvider.customers
                    .map((customer) => DropdownMenuItem<String>(
                          value: customer.customerId,
                          child: Text('${customer.firstName} ${customer.lastName}'),
                        ))
                    .toList(),
                onChanged: (val) => _onCustomerSelected(val), // Trigger Logic
              ),
              const SizedBox(height: 16),

              // 2. Visit Type (Member vs Walk-In)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FormBuilderDropdown<String>(
                      name: 'type',
                      decoration: const InputDecoration(
                        labelText: 'Visit Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null ? 'Required' : null,
                      items: ['Member', 'Walk-In', 'Guest', 'Staff']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val == 'Walk-In') {
                          _formKey.currentState?.fields['amount_paid']?.didChange('15.00'); 
                        } else if (val == 'Member') {
                          _formKey.currentState?.fields['amount_paid']?.didChange('0.00');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 3. Amount Paid
                  Expanded(
                    flex: 2,
                    child: FormBuilderTextField(
                      name: 'amount_paid',
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) return 'Invalid #';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              // ... (Rest of the fields same as before: Checkin, Checkout, Facility) ...
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'checkin_time',
                decoration: const InputDecoration(labelText: 'Check-in Time', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                inputType: InputType.both,
                format: DateFormat('yyyy-MM-dd h:mm a'),
                validator: (value) => value == null ? 'Required' : null,
                onChanged: (DateTime? newValue) {
                  if (newValue != null) {
                    _formKey.currentState?.fields['date']?.didChange(DateTime(newValue.year, newValue.month, newValue.day));
                  }
                },
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'checkout_time',
                decoration: const InputDecoration(labelText: 'Check-out Time (Optional)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.exit_to_app)),
                inputType: InputType.both,
                format: DateFormat('yyyy-MM-dd h:mm a'),
              ),
              FormBuilderField(name: 'date', builder: (field) => const SizedBox.shrink()),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'facility_used',
                decoration: const InputDecoration(labelText: 'Facility Used (Optional)', border: OutlineInputBorder()),
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
                      date: data['date'],
                      facilityUsed: data['facility_used'],
                      type: data['type'],
                      amountPaid: double.tryParse(data['amount_paid'].toString()) ?? 0.0,
                    );

                    try {
                      if (isEditing) {
                        await Provider.of<AttendanceProvider>(context, listen: false).updateAttendance(newAttendance);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record updated!')));
                      } else {
                        await Provider.of<AttendanceProvider>(context, listen: false).addAttendance(newAttendance);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in!')));
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(isEditing ? 'Update Attendance' : 'Check In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}