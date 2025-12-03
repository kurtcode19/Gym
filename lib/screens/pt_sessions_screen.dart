// lib/screens/pt_sessions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/pt_provider.dart';
import 'package:gym/models/pt_session.dart';
import 'package:gym/screens/add_pt_session_screen.dart';
import 'package:intl/intl.dart';

class PTSessionsScreen extends StatefulWidget {
  const PTSessionsScreen({super.key});

  @override
  State<PTSessionsScreen> createState() => _PTSessionsScreenState();
}

class _PTSessionsScreenState extends State<PTSessionsScreen> {
  String _searchQuery = "";

  Color _getStatusColor(PTSession session) {
    if (session.packageId != null) return Colors.blue; // Package
    if (session.isPaid) return Colors.green; // Cash Paid
    return Colors.orange; // Unpaid
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Personal Training', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search client or trainer...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          Expanded(
            child: Consumer<PTProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                
                // Filter logic
                final sessions = provider.sessions.where((item) {
                  if (_searchQuery.isEmpty) return true;
                  return item.customerName.toLowerCase().contains(_searchQuery) ||
                         item.trainerName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (sessions.isEmpty) {
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final item = sessions[index];
                    final session = item.session;
                    final statusColor = _getStatusColor(session);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.fitness_center, color: statusColor, size: 24),
                        ),
                        title: Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(item.trainerName, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
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
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (session.packageId != null)
                              const Chip(
                                label: Text("Package", style: TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              )
                            else
                              Text(
                                NumberFormat.currency(symbol: '₱').format(session.cost),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                          ],
                        ),
                        onLongPress: () => provider.deleteSession(session.sessionId as PTSession),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPTSessionScreen())),
        label: const Text("Book Session"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}