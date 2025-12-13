import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/providers/trainer_package_provider.dart';
import 'package:gym/screens/add_trainer_package_screen.dart';
import 'package:gym/screens/add_pt_session_screen.dart';
import 'package:gym/models/trainer_package.dart';

class TrainerPackagesScreen extends StatefulWidget {
  const TrainerPackagesScreen({super.key});

  @override
  State<TrainerPackagesScreen> createState() => _TrainerPackagesScreenState();
}

class _TrainerPackagesScreenState extends State<TrainerPackagesScreen> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black26,
        centerTitle: true,

        // ✅ DARK BACK BUTTON
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Personal Training Packages",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
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
                hintText: "Search packages...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => query = value.toLowerCase());
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Consumer<TrainerPackageProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 🔎 FILTER LOGIC
                final filtered = provider.packages.where((p) {
                  return p.package.packageName.toLowerCase().contains(query) ||
                      p.customerName.toLowerCase().contains(query) ||
                      p.trainerName.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) return _emptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final pkg = item.package;
                    final isUnlimited = pkg.totalSessions == -1;

                    return _packageCard(context, provider, item, pkg, isUnlimited);
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        label: const Text("New Package"),
        icon: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTrainerPackageScreen()),
        ),
      ),
    );
  }

  // 🟦 EMPTY STATE
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "No active packages",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // 🟩 PACKAGE CARD
  Widget _packageCard(
    BuildContext context,
    TrainerPackageProvider provider,
    DetailedTrainerPackage item,
    TrainerPackage pkg,
    bool isUnlimited,
  ) {
    final bool isExpired = pkg.endDate.isBefore(DateTime.now());

    return InkWell(
      onLongPress: () {
        // AUTO-OPEN PT SESSION SCREEN
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddPTSessionScreen(
              preselectedCustomerId: pkg.customerId,
              preselectedTrainerId: pkg.trainerId,
              preselectedPackageId: pkg.packageId,
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON BADGE
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red.withOpacity(0.15)
                    : Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpired ? Icons.lock_clock : Icons.fitness_center,
                color: isExpired ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(width: 14),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME + STATUS
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pkg.packageName,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired ? "EXPIRED" : "ACTIVE",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Member: ${item.customerName}",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    "Trainer: ${item.trainerName}",
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        "Expires: ${DateFormat('MMM d, yyyy').format(pkg.endDate)}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // RIGHT SIDE ACTIONS
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isUnlimited ? "Unlimited" : "${pkg.sessionsRemaining} left",
                  style: TextStyle(
                    color: isExpired ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  isUnlimited
                      ? "${pkg.sessionsUsed} / ∞ used"
                      : "${pkg.sessionsUsed} / ${pkg.totalSessions} used",
                  style: const TextStyle(fontSize: 11),
                ),

                const SizedBox(height: 6),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onSelected: (value) {
                    if (value == "edit") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddTrainerPackageScreen(package: pkg),
                        ),
                      );
                    } else if (value == "delete") {
                      _confirmDelete(context, provider, pkg);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text("Edit Package"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Delete Package"),
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

  // DELETE CONFIRMATION
  void _confirmDelete(
      BuildContext context, TrainerPackageProvider provider, TrainerPackage pkg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Package?"),
        content: const Text(
          "This will remove the package.\n"
          "PT sessions already created will remain but lose package link.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deletePackage(pkg.packageId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Package deleted successfully")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
