// lib/screens/trainers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/screens/add_trainer_screen.dart';
import 'package:intl/intl.dart';
import 'package:gym/utils/app_refresher.dart'; // Import the utility
class TrainersScreen extends StatelessWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Trainers', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
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
                hintText: 'Search trainers by name...',
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
                Provider.of<TrainerProvider>(context, listen: false).searchTrainers(query);
              },
            ),
          ),
          
          Expanded(
            child: Consumer<TrainerProvider>(
              builder: (context, trainerProvider, child) {
                if (trainerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (trainerProvider.trainers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No trainers found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trainerProvider.trainers.length,
                    itemBuilder: (context, index) {
                      final trainer = trainerProvider.trainers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTrainerScreen(trainer: trainer),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.orange.shade100,
                                  child: Text(
                                    trainer.firstName.isNotEmpty ? trainer.firstName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${trainer.firstName} ${trainer.lastName}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (trainer.email != null && trainer.email!.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                trainer.email!,
                                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (trainer.phoneNumber != null && trainer.phoneNumber!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                trainer.phoneNumber!,
                                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Delete Action
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                                  onPressed: () {
                                    _confirmDelete(context, trainerProvider, trainer);
                                  },
                                ),
                              ],
                            ),
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
              builder: (context) => const AddTrainerScreen(),
            ),
          );
        },
        label: const Text("New Trainer"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _confirmDelete(BuildContext context, TrainerProvider trainerProvider, Trainer trainer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Trainer?'),
          content: Text('Are you sure you want to delete ${trainer.firstName} ${trainer.lastName}?\n\nThis action cannot be undone and will unassign them from any scheduled classes.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                trainerProvider.deleteTrainer(trainer.trainerId);
                Navigator.of(context).pop();
                  // 2. Refresh everything
  if (context.mounted) {
    await AppRefresher.refreshAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${trainer.firstName} deleted.')),
                );
  }
              },
            ),
          ],
        );
      },
    );
  }
}