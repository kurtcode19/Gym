// lib/screens/class_bookings_screen.dart
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
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'attended': return Colors.blue;
      case 'no show': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _updateStatsAndBookings(BuildContext context) {
    final bookingProvider = Provider.of<ClassBookingProvider>(context, listen: false);
    setState(() {
      _currentMonthStats = bookingProvider.getBookingCountsForMonth(_focusedDay);
      _selectedDayBookings = bookingProvider.getBookingsForDay(_selectedDay!);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      final bookingProvider = Provider.of<ClassBookingProvider>(context, listen: false);
      setState(() {
        _selectedDayBookings = bookingProvider.getBookingsForDay(_selectedDay!);
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _updateStatsAndBookings(context);
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<ClassBookingProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Schedule & Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. MONTHLY STATS PANEL
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Confirmed', _currentMonthStats['Confirmed'] ?? 0, Colors.green),
                  _buildVerticalDivider(),
                  _buildStatItem('Attended', _currentMonthStats['Attended'] ?? 0, Colors.blue),
                  _buildVerticalDivider(),
                  _buildStatItem('No Show', _currentMonthStats['No Show'] ?? 0, Colors.orange),
                  _buildVerticalDivider(),
                  _buildStatItem('Cancelled', _currentMonthStats['Cancelled'] ?? 0, Colors.red),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // 2. CALENDAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.week, // Default to week for better space
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                          CalendarFormat.week: 'Week',
                        },
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: _onDaySelected,
                        onPageChanged: _onPageChanged,
                        eventLoader: (day) {
                          final normalizedDay = DateTime.utc(day.year, day.month, day.day);
                          return bookingProvider.bookingDates.contains(normalizedDay) ? [true] : [];
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(color: Colors.blue.shade200, shape: BoxShape.circle),
                          selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                          markerDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                          markersMaxCount: 1,
                        ),
                        headerStyle: const HeaderStyle(formatButtonVisible: true, titleCentered: true, formatButtonShowsNext: false),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. BOOKINGS LIST HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Bookings",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                        Text(
                          DateFormat('MMMM d').format(_selectedDay!),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // 4. BOOKINGS LIST
                  if (_selectedDayBookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text("No bookings for this day", style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _selectedDayBookings.length,
                      itemBuilder: (context, index) {
                        final db = _selectedDayBookings[index];
                        final booking = db.booking;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddClassBookingScreen(booking: booking)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time Badge
                                  Column(
                                    children: [
                                      Text(
                                        DateFormat('h:mm').format(db.classScheduleTime),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        DateFormat('a').format(db.classScheduleTime),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 2,
                                        height: 30,
                                        color: Colors.grey[200],
                                      )
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          db.className,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              db.customerFullName,
                                              style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.sports_gymnastics, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Trainer: ${db.trainerFullName}",
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Status & Menu
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(booking.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          booking.status,
                                          style: TextStyle(
                                            color: _getStatusColor(booking.status),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _confirmDelete(context, bookingProvider, booking),
                                        child: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClassBookingScreen()),
          );
        },
        label: const Text("Book Class"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.grey[300],
    );
  }

  void _confirmDelete(BuildContext context, ClassBookingProvider bookingProvider, ClassBooking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking?'),
          content: const Text('Are you sure you want to delete this booking record?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Yes, Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                bookingProvider.deleteClassBooking(booking.bookingId);
                Navigator.of(context).pop();
                  if (context.mounted) {
    await AppRefresher.refreshAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking deleted.')),
                );
                  }
              },
            ),
          ],
        );
      },
    );
  }
}