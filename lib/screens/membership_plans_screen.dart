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
          // Enhanced Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search plans...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              onChanged: (query) {
                Provider.of<MembershipPlanProvider>(context, listen: false).searchMembershipPlans(query);
              },
            ),
          ),
          // Plan Count
          Consumer<MembershipPlanProvider>(
            builder: (context, planProvider, child) {
              if (planProvider.plans.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${planProvider.plans.length} plan${planProvider.plans.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 8),
          // Plan List
          Expanded(
            child: Consumer<MembershipPlanProvider>(
              builder: (context, planProvider, child) {
                if (planProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading membership plans...'),
                      ],
                    ),
                  );
                } else if (planProvider.plans.isEmpty) {
                  return _buildEmptyState(context);
                } else {
                  return _buildPlanList(planProvider, context);
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Membership Plans',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first membership plan to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMembershipPlanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(MembershipPlanProvider planProvider, BuildContext context) {
    return ListView.separated(
      itemCount: planProvider.plans.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final plan = planProvider.plans[index];
        return _buildPlanCard(plan, planProvider, context);
      },
    );
  }

  Widget _buildPlanCard(MembershipPlan plan, MembershipPlanProvider planProvider, BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.fitness_center,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          plan.planName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    NumberFormat.currency(symbol: '\$').format(plan.monthlyFee),
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${plan.durationValue} ${plan.durationUnit.toDisplayString()}${plan.durationValue > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ${NumberFormat.currency(symbol: '\$').format(plan.monthlyFee * plan.durationValue)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMembershipPlanScreen(plan: plan),
                ),
              );
            } else if (value == 'delete') {
              _confirmDelete(context, planProvider, plan);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMembershipPlanScreen(plan: plan),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, MembershipPlanProvider planProvider, MembershipPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Delete Plan'),
            ],
          ),
          content: Text('Are you sure you want to delete "${plan.planName}"? This will affect existing memberships.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
              onPressed: () {
                planProvider.deleteMembershipPlan(plan.planId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${plan.planName} deleted successfully.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}