// lib/screens/add_class_booking_screen.dart
// FINAL VERSION – FIXED VALIDATION + CAPACITY + DATE INDICATORS (OPTION B)

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import 'package:gym/models/class_booking.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/trainer_package_provider.dart';

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
  DateTime? _selectedDate;

  String? _selectedClassId;
  String? _selectedTrainerId;

  Map<String, dynamic> _initialValues = {};

  static const int MAX_CAPACITY = 10;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 150));

    final classProvider = Provider.of<ClassProvider>(context, listen: false);

    Provider.of<MembershipProvider>(context, listen: false).fetchMemberships();
    Provider.of<TrainerPackageProvider>(context, listen: false).fetchPackages();

    if (widget.booking != null) {
      try {
        final detailed = classProvider.classes
            .firstWhere((dc) => dc.gymClass.classId == widget.booking!.classId);

        final dt = detailed.gymClass.scheduleTime;

        _selectedDate = DateTime(dt.year, dt.month, dt.day);
        _selectedClassId = detailed.gymClass.classId;
        _selectedTrainerId = detailed.gymClass.trainerId;
        _focusedDay = _selectedDate!;
      } catch (_) {}

      _initialValues = {
        "customer_id": widget.booking!.customerId,
        "booking_date": widget.booking!.bookingDate,
        "status": widget.booking!.status,
      };

      classProvider.filterClasses(
        date: _selectedDate,
        trainerId: _selectedTrainerId,
      );
    } else {
      _selectedDate = DateTime.now();
      classProvider.filterClasses(date: _selectedDate);

      _initialValues = {
        "booking_date": DateTime.now(),
        "status": "Confirmed",
      };
    }

    if (mounted) setState(() {});
  }

  // -----------------------------------------------
  // Premium UI Components
  // -----------------------------------------------
  Widget _premiumCard(Widget child) {
    return Card(
      elevation: 2.5,
      shadowColor: Colors.black.withOpacity(.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  InputDecoration _premiumField(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: Colors.grey[700]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------
  // Active Members Only
  // -----------------------------------------------
  List<Customer> _activeMembers(BuildContext context) {
    final customers =
        Provider.of<CustomerProvider>(context, listen: false).customers;
    final memberships =
        Provider.of<MembershipProvider>(context, listen: false).memberships;

    final activeIds = memberships
        .where((m) => m.membership.status.toLowerCase() == "active")
        .map((m) => m.membership.customerId)
        .toSet();

    final list =
        customers.where((c) => activeIds.contains(c.customerId)).toList();

    if (widget.booking != null &&
        !list.any((c) => c.customerId == widget.booking!.customerId)) {
      list.add(customers
          .firstWhere((c) => c.customerId == widget.booking!.customerId));
    }

    return list;
  }

  // -----------------------------------------------
  // Build Screen
  // -----------------------------------------------
  @override
  Widget build(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);
    final bookingProvider = Provider.of<ClassBookingProvider>(context);

    final customers = _activeMembers(context);

    // Class days (based on your provider)
    final classDays = classProvider.allClassDates.toList();

    // Capacity map
    final Map<DateTime, int> capacityMap = {};
    for (var b in bookingProvider.allBookings) {
      final d = b.classScheduleTime;
      final day = DateTime(d.year, d.month, d.day);
      capacityMap[day] = (capacityMap[day] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.booking == null ? "New Class Booking" : "Edit Booking",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: _initialValues,
          child: ListView(
            children: [
              _sectionTitle("Select Member"),
              _memberDropdown(customers),

              const SizedBox(height: 24),

              _sectionTitle("Choose Date"),
              _calendarCard(classDays, capacityMap),

              const SizedBox(height: 24),

              _sectionTitle("Filter by Trainer"),
              _trainerFilter(trainerProvider),

              const SizedBox(height: 24),

              _sectionTitle("Available Classes"),
              _availableClassesList(classProvider),

              // ⭐ Hidden class_id field with visible validation error
              FormBuilderField<String>(
                name: "class_id",
                validator: (v) => v == null ? "Please select a class" : null,
                builder: (state) {
                  return state.hasError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            state.errorText ?? '',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),

              _sectionTitle("Booking Details"),
              _detailsCard(),

              const SizedBox(height: 30),

              _submitButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------
  // UI Components
  // -----------------------------------------------

  Widget _memberDropdown(List<Customer> customers) {
    return _premiumCard(
      FormBuilderDropdown<String>(
        name: "customer_id",
        decoration: _premiumField("Active Members", Icons.person),
        validator: (v) => v == null ? "Required" : null,
        items: customers
            .map(
              (c) => DropdownMenuItem(
                value: c.customerId,
                child: Text("${c.firstName} ${c.lastName}"),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _calendarCard(List<DateTime> classDays, Map<DateTime, int> capacityMap) {
    return _premiumCard(
      Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: "Month"},
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),

            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDate = DateTime(selected.year, selected.month, selected.day);
                _focusedDay = focused;
                _selectedClassId = null;
              });

              Provider.of<ClassProvider>(context, listen: false)
                  .filterClasses(date: _selectedDate);

              _formKey.currentState?.fields["class_id"]?.didChange(null);
            },

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final d = DateTime(day.year, day.month, day.day);

                final hasClass = classDays.contains(d);
                final count = capacityMap[d] ?? 0;

                Color bg = Colors.transparent;
                Color txt = Colors.black;

                if (hasClass) {
                  if (count >= MAX_CAPACITY) {
                    bg = Colors.red.withOpacity(.35);
                    txt = Colors.red.shade900;
                  } else if (count >= 6) {
                    bg = Colors.orange.withOpacity(.35);
                    txt = Colors.deepOrange.shade900;
                  } else {
                    bg = Colors.green.withOpacity(.35);
                    txt = Colors.green.shade900;
                  }
                }

                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Text(
                    "${day.day}",
                    style: TextStyle(
                      color: txt,
                      fontWeight: hasClass ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          _legendRow(),
        ],
      ),
    );
  }

  Widget _legendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(Colors.green.shade700, "Available"),
        const SizedBox(width: 16),
        _legendDot(Colors.orange.shade800, "Few Spots"),
        const SizedBox(width: 16),
        _legendDot(Colors.red.shade700, "Full"),
      ],
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _trainerFilter(TrainerProvider trainerProvider) {
    return _premiumCard(
      FormBuilderDropdown<String?>(
        name: "trainer_filter",
        decoration: _premiumField("Trainer (optional)", Icons.filter_alt),
        items: [
          const DropdownMenuItem(value: null, child: Text("All")),
          ...trainerProvider.trainers.map(
            (t) => DropdownMenuItem(
              value: t.trainerId,
              child: Text("${t.firstName} ${t.lastName}"),
            ),
          ),
        ],
        onChanged: (val) {
          _selectedTrainerId = val;
          _selectedClassId = null;

          Provider.of<ClassProvider>(context, listen: false)
              .filterClasses(date: _selectedDate, trainerId: val);

          _formKey.currentState?.fields["class_id"]?.didChange(null);
        },
      ),
    );
  }

  Widget _availableClassesList(ClassProvider classProvider) {
    if (classProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (classProvider.classes.isEmpty) {
      return _premiumCard(
        const Padding(
          padding: EdgeInsets.all(10),
          child: Center(
            child: Text("No classes available", style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Column(
      children: classProvider.classes.map((dc) {
        final g = dc.gymClass;
        final selected = _selectedClassId == g.classId;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedClassId = g.classId);
            _formKey.currentState?.fields["class_id"]?.didChange(g.classId);
          },
          child: _premiumCard(
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      DateFormat("h:mm").format(g.scheduleTime),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.blueAccent : Colors.black,
                      ),
                    ),
                    Text(
                      DateFormat("a").format(g.scheduleTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.blueAccent : Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        "Trainer: ${dc.trainerFullName}",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                if (selected)
                  const Icon(Icons.check_circle, color: Colors.blueAccent),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _detailsCard() {
    return _premiumCard(
      Column(
        children: [
          FormBuilderDateTimePicker(
            name: "booking_date",
            decoration: _premiumField("Booking Created On", Icons.today),
            inputType: InputType.date,
          ),
          const SizedBox(height: 16),
          FormBuilderDropdown<String>(
            name: "status",
            decoration: _premiumField("Status", Icons.flag),
            items: const [
              DropdownMenuItem(value: "Confirmed", child: Text("Confirmed")),
              DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
              DropdownMenuItem(value: "Attended", child: Text("Attended")),
              DropdownMenuItem(value: "No Show", child: Text("No Show")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _save(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        minimumSize: const Size.fromHeight(55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        widget.booking == null ? "Confirm Booking" : "Save Changes",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  // -----------------------------------------------
  // SAVE LOGIC + FULL ERROR CHECKING
  // -----------------------------------------------
  Future<void> _save(BuildContext context) async {
    _formKey.currentState?.fields["class_id"]?.validate();

    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      _showSnack("Please correct the highlighted fields.", true);
      return;
    }

    final data = _formKey.currentState!.value;

    final customerId = data["customer_id"];
    final classId = data["class_id"];
    final bookingDate = data["booking_date"];
    final status = data["status"];

    if (customerId == null || classId == null) {
      _showSnack("Incomplete booking information.", true);
      return;
    }

    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final bookingProvider = Provider.of<ClassBookingProvider>(context, listen: false);

    final match =
        classProvider.classes.where((c) => c.gymClass.classId == classId);

    if (match.isEmpty) {
      _showSnack("Class no longer exists.", true);
      return;
    }

    final selectedClass = match.first.gymClass;

    if (selectedClass.scheduleTime.isBefore(DateTime.now())) {
      _showSnack("Cannot book past classes.", true);
      return;
    }

    final count = bookingProvider
        .getBookingsForDay(selectedClass.scheduleTime)
        .length;

    if (count >= MAX_CAPACITY) {
      _showSnack("This class is fully booked.", true);
      return;
    }

    final conflict = bookingProvider.validateBooking(
      customerId,
      selectedClass,
      excludeBookingId: widget.booking?.bookingId,
    );

    if (conflict != null) {
      _showSnack(conflict, true);
      return;
    }

    final newBooking = ClassBooking(
      bookingId: widget.booking?.bookingId,
      customerId: customerId,
      classId: classId,
      bookingDate: bookingDate,
      status: status,
    );

    try {
      final pkgProvider =
          Provider.of<TrainerPackageProvider>(context, listen: false);

      if (widget.booking == null) {
        await bookingProvider.addClassBooking(newBooking, pkgProvider);
      } else {
        await bookingProvider.updateClassBooking(newBooking);
      }

      if (!mounted) return;

      _showSnack("Booking saved!", false);
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Error: $e", true);
    }
  }

  void _showSnack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
