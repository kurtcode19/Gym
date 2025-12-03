import 'package:flutter/material.dart';
import 'package:gym/utils/app_refresher.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/screens/add_class_booking_screen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gym/models/class_booking.dart';

class ClassBookingsScreen extends StatefulWidget {
  const ClassBookingsScreen({super.key});

  @override
  State<ClassBookingsScreen> createState() => _ClassBookingsScreenState();
}

class _ClassBookingsScreenState extends State<ClassBookingsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, int> _currentMonthStats = {};
  List<DetailedClassBooking> _selectedDayBookings = [];

  // 🔁 FIX: keep calendar format in state so the toggle works
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateStatsAndBookings(context);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'attended':
        return Colors.blue;
      case 'no show':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _updateStatsAndBookings(BuildContext context) {
    final bookingProvider =
        Provider.of<ClassBookingProvider>(context, listen: false);

    setState(() {
      _currentMonthStats = bookingProvider.getBookingCountsForMonth(_focusedDay);
      _selectedDayBookings =
          bookingProvider.getBookingsForDay(_selectedDay!);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      final bookingProvider =
          Provider.of<ClassBookingProvider>(context, listen: false);

      setState(() {
        _selectedDayBookings =
            bookingProvider.getBookingsForDay(_selectedDay!);
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _updateStatsAndBookings(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingProvider = Provider.of<ClassBookingProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // --------------------------------------------------------------------
      // ⭐ PREMIUM APP BAR
      // --------------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          "Class Bookings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: Column(
        children: [
          // ----------------------------------------------------------------
          // ⭐ PREMIUM HEADER + MINI DASHBOARD
          // ----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: _buildPremiumStatsCard(),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendar(context, bookingProvider),

                  const SizedBox(height: 22),

                  _buildBookingsHeader(),

                  const SizedBox(height: 12),

                  _buildBookingsList(bookingProvider),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        label: const Text("Book Class"),
        icon: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClassBookingScreen()),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ⭐ PREMIUM MINI DASHBOARD
  // --------------------------------------------------------------------------
  Widget _buildPremiumStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Confirmed", _currentMonthStats["Confirmed"] ?? 0,
              Colors.green),
          _verticalDivider(),
          _statItem("Attended", _currentMonthStats["Attended"] ?? 0,
              Colors.blue),
          _verticalDivider(),
          _statItem("No Show", _currentMonthStats["No Show"] ?? 0,
              Colors.orange),
          _verticalDivider(),
          _statItem("Cancelled", _currentMonthStats["Cancelled"] ?? 0,
              Colors.red),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 28,
      width: 1.2,
      color: Colors.grey.shade300,
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 17, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // ⭐ PREMIUM CALENDAR WRAPPER (WITH WORKING TOGGLE)
  // --------------------------------------------------------------------------
  Widget _buildCalendar(
      BuildContext context, ClassBookingProvider bookingProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200)),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,

          // 🔁 use the stateful format instead of a hard-coded one
          calendarFormat: _calendarFormat,

          availableCalendarFormats: const {
            CalendarFormat.week: 'Week',
            CalendarFormat.month: 'Month'
          },

          selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
          onDaySelected: _onDaySelected,
          onPageChanged: _onPageChanged,

          // 🔁 update format when the button is pressed
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },

          eventLoader: (day) {
            final normalized =
                DateTime.utc(day.year, day.month, day.day);
            return bookingProvider.bookingDates.contains(normalized)
                ? [true]
                : [];
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
                color: Colors.blue.shade200, shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(
                color: Colors.blue, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(
                color: Colors.orange, shape: BoxShape.circle),
            markersMaxCount: 1,
          ),
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: true,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BOOKING LIST HEADER
  // --------------------------------------------------------------------------
  Widget _buildBookingsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Bookings",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800])),
          Text(
            DateFormat('MMMM d').format(_selectedDay!),
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ⭐ PREMIUM BOOKINGS LIST
  // --------------------------------------------------------------------------
  Widget _buildBookingsList(ClassBookingProvider bookingProvider) {
    if (_selectedDayBookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No bookings for this day",
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedDayBookings.length,
      itemBuilder: (_, i) {
        final db = _selectedDayBookings[i];
        final booking = db.booking;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddClassBookingScreen(booking: booking)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TIME MARKER
                  Column(
                    children: [
                      Text(
                        DateFormat('h:mm').format(db.classScheduleTime),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        DateFormat('a').format(db.classScheduleTime),
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 28,
                        width: 2,
                        color: Colors.grey[200],
                      )
                    ],
                  ),

                  const SizedBox(width: 16),

                  // DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(db.className,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(db.customerFullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.sports_gymnastics,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              "Trainer: ${db.trainerFullName}",
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // STATUS & MENU
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(booking.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status,
                          style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () =>
                            _confirmDelete(context, bookingProvider, booking),
                        child: Icon(Icons.delete_outline,
                            color: Colors.red[300], size: 20),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // DELETE CONFIRMATION
  // --------------------------------------------------------------------------
  void _confirmDelete(BuildContext context,
      ClassBookingProvider bookingProvider, ClassBooking booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: const Text("Are you sure you want to delete this booking?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              child: const Text("No"),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text("Yes, Delete", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              bookingProvider.deleteClassBooking(booking.bookingId);
              Navigator.pop(context);

              if (context.mounted) {
                await AppRefresher.refreshAll(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Booking deleted."),
                ));
              }
            },
          ),
        ],
      ),
    );
  }
}
