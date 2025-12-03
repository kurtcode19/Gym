// lib/screens/classes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/models/class.dart';
import 'package:gym/screens/add_class_screen.dart';
import 'package:intl/intl.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // -------------------------------------------------------------------
      // ⭐ PREMIUM APP BAR
      // -------------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          "Class Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      // -------------------------------------------------------------------
      // BODY
      // -------------------------------------------------------------------
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // ⭐ PREMIUM SEARCH BAR
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search classes...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (q) => Provider.of<ClassProvider>(context, listen: false)
                  .searchGymClasses(q),
            ),
          ),

          const SizedBox(height: 8),

          // -------------------------------------------------------------------
          // CLASS LIST
          // -------------------------------------------------------------------
          Expanded(
            child: Consumer<ClassProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.classes.isEmpty) {
                  return _emptyState();
                }

                // GROUP BY CLASS NAME
                final Map<String, List<DetailedGymClass>> grouped = {};
                for (var c in provider.classes) {
                  grouped.putIfAbsent(c.gymClass.className, () => []);
                  grouped[c.gymClass.className]!.add(c);
                }

                final sortedKeys = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final className = sortedKeys[index];
                    final sessions = grouped[className]!..sort(
                      (a, b) => a.gymClass.scheduleTime
                          .compareTo(b.gymClass.scheduleTime),
                    );

                    final next = sessions.firstWhere(
                        (s) => s.gymClass.scheduleTime.isAfter(DateTime.now()),
                        orElse: () => sessions.last);

                    return _classGroupCard(
                      context: context,
                      className: className,
                      sessions: sessions,
                      nextSession: next,
                      provider: provider,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // -------------------------------------------------------------------
      // FAB
      // -------------------------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        label: const Text("Schedule Class"),
        icon: const Icon(Icons.add),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddClassScreen())),
      ),
    );
  }

  // -------------------------------------------------------------------
  // EMPTY STATE
  // -------------------------------------------------------------------
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "No classes scheduled",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // ⭐ PREMIUM CLASS GROUP CARD
  // -------------------------------------------------------------------
  Widget _classGroupCard({
    required BuildContext context,
    required String className,
    required List<DetailedGymClass> sessions,
    required DetailedGymClass nextSession,
    required ClassProvider provider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          childrenPadding: EdgeInsets.zero,
          iconColor: Colors.black87,
          collapsedIconColor: Colors.black54,

          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade50,
            child: Text(
              className[0].toUpperCase(),
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          title: Text(
            className,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "${sessions.length} Sessions Scheduled",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                "Next: ${DateFormat('MMM d, h:mm a').format(nextSession.gymClass.scheduleTime)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          trailing: IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            tooltip: "Delete all sessions",
            onPressed: () =>
                _confirmBatchDelete(context, provider, className, sessions),
          ),

          // --------------------------------------------------------------
          // EXPANDED SESSION LIST
          // --------------------------------------------------------------
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final isPast =
                      s.gymClass.scheduleTime.isBefore(DateTime.now());

                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      Icons.event,
                      size: 20,
                      color: isPast ? Colors.grey : Colors.blue,
                    ),
                    title: Text(
                      DateFormat('EEE, MMM d • h:mm a')
                          .format(s.gymClass.scheduleTime),
                      style: TextStyle(
                        color: isPast ? Colors.grey : Colors.black87,
                        decoration:
                            isPast ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      s.trainerFullName,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, size: 18, color: Colors.grey),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddClassScreen(gymClass: s.gymClass),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.red),
                          onPressed: () =>
                              _confirmDeleteSingle(context, provider, s),
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
  }

  // -------------------------------------------------------------------
  // CONFIRM DELETE: BATCH
  // -------------------------------------------------------------------
  void _confirmBatchDelete(
    BuildContext context,
    ClassProvider provider,
    String className,
    List<DetailedGymClass> sessions,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete All Sessions?"),
        content: Text(
          "You are about to delete ALL ${sessions.length} sessions for \"$className\".\nThis cannot be undone.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              provider.deleteBatchGymClasses(
                  sessions.map((s) => s.gymClass.classId).toList());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete All",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // CONFIRM DELETE: SINGLE
  // -------------------------------------------------------------------
  void _confirmDeleteSingle(
    BuildContext context,
    ClassProvider provider,
    DetailedGymClass session,
  ) {
    final date = DateFormat('MMM d – h:mm a')
        .format(session.gymClass.scheduleTime);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete This Session?"),
        content: Text("Do you want to delete the session on $date?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Yes, Delete",
                style: TextStyle(color: Colors.red)),
            onPressed: () {
              provider.deleteGymClass(session.gymClass.classId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
