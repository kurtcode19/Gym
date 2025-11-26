// lib/screens/add_class_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/class_booking.dart';
import 'package:gym/models/class.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/trainer_package_provider.dart'; // NEW IMPORT
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AddClassBookingScreen extends StatefulWidget {
  final ClassBooking? booking;

  const AddClassBookingScreen({super.key, this.booking});

  @override
  State<AddClassBookingScreen> createState() => _AddClassBookingScreenState();
}

class _AddClassBookingScreenState extends State<AddClassBookingScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedClassDate;
  String? _selectedTrainerId;
  String? _selectedClassIdForBooking;
  Map<String, dynamic> _initialValues = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      Provider.of<MembershipProvider>(context, listen: false).fetchMemberships(); 
      // Also fetch packages to ensure up-to-date status
      Provider.of<TrainerPackageProvider>(context, listen: false).fetchPackages();

      if (widget.booking != null) {
        GymClass? currentClass;
        try {
           final detailedClass = classProvider.classes.firstWhere((dc) => dc.gymClass.classId == widget.booking!.classId);
           currentClass = detailedClass.gymClass;
        } catch(e) {
           // Handle class not found
        }

        if (currentClass != null) {
          setState(() {
            _selectedClassDate = currentClass!.scheduleTime;
            _focusedDay = currentClass!.scheduleTime;
            _selectedTrainerId = currentClass!.trainerId;
            _selectedClassIdForBooking = currentClass!.classId;
          });
          classProvider.filterClasses(date: _selectedClassDate, trainerId: _selectedTrainerId);
        }

        _initialValues = {
          'customer_id': widget.booking!.customerId,
          'booking_date': widget.booking!.bookingDate,
          'status': widget.booking!.status,
          'class_id': _selectedClassIdForBooking,
        };
      } else {
        _selectedClassDate = DateTime.now();
        classProvider.filterClasses(date: _selectedClassDate);
        _initialValues = {
          'booking_date': DateTime.now(),
          'status': 'Confirmed',
        };
      }
      if (mounted) setState(() {});
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalizedSelectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);

    if (!isSameDay(_selectedClassDate, normalizedSelectedDay)) {
      setState(() {
        _selectedClassDate = normalizedSelectedDay;
        _focusedDay = focusedDay;
        _selectedClassIdForBooking = null; 
      });
      _applyFilter();
      _formKey.currentState?.fields['class_id']?.didChange(null);
    }
  }

  void _applyFilter() {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    classProvider.filterClasses(date: _selectedClassDate, trainerId: _selectedTrainerId);
    
    if (_selectedClassIdForBooking != null &&
        !classProvider.classes.any((dc) => dc.gymClass.classId == _selectedClassIdForBooking)) {
      setState(() => _selectedClassIdForBooking = null);
      _formKey.currentState?.fields['class_id']?.didChange(null);
    }
  }

  List<Customer> _getActiveCustomers(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);

    final activeMemberIds = membershipProvider.memberships
        .where((m) => m.membership.status.toLowerCase() == 'active')
        .map((m) => m.membership.customerId)
        .toSet();

    final activeCustomers = customerProvider.customers
        .where((c) => activeMemberIds.contains(c.customerId))
        .toList();

    if (widget.booking != null) {
      final currentId = widget.booking!.customerId;
      final isInList = activeCustomers.any((c) => c.customerId == currentId);
      if (!isInList) {
        try {
          final currentCustomer = customerProvider.customers.firstWhere((c) => c.customerId == currentId);
          activeCustomers.add(currentCustomer);
        } catch (e) {}
      }
    }
    
    return activeCustomers;
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);
    final membershipProvider = Provider.of<MembershipProvider>(context);

    final activeCustomers = _getActiveCustomers(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.booking != null ? 'Edit Booking' : 'New Booking'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: _initialValues,
          enabled: !customerProvider.isLoading && !classProvider.isLoading && !membershipProvider.isLoading,
          child: ListView(
            children: [
              // Customer Selection
              FormBuilderDropdown<String>(
                name: 'customer_id',
                decoration: InputDecoration(
                  labelText: 'Select Active Member',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Only showing customers with active memberships',
                ),
                validator: (value) => value == null ? 'Required' : null,
                items: activeCustomers.isEmpty 
                  ? [const DropdownMenuItem(value: null, enabled: false, child: Text('No active members found'))]
                  : activeCustomers.map((c) => DropdownMenuItem(
                      value: c.customerId, 
                      child: Text('${c.firstName} ${c.lastName}')
                    )).toList(),
              ),
              const SizedBox(height: 24),

              // Calendar Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("Has Class", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.week: 'Week', CalendarFormat.month: 'Month'},
                  selectedDayPredicate: (day) => isSameDay(_selectedClassDate, day),
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  eventLoader: (day) {
                    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
                    return classProvider.classDates.contains(normalizedDay) ? [true] : [];
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    markersMaxCount: 1,
                  ),
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                ),
              ),
              
              const SizedBox(height: 16),

              FormBuilderDropdown<String>(
                name: 'trainer_id_filter',
                decoration: InputDecoration(
                  labelText: 'Filter by Trainer',
                  prefixIcon: const Icon(Icons.filter_alt),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Trainers')),
                  ...trainerProvider.trainers.map((t) => DropdownMenuItem(value: t.trainerId, child: Text('${t.firstName} ${t.lastName}'))),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedTrainerId = val;
                    _selectedClassIdForBooking = null;
                  });
                  _applyFilter();
                  _formKey.currentState?.fields['class_id']?.didChange(null);
                },
              ),

              const SizedBox(height: 24),

              Text("Available Classes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 8),
              
              classProvider.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : classProvider.classes.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("No classes available for this selection", style: TextStyle(color: Colors.grey))),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: classProvider.classes.length,
                      itemBuilder: (context, index) {
                        final detailedClass = classProvider.classes[index];
                        final isSelected = _selectedClassIdForBooking == detailedClass.gymClass.classId;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedClassIdForBooking = detailedClass.gymClass.classId);
                            _formKey.currentState?.fields['class_id']?.didChange(detailedClass.gymClass.classId);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.transparent, 
                                width: 2
                              ),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(DateFormat('h:mm').format(detailedClass.gymClass.scheduleTime), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.blue : Colors.black87)),
                                    Text(DateFormat('a').format(detailedClass.gymClass.scheduleTime), style: TextStyle(fontSize: 12, color: isSelected ? Colors.blue : Colors.grey)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Container(width: 1, height: 40, color: Colors.grey.shade200),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(detailedClass.gymClass.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text("Trainer: ${detailedClass.trainerFullName}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ),
                                ),
                                if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              FormBuilderField<String>(
                name: 'class_id',
                validator: (val) => val == null ? 'Select a class' : null,
                builder: (field) => field.hasError 
                  ? Padding(padding: const EdgeInsets.only(top: 5), child: Text(field.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))) 
                  : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              Text("Booking Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FormBuilderDateTimePicker(
                        name: 'booking_date',
                        decoration: const InputDecoration(labelText: 'Booking Created On', prefixIcon: Icon(Icons.today), border: InputBorder.none),
                        inputType: InputType.date,
                      ),
                      const Divider(),
                      FormBuilderDropdown<String>(
                        name: 'status',
                        decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.flag), border: InputBorder.none),
                        items: ['Confirmed', 'Cancelled', 'Attended', 'No Show']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // 1. Trigger validation for hidden field
                    _formKey.currentState?.fields['class_id']?.validate();
                    
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final data = _formKey.currentState!.value;
                      
                      // 2. Get Providers
                      final bookingProvider = Provider.of<ClassBookingProvider>(context, listen: false);
                      final classProvider = Provider.of<ClassProvider>(context, listen: false);
                      // NEW: Get Package Provider
                      final packageProvider = Provider.of<TrainerPackageProvider>(context, listen: false);
                      
                      // 3. Validate Double Booking
                      final targetClass = classProvider.classes.firstWhere((c) => c.gymClass.classId == data['class_id']).gymClass;
                      final error = bookingProvider.validateBooking(
                        data['customer_id'], 
                        targetClass, 
                        excludeBookingId: widget.booking?.bookingId
                      );

                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                        return;
                      }

                      final newBooking = ClassBooking(
                        bookingId: widget.booking?.bookingId,
                        customerId: data['customer_id'],
                        classId: data['class_id'],
                        bookingDate: data['booking_date'],
                        status: data['status'],
                      );

                      try {
                        // 4. Execute Add/Update with Package Logic
                        if (widget.booking != null) {
                          await bookingProvider.updateClassBooking(newBooking);
                        } else {
                          // PASS packageProvider to handle deduction logic
                          await bookingProvider.addClassBooking(newBooking, packageProvider);
                        }
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking saved!')));
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        // This catches "User has no sessions left" errors
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.booking != null ? 'Update Booking' : 'Confirm Booking', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}