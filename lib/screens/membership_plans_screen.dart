// lib/screens/membership_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/membership_plan_provider.dart';
import 'package:gym/models/membership_plan.dart';
import 'package:gym/screens/add_membership_plan_screen.dart';
import 'package:intl/intl.dart';

class MembershipPlansScreen extends StatelessWidget {
  const MembershipPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Plans'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search plans...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<MembershipPlanProvider>(context, listen: false).searchMembershipPlans(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<MembershipPlanProvider>(
              builder: (context, planProvider, child) {
                if (planProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (planProvider.plans.isEmpty) {
                  return const Center(child: Text('No membership plans found.'));
                } else {
                  return ListView.builder(
                    itemCount: planProvider.plans.length,
                    itemBuilder: (context, index) {
                      final plan = planProvider.plans[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(plan.planName),
                          subtitle: Text(
                            '${NumberFormat.currency(symbol: '\$').format(plan.monthlyFee)}/month '
                            '• ${plan.duration} months'
                          ),
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddMembershipPlanScreen(plan: plan),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, planProvider, plan);
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
              builder: (context) => const AddMembershipPlanScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MembershipPlanProvider planProvider, MembershipPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Plan'),
          content: Text('Are you sure you want to delete "${plan.planName}"? This will affect existing memberships.'),
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
                planProvider.deleteMembershipPlan(plan.planId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${plan.planName} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}