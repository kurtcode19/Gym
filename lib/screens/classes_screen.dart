// lib/screens/classes_screen.dart
// FINAL OPTIMIZED VERSION – FAST, CLEAN & BUG-FREE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/class_provider.dart';
import 'package:gym/models/class.dart';
import 'package:gym/screens/add_class_screen.dart';
import 'package:intl/intl.dart';
import 'package:gym/utils/app_refresher.dart';

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

      appBar: AppBar(
        title: const Text(
          "Class Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: Column(
        children: [
          _buildSearchBar(theme),

          Expanded(
            child: Consumer<ClassProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final classes = provider.classes;

                if (classes.isEmpty) return _emptyState();

                // ------------------------------------------------------------
                // ⭐ MUCH FASTER GROUPING (O(n) NOT O(n²))
                // ------------------------------------------------------------
                final grouped = <String, List<DetailedGymClass>>{};
                for (final c in classes) {
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
                      (a, b) => a.gymClass.scheduleTime.compareTo(b.gymClass.scheduleTime),
                    );

                    // NEXT SESSION (SAFE & FAST)
                    DetailedGymClass? nextSession;
                    for (final s in sessions) {
                      if (s.gymClass.scheduleTime.isAfter(DateTime.now())) {
                        nextSession = s;
                        break;
                      }
                    }
                    nextSession ??= sessions.last;

                    return _classGroupCard(
                      context: context,
                      className: className,
                      sessions: sessions,
                      nextSession: nextSession!,
                      provider: provider,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        label: const Text("Schedule Class"),
        icon: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddClassScreen()),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEARCH BAR — LIGHTWEIGHT + OPTIMIZED
  // ----------------------------------------------------------
  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(.06),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search classes...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (q) {
          Provider.of<ClassProvider>(context, listen: false).searchGymClasses(q.trim());
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // EMPTY DISPLAY
  // ----------------------------------------------------------
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

  // ----------------------------------------------------------
  // MAIN CARD GROUP
  // ----------------------------------------------------------
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
            color: Colors.black.withOpacity(.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            const SizedBox(height: 3),
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
          onPressed: () => _confirmBatchDelete(context, provider, className, sessions),
        ),

        children: [
          _sessionList(context, provider, sessions),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // OPTIMIZED LIST OF SESSIONS
  // ----------------------------------------------------------
  Widget _sessionList(
      BuildContext context, ClassProvider provider, List<DetailedGymClass> sessions) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        itemCount: sessions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (_, i) {
          final s = sessions[i];
          final isPast = s.gymClass.scheduleTime.isBefore(DateTime.now());

          return ListTile(
            visualDensity: VisualDensity.compact,
            leading: Icon(
              Icons.event,
              size: 20,
              color: isPast ? Colors.grey : Colors.blue,
            ),
            title: Text(
              DateFormat('EEE, MMM d • h:mm a').format(s.gymClass.scheduleTime),
              style: TextStyle(
                color: isPast ? Colors.grey : Colors.black,
                decoration: isPast ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(s.trainerFullName, style: const TextStyle(fontSize: 13)),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddClassScreen(gymClass: s.gymClass),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => _confirmDeleteSingle(context, provider, s),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // DELETE ALL SESSIONS
  // ----------------------------------------------------------
  void _confirmBatchDelete(
      BuildContext context,
      ClassProvider provider,
      String className,
      List<DetailedGymClass> sessions) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete All Sessions?"),
        content: Text("Delete ALL ${sessions.length} sessions for \"$className\"?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteBatchGymClasses(
                  sessions.map((s) => s.gymClass.classId).toList());
              if (mounted) await AppRefresher.refreshAll(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete All"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // DELETE SINGLE SESSION
  // ----------------------------------------------------------
  void _confirmDeleteSingle(
      BuildContext context,
      ClassProvider provider,
      DetailedGymClass session) {
    final date = DateFormat('MMM d – h:mm a').format(session.gymClass.scheduleTime);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Session?"),
        content: Text("Delete this session on $date?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Yes, Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteGymClass(session.gymClass.classId);
              if (mounted) await AppRefresher.refreshAll(context);
            },
          ),
        ],
      ),
    );
  }
}
