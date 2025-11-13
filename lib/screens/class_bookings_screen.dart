// lib/screens/class_bookings_screen.dart - UPDATED FOR EVENT CALENDAR UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/screens/add_class_booking_screen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gym/models/class_booking.dart'; // Import for DetailedClassBooking

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
    _selectedDay = _focusedDay; // Initially select today
    _updateStatsAndBookings(context); // Load initial stats and bookings
  }

  // Helper to get color for status dot/card
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
    final bookingProvider = Provider.of<ClassBookingProvider>(context, listen: false);
    setState(() {
      _currentMonthStats = bookingProvider.getBookingCountsForMonth(_focusedDay);
      _selectedDayBookings = bookingProvider.getBookingsForDay(_selectedDay!);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Normalize dates to remove time for comparison
    final normalizedSelectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
    final normalizedFocusedDay = DateTime.utc(focusedDay.year, focusedDay.month, focusedDay.day);

    if (!isSameDay(_selectedDay, normalizedSelectedDay)) {
      setState(() {
        _selectedDay = normalizedSelectedDay;
        _focusedDay = normalizedFocusedDay;
      });
      // Update the list of bookings for the newly selected day
      final bookingProvider = Provider.of<ClassBookingProvider>(context, listen: false);
      setState(() {
        _selectedDayBookings = bookingProvider.getBookingsForDay(_selectedDay!);
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    // When the month changes, update the monthly stats
    _updateStatsAndBookings(context);
  }

  // Widget to build the small stat cards like in the image
  Widget _buildStatCard({
    required String title,
    required int count,
    required Color dotColor,
  }) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<ClassBookingProvider>(context);

    // Update stats and bookings whenever the provider notifies listeners (e.g., after add/delete)
    // This is a simple way to ensure the UI refreshes after data changes.
    // In a more complex scenario, you might only update specific parts or use a selector.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateStatsAndBookings(context);
    });

    if (bookingProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Class Bookings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Match dashboard background
      appBar: AppBar(
        title: const Text('Class Bookings Calendar'),
      ),
      body: Column(
        children: [
          // Stat Cards (similar to the image)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor, // Use app's primary color
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(title: 'Confirmed', count: _currentMonthStats['Confirmed'] ?? 0, dotColor: _getStatusColor('confirmed')),
                      const SizedBox(width: 8),
                      _buildStatCard(title: 'Attended', count: _currentMonthStats['Attended'] ?? 0, dotColor: _getStatusColor('attended')),
                      const SizedBox(width: 8),
                      _buildStatCard(title: 'No Show', count: _currentMonthStats['No Show'] ?? 0, dotColor: _getStatusColor('no show')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(title: 'Cancelled', count: _currentMonthStats['Cancelled'] ?? 0, dotColor: _getStatusColor('cancelled')),
                      // Add more stat cards as needed, e.g., 'Upcoming'
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TableCalendar
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            elevation: 2,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onPageChanged: _onPageChanged,
              eventLoader: (day) {
                // Returns a list of objects for events, even a simple boolean list works
                final normalizedDay = DateTime.utc(day.year, day.month, day.day);
                return bookingProvider.bookingDates.contains(normalizedDay) ? [true] : [];
              },
              calendarStyle: CalendarStyle(
                weekendTextStyle: const TextStyle(color: Colors.red),
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary, // Small dot for days with bookings
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                weekendStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List of bookings for the selected day
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _selectedDay != null
                        ? 'Bookings for ${DateFormat('EEE, MMM d, yyyy').format(_selectedDay!)}:'
                        : 'Select a day to see bookings:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: _selectedDayBookings.isEmpty
                      ? const Center(child: Text('No bookings for this day.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _selectedDayBookings.length,
                          itemBuilder: (context, index) {
                            final detailedBooking = _selectedDayBookings[index];
                            final booking = detailedBooking.booking;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(booking.status),
                                  child: Text(
                                    booking.status[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  '${detailedBooking.customerFullName} - ${detailedBooking.className}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Time: ${DateFormat('h:mm a').format(detailedBooking.classScheduleTime)} (${detailedBooking.classDurationMinutes} min)'),
                                    Text('Trainer: ${detailedBooking.trainerFullName}'),
                                    Text('Status: ${booking.status}'),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddClassBookingScreen(booking: booking),
                                    ),
                                  );
                                },
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    _confirmDelete(context, bookingProvider, booking);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddClassBookingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClassBookingProvider bookingProvider, ClassBooking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Booking'),
          content: Text('Are you sure you want to delete this class booking?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                bookingProvider.deleteClassBooking(booking.bookingId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class booking deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}