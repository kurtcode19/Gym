// lib/screens/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/models/attendance.dart';
import 'package:gym/screens/add_attendance_screen.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search attendance...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<AttendanceProvider>(context, listen: false).searchAttendanceRecords(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<AttendanceProvider>(
              builder: (context, attendanceProvider, child) {
                if (attendanceProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (attendanceProvider.attendanceRecords.isEmpty) {
                  return const Center(child: Text('No attendance records found.'));
                } else {
                  return ListView.builder(
                    itemCount: attendanceProvider.attendanceRecords.length,
                    itemBuilder: (context, index) {
                      final detailedAttendance = attendanceProvider.attendanceRecords[index];
                      final attendance = detailedAttendance.attendance;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              DateFormat('dd').format(attendance.date),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '${detailedAttendance.customerFirstName} ${detailedAttendance.customerLastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${DateFormat('MMM d, yyyy').format(attendance.date)}'),
                              Text(
                                'Check-in: ${DateFormat('h:mm a').format(attendance.checkinTime)}'
                                '${attendance.checkoutTime != null ? ' - ${DateFormat('h:mm a').format(attendance.checkoutTime!)}' : ''}',
                              ),
                              Text('Facility: ${attendance.facilityUsed ?? 'N/A'}'),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddAttendanceScreen(attendance: attendance),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, attendanceProvider, attendance);
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
              builder: (context) => const AddAttendanceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AttendanceProvider attendanceProvider, Attendance attendance) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Attendance Record'),
          content: Text('Are you sure you want to delete this attendance record for ${DateFormat('MMM d, yyyy').format(attendance.date)}?'),
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
                attendanceProvider.deleteAttendance(attendance.attendanceId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance record deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}