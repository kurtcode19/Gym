import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/providers/pt_provider.dart';
import 'package:gym/screens/add_pt_session_screen.dart';
import 'package:gym/models/pt_session.dart';

class PTSessionsScreen extends StatefulWidget {
  const PTSessionsScreen({super.key});

  @override
  State<PTSessionsScreen> createState() => _PTSessionsScreenState();
}

class _PTSessionsScreenState extends State<PTSessionsScreen> {
  String query = "";

  // STATUS COLORS
  Color _statusColor(PTSession session) {
    final isPaid = session.isPaid == 1 || session.isPaid == true;

    if (session.packageId != null) return Colors.blue;
    if (isPaid) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // =====================================================
      // DARK BACK BUTTON ADDED HERE
      // =====================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        shadowColor: Colors.black26,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Personal Training Sessions",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),

      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by client or trainer...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => query = value.toLowerCase()),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Consumer<PTProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = provider.sessions.where((s) {
                  final customer = s.customerName.toLowerCase();
                  final trainer = s.trainerName.toLowerCase();

                  if (query.isEmpty) return true;
                  return customer.contains(query) || trainer.contains(query);
                }).toList();

                if (filtered.isEmpty) return _emptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final session = item.session;
                    final color = _statusColor(session);

                    return _sessionCard(context, provider, item, session, color);
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPTSessionScreen()),
        ),
        label: const Text("Book Session"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // EMPTY STATE
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No sessions found", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // SESSION CARD UI
  Widget _sessionCard(
    BuildContext context,
    PTProvider provider,
    DetailedPTSession item,
    PTSession session,
    Color color,
  ) {
    final isPaid = session.isPaid == 1 || session.isPaid == true;

    return InkWell(
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddPTSessionScreen(
              preselectedCustomerId: session.customerId,
              preselectedTrainerId: session.trainerId,
              preselectedPackageId: session.packageId,
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON BADGE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center, color: color, size: 24),
            ),

            const SizedBox(width: 14),

            // DETAILS SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),

                  const SizedBox(height: 6),

                  Text("Trainer: ${item.trainerName}",
                      style: TextStyle(color: Colors.grey[800])),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(session.startTime),
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      if (session.packageId != null)
                        _badge("Package", Colors.blue)
                      else if (isPaid)
                        _badge("Paid", Colors.green)
                      else
                        _badge("Unpaid", Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            // MENU + AMOUNT
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (session.packageId == null)
                  Text(
                    NumberFormat.currency(locale: 'en_PH', symbol: '₱')
                        .format(session.cost),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),

                const SizedBox(height: 8),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPTSessionScreen(
                            preselectedCustomerId: session.customerId,
                            preselectedTrainerId: session.trainerId,
                            preselectedPackageId: session.packageId,
                          ),
                        ),
                      );
                    } else if (value == "delete") {
                      _confirmDelete(context, provider, session);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text("Edit Session"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Delete Session"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }

  // DELETE CONFIRMATION
  void _confirmDelete(
      BuildContext context, PTProvider provider, PTSession session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Session?"),
        content: const Text("This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteSession(session);

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Session deleted successfully")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
