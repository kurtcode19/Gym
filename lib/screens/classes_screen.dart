// lib/screens/classes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/models/class.dart';
import 'package:gym/screens/add_class_screen.dart';
import 'package:intl/intl.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search classes...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<ClassProvider>(context, listen: false).searchGymClasses(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<ClassProvider>(
              builder: (context, classProvider, child) {
                if (classProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (classProvider.classes.isEmpty) {
                  return const Center(child: Text('No classes scheduled.'));
                } else {
                  return ListView.builder(
                    itemCount: classProvider.classes.length,
                    itemBuilder: (context, index) {
                      final detailedClass = classProvider.classes[index];
                      final gymClass = detailedClass.gymClass;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.secondary, // Use an accent color
                            child: Text(
                              gymClass.className[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(gymClass.className),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trainer: ${detailedClass.trainerFirstName != null ? '${detailedClass.trainerFirstName} ${detailedClass.trainerLastName}' : 'Unassigned'}',
                              ),
                              Text(
                                'Time: ${DateFormat('EEE, MMM d, h:mm a').format(gymClass.scheduleTime)} '
                                '(${gymClass.durationMinutes} min)',
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddClassScreen(gymClass: gymClass),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, classProvider, gymClass);
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
              builder: (context) => const AddClassScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClassProvider classProvider, GymClass gymClass) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Class'),
          content: Text('Are you sure you want to delete "${gymClass.className}" scheduled for ${DateFormat('MMM d, h:mm a').format(gymClass.scheduleTime)}? This will delete all associated bookings.'),
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
                classProvider.deleteGymClass(gymClass.classId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${gymClass.className} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}