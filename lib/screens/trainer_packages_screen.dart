import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/trainer_package_provider.dart';
import 'package:gym/screens/add_trainer_package_screen.dart';
import 'package:gym/models/trainer_package.dart';
import 'package:intl/intl.dart';

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

      // -------------------------------------------------------------------
      // ⭐ PREMIUM APP BAR
      // -------------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          "Personal Training Packages",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

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
                  offset: const Offset(0, 3),
                )
              ],
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

          // -------------------------------------------------------------------
          // ⭐ CONTENT
          // -------------------------------------------------------------------
          Expanded(
            child: Consumer<TrainerPackageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

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
                    final status = pkg.calculatedStatus;
                    final isUnlimited = pkg.totalSessions == -1;

                    return _packageCard(context, provider, item, pkg, status, isUnlimited);
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

  // -------------------------------------------------------------------
  // ⭐ EMPTY STATE
  // -------------------------------------------------------------------
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

  // -------------------------------------------------------------------
  // ⭐ PREMIUM PACKAGE CARD
  // -------------------------------------------------------------------
  Widget _packageCard(
    BuildContext context,
    TrainerPackageProvider provider,
    DetailedTrainerPackage item,
    TrainerPackage pkg,
    String status,
    bool isUnlimited,
  ) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

        // PACKAGE NAME
        title: Text(
          pkg.packageName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        // DETAILS
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text("Member: ${item.customerName}",
                style: TextStyle(color: Colors.grey[600])),
            Text("Trainer: ${item.trainerName}",
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "Expires: ${DateFormat('MMM d, yyyy').format(pkg.endDate)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),

        // TRAILING SECTION
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isUnlimited ? "Unlimited" : "${pkg.sessionsRemaining} left",
              style: TextStyle(
                color: status == "Active" ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              "${pkg.sessionsUsed} / ${isUnlimited ? '∞' : pkg.totalSessions} used",
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 4),

            // MENU BUTTON
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == "edit") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTrainerPackageScreen(package: pkg),
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
                      Text("Edit"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // DELETE CONFIRMATION
  // -------------------------------------------------------------------
  void _confirmDelete(
      BuildContext context, TrainerPackageProvider provider, TrainerPackage pkg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Package?"),
        content: const Text(
          "This will remove the package.\n\n"
          "Past sessions linked to this package will remain but will lose their reference.",
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
                const SnackBar(content: Text("Package deleted")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
