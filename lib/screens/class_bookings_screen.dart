// lib/screens/class_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/class_booking_provider.dart';
import 'package:gym/screens/add_class_booking_screen.dart';
import 'package:intl/intl.dart';
import 'package:gym/models/class_booking.dart';

class ClassBookingsScreen extends StatelessWidget {
  const ClassBookingsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'attended':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Bookings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search bookings...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<ClassBookingProvider>(context, listen: false).searchClassBookings(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<ClassBookingProvider>(
              builder: (context, bookingProvider, child) {
                if (bookingProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (bookingProvider.bookings.isEmpty) {
                  return const Center(child: Text('No class bookings found.'));
                } else {
                  return ListView.builder(
                    itemCount: bookingProvider.bookings.length,
                    itemBuilder: (context, index) {
                      final detailedBooking = bookingProvider.bookings[index];
                      final booking = detailedBooking.booking;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(booking.status),
                            child: Text(
                              booking.status[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${detailedBooking.customerFirstName} ${detailedBooking.customerLastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class: ${detailedBooking.className}'),
                              Text(
                                'Time: ${DateFormat('EEE, MMM d, h:mm a').format(detailedBooking.classScheduleTime)}',
                              ),
                              Text('Trainer: ${detailedBooking.trainerFirstName != null ? '${detailedBooking.trainerFirstName} ${detailedBooking.trainerLastName}' : 'N/A'}'),
                              Text('Status: ${booking.status}'),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to edit screen
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
                  );
                }
              },
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