// lib/screens/trainers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/screens/add_trainer_screen.dart';

class TrainersScreen extends StatelessWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search trainers...',
                prefixIcon: Icon(Icons.search),
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
                  return const Center(child: Text('No trainers found.'));
                } else {
                  return ListView.builder(
                    itemCount: trainerProvider.trainers.length,
                    itemBuilder: (context, index) {
                      final trainer = trainerProvider.trainers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              trainer.firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text('${trainer.firstName} ${trainer.lastName}'),
                          subtitle: Text(trainer.email ?? 'No email'),
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTrainerScreen(trainer: trainer),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, trainerProvider, trainer);
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
              builder: (context) => const AddTrainerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TrainerProvider trainerProvider, Trainer trainer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Trainer'),
          content: Text('Are you sure you want to delete ${trainer.firstName} ${trainer.lastName}? This will unassign them from classes.'),
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
                trainerProvider.deleteTrainer(trainer.trainerId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${trainer.firstName} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}