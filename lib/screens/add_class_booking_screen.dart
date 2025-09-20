// lib/screens/add_class_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/class_booking.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/models/class.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:intl/intl.dart';

class AddClassBookingScreen extends StatefulWidget {
  final ClassBooking? booking; // Optional: for editing existing booking

  const AddClassBookingScreen({super.key, this.booking});

  @override
  State<AddClassBookingScreen> createState() => _AddClassBookingScreenState();
}

class _AddClassBookingScreenState extends State<AddClassBookingScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.booking != null;
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final classProvider = Provider.of<ClassProvider>(context, listen: false);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'customer_id': widget.booking!.customerId,
        'class_id': widget.booking!.classId,
        'booking_date': widget.booking!.bookingDate,
        'status': widget.booking!.status,
      };
    } else {
      initialValues = {
        'booking_date': DateTime.now(),
        'status': 'Confirmed', // Default status
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Class Booking' : 'Add Class Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              // Customer Selection
              FormBuilderDropdown<String>(
                name: 'customer_id',
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
              // Class Selection
              FormBuilderDropdown<String>(
                name: 'class_id',
                decoration: const InputDecoration(labelText: 'Class'),
                validator: (value) => value == null ? 'Please select a class' : null,
                items: classProvider.classes
                    .map((detailedClass) => DropdownMenuItem<String>(
                          value: detailedClass.gymClass.classId,
                          child: Text(
                            '${detailedClass.gymClass.className} '
                            '(${DateFormat('MMM d, h:mm a').format(detailedClass.gymClass.scheduleTime)})',
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Booking Date (can be different from class schedule date)
              FormBuilderDateTimePicker(
                name: 'booking_date',
                decoration: const InputDecoration(labelText: 'Booking Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Booking date cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              // Status
              FormBuilderDropdown<String>(
                name: 'status',
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) => value == null || value.isEmpty ? 'Status cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'Attended', child: Text('Attended')),
                  DropdownMenuItem(value: 'No Show', child: Text('No Show')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newBooking = ClassBooking(
                      bookingId: isEditing ? widget.booking!.bookingId : null,
                      customerId: data['customer_id'],
                      classId: data['class_id'],
                      bookingDate: data['booking_date'],
                      status: data['status'],
                    );

                    if (isEditing) {
                      await Provider.of<ClassBookingProvider>(context, listen: false).updateClassBooking(newBooking);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking updated successfully!')),
                      );
                    } else {
                      await Provider.of<ClassBookingProvider>(context, listen: false).addClassBooking(newBooking);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Booking' : 'Add Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}