// lib/screens/add_class_booking_screen.dart - UPDATED FOR EVENT CALENDAR

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/class_booking.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/models/class.dart'; // Correctly refers to your 'Class' model
import 'package:gym/models/trainer.dart'; // Import Trainer model
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar

class AddClassBookingScreen extends StatefulWidget {
  final ClassBooking? booking; // Optional: for editing existing booking

  const AddClassBookingScreen({super.key, this.booking});

  @override
  State<AddClassBookingScreen> createState() => _AddClassBookingScreenState();
}

class _AddClassBookingScreenState extends State<AddClassBookingScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedClassDate; // Date selected on the calendar
  String? _selectedTrainerId; // Trainer selected in filter dropdown
  String? _selectedClassIdForBooking; // The actual class_id for the booking
  
  // Add initial values map to handle pre-filling
  Map<String, dynamic> _initialValues = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    // Use a small delay to ensure widgets are built before accessing form state
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      final classProvider = Provider.of<ClassProvider>(context, listen: false);

      if (widget.booking != null) {
        // If editing, pre-fill values
        final currentClass = classProvider.classes.firstWhere(
          (dc) => dc.gymClass.classId == widget.booking!.classId,
          orElse: () => DetailedGymClass(gymClass: GymClass(className: '', scheduleTime: DateTime.now(), durationMinutes: 0)),
        ).gymClass;

        setState(() {
          _selectedClassDate = currentClass.scheduleTime;
          _focusedDay = currentClass.scheduleTime;
          _selectedTrainerId = currentClass.trainerId;
          _selectedClassIdForBooking = currentClass.classId; // Pre-select the class
        });

        // Apply initial filter
        classProvider.filterClasses(date: _selectedClassDate, trainerId: _selectedTrainerId);

        // Set initial values instead of using patch
        _initialValues = {
          'customer_id': widget.booking!.customerId,
          'booking_date': widget.booking!.bookingDate,
          'status': widget.booking!.status,
          'trainer_id_filter': _selectedTrainerId,
          'class_id': _selectedClassIdForBooking,
        };
      } else {
        // For new bookings, default to today
        _selectedClassDate = DateTime.now();
        classProvider.filterClasses(date: _selectedClassDate);
        
        _initialValues = {
          'booking_date': DateTime.now(),
          'status': 'Confirmed',
        };
      }
      
      // Trigger a rebuild to apply initial values
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Normalize selected day to remove time components for comparison with class dates
    final normalizedSelectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);

    if (!isSameDay(_selectedClassDate, normalizedSelectedDay)) {
      setState(() {
        _selectedClassDate = normalizedSelectedDay;
        _focusedDay = focusedDay; // Keep calendar focused on selected month
        _selectedClassIdForBooking = null; // Clear selected class when date changes
      });
      _applyFilter();
      
      // Update the form field when selection changes
      if (_formKey.currentState != null) {
        _formKey.currentState!.fields['class_id']?.didChange(null);
      }
    }
  }

  void _applyFilter() {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    classProvider.filterClasses(date: _selectedClassDate, trainerId: _selectedTrainerId);
    // When filters change, ensure selected class is still valid, else clear it
    if (_selectedClassIdForBooking != null &&
        !classProvider.classes.any((dc) => dc.gymClass.classId == _selectedClassIdForBooking)) {
      setState(() {
        _selectedClassIdForBooking = null;
      });
      // Also update the form field
      if (_formKey.currentState != null) {
        _formKey.currentState!.fields['class_id']?.didChange(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.booking != null ? 'Edit Class Booking' : 'Add Class Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: _initialValues, // Use initialValues instead of patch
          enabled: !customerProvider.isLoading && !classProvider.isLoading && !trainerProvider.isLoading,
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

              // TableCalendar for class date selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedClassDate, day),
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: (day) {
                      // Highlight days that have classes
                      final normalizedDay = DateTime.utc(day.year, day.month, day.day);
                      return classProvider.classDates.contains(normalizedDay) ? [true] : [];
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Display selected date for clarity and trainer filter
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Date:', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          _selectedClassDate != null
                              ? DateFormat('EEE, MMM d, yyyy').format(_selectedClassDate!)
                              : 'No date selected',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FormBuilderDropdown<String>(
                      name: 'trainer_id_filter',
                      decoration: const InputDecoration(labelText: 'Filter by Trainer'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Trainers')),
                        ...trainerProvider.trainers
                            .map((trainer) => DropdownMenuItem<String>(
                                  value: trainer.trainerId,
                                  child: Text('${trainer.firstName} ${trainer.lastName}'),
                                ))
                            .toList(),
                      ],
                      onChanged: (trainerId) {
                        setState(() {
                          _selectedTrainerId = trainerId;
                          _selectedClassIdForBooking = null; // Clear selected class when trainer changes
                        });
                        _applyFilter();
                        // Update the form field
                        if (_formKey.currentState != null) {
                          _formKey.currentState!.fields['class_id']?.didChange(null);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // List of Available Classes (Event Calendar View)
              Text(
                'Available Classes for selected date:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              classProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : classProvider.classes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                              child: Text(
                            'No classes found for this date/trainer.',
                            style: TextStyle(color: Colors.grey),
                          )),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: classProvider.classes.length,
                          itemBuilder: (context, index) {
                            final detailedClass = classProvider.classes[index];
                            final isSelected = _selectedClassIdForBooking == detailedClass.gymClass.classId;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              elevation: isSelected ? 8 : 2, // Highlight selected
                              color: isSelected ? Colors.deepOrange.shade100 : Colors.white,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedClassIdForBooking = detailedClass.gymClass.classId;
                                  });
                                  // Update the FormBuilder field
                                  if (_formKey.currentState != null) {
                                    _formKey.currentState!.fields['class_id']?.didChange(detailedClass.gymClass.classId);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detailedClass.gymClass.className,
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.deepOrange : null,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Time: ${DateFormat('h:mm a').format(detailedClass.gymClass.scheduleTime)} '
                                        '(${detailedClass.gymClass.durationMinutes} min)',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        'Trainer: ${detailedClass.trainerFullName}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 16),

              // Hidden FormBuilderField to hold the selected class_id
              FormBuilderField<String>(
                name: 'class_id',
                validator: (value) => value == null ? 'Please select a class from the list above' : null,
                builder: (FormFieldState<String?> field) {
                  // This field is mostly for validation and to hold the value for FormBuilder.
                  // Its UI is handled by the interactive list above.
                  // We update its value manually when a class card is tapped.
                  return const SizedBox.shrink(); // Hide the actual field widget
                },
              ),
              const SizedBox(height: 16),

              // Booking Date (when the booking action was made)
              FormBuilderDateTimePicker(
                name: 'booking_date',
                decoration: const InputDecoration(labelText: 'Booking Creation Date'),
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
                  // Manually trigger validation of the hidden class_id field
                  _formKey.currentState?.fields['class_id']?.validate();

                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newBooking = ClassBooking(
                      bookingId: widget.booking != null ? widget.booking!.bookingId : null,
                      customerId: data['customer_id'],
                      classId: data['class_id'], // This now comes from _selectedClassIdForBooking via the hidden field
                      bookingDate: data['booking_date'],
                      status: data['status'],
                    );

                    try {
                      if (widget.booking != null) {
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
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving booking: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please correct the errors in the form.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(widget.booking != null ? 'Update Booking' : 'Add Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}