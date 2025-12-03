import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/screens/add_trainer_screen.dart';
import 'package:gym/utils/app_refresher.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
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
          "Trainers",
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
                    offset: const Offset(0, 3))
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search trainers by name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                Provider.of<TrainerProvider>(context, listen: false)
                    .searchTrainers(query);
              },
            ),
          ),

          const SizedBox(height: 8),

          // -------------------------------------------------------------------
          // TRAINER LIST
          // -------------------------------------------------------------------
          Expanded(
            child: Consumer<TrainerProvider>(
              builder: (context, trainerProvider, child) {
                if (trainerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (trainerProvider.trainers.isEmpty) {
                  return _emptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trainerProvider.trainers.length,
                  itemBuilder: (context, index) {
                    final trainer = trainerProvider.trainers[index];
                    return _trainerCard(context, trainerProvider, trainer);
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        label: const Text("New Trainer"),
        icon: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTrainerScreen()),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // ⭐ PREMIUM EMPTY STATE
  // -------------------------------------------------------------------
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            "No trainers found",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // ⭐ PREMIUM TRAINER CARD
  // -------------------------------------------------------------------
  Widget _trainerCard(
    BuildContext context,
    TrainerProvider provider,
    Trainer trainer,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTrainerScreen(trainer: trainer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar Box
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  trainer.firstName.isNotEmpty
                      ? trainer.firstName[0].toUpperCase()
                      : "?",
                  style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),

              const SizedBox(width: 16),

              // Trainer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${trainer.firstName} ${trainer.lastName}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),

                    if (trainer.email != null && trainer.email!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trainer.email!,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    if (trainer.phoneNumber != null &&
                        trainer.phoneNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              trainer.phoneNumber!,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Delete
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: () {
                  _confirmDelete(context, provider, trainer);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // DELETE CONFIRMATION
  // -------------------------------------------------------------------
  void _confirmDelete(
      BuildContext context, TrainerProvider provider, Trainer trainer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Trainer?"),
        content: Text(
          "Delete ${trainer.firstName} ${trainer.lastName}?\n\n"
          "This action cannot be undone and will unassign them from all classes.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context)),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              provider.deleteTrainer(trainer.trainerId);
              Navigator.pop(context);

              if (context.mounted) {
                await AppRefresher.refreshAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${trainer.firstName} deleted.")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
