import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/trainer_package_provider.dart';
import 'package:gym/screens/add_trainer_package_screen.dart';
import 'package:intl/intl.dart';

class TrainerPackagesScreen extends StatelessWidget {
  const TrainerPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Personal Training Packages', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<TrainerPackageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          
          if (provider.packages.isEmpty) {
            return const Center(child: Text("No active packages"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.packages.length,
            itemBuilder: (context, index) {
              final item = provider.packages[index];
              final pkg = item.package;
              final status = pkg.calculatedStatus;
              final isUnlimited = pkg.totalSessions == -1;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(pkg.packageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Member: ${item.customerName}'),
                      Text('Trainer: ${item.trainerName}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('Expires: ${DateFormat('MMM d, yyyy').format(pkg.endDate)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      )
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isUnlimited ? 'Unlimited' : '${pkg.sessionsRemaining} left',
                        style: TextStyle(
                          color: status == 'Active' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                      ),
                      Text('${pkg.sessionsUsed} / ${isUnlimited ? '∞' : pkg.totalSessions} used', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTrainerPackageScreen()));
        },
        label: const Text("New Package"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}