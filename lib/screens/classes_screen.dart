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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Class Management', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search classes...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_view_week, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No classes scheduled', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                } else {
                  // --- GROUPING LOGIC ---
                  // Group classes by Class Name to prevent flooding
                  final Map<String, List<DetailedGymClass>> groupedClasses = {};
                  for (var c in classProvider.classes) {
                    if (!groupedClasses.containsKey(c.gymClass.className)) {
                      groupedClasses[c.gymClass.className] = [];
                    }
                    groupedClasses[c.gymClass.className]!.add(c);
                  }
                  
                  // Sort groups alphabetically
                  final sortedKeys = groupedClasses.keys.toList()..sort();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final className = sortedKeys[index];
                      final sessions = groupedClasses[className]!;
                      
                      // Sort sessions by date
                      sessions.sort((a, b) => a.gymClass.scheduleTime.compareTo(b.gymClass.scheduleTime));

                      final nextSession = sessions.firstWhere(
                        (s) => s.gymClass.scheduleTime.isAfter(DateTime.now()),
                        orElse: () => sessions.last, // Fallback to last if all past
                      );

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                className[0].toUpperCase(),
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              className,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${sessions.length} Sessions Scheduled',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                Text(
                                  'Next: ${DateFormat('MMM d, h:mm a').format(nextSession.gymClass.scheduleTime)}',
                                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            // BATCH DELETE BUTTON
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.red),
                              tooltip: 'Delete All Sessions',
                              onPressed: () => _confirmBatchDelete(context, classProvider, className, sessions),
                            ),
                            children: [
                              // EXPANDED LIST OF INDIVIDUAL SESSIONS
                              Container(
                                constraints: const BoxConstraints(maxHeight: 300), // Limit height if too many
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: sessions.length,
                                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey[200]),
                                  itemBuilder: (ctx, i) {
                                    final session = sessions[i];
                                    final isPast = session.gymClass.scheduleTime.isBefore(DateTime.now());
                                    
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        Icons.event, 
                                        size: 18, 
                                        color: isPast ? Colors.grey : Colors.blue
                                      ),
                                      title: Text(
                                        DateFormat('EEE, MMM d • h:mm a').format(session.gymClass.scheduleTime),
                                        style: TextStyle(
                                          color: isPast ? Colors.grey : Colors.black87,
                                          decoration: isPast ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      subtitle: Text(session.trainerFullName),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AddClassScreen(gymClass: session.gymClass),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                                            onPressed: () => _confirmSingleDelete(context, classProvider, session.gymClass),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddClassScreen(),
            ),
          );
        },
        label: const Text("Schedule Class"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // DELETE ALL IN GROUP
void _confirmBatchDelete(
  BuildContext context,
  ClassProvider provider,
  String className,
  List<DetailedGymClass> sessions,
) {
  final ids = sessions.map((s) => s.gymClass.classId).toList();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete All Sessions?'),
      content: Text(
        'You are about to delete ALL ${ids.length} scheduled sessions for "$className".\n\nThis cannot be undone.',
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete All'),
          onPressed: () {
            provider.deleteBatchGymClasses(ids);
            Navigator.pop(context);
          },
        )
      ],
    ),
  );
}


  // DELETE SINGLE SESSION
  void _confirmSingleDelete(BuildContext context, ClassProvider provider, GymClass gymClass) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Session?'),
          content: Text('Delete just this session on ${DateFormat('MMM d').format(gymClass.scheduleTime)}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes, Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                provider.deleteGymClass(gymClass.classId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}