// lib/screens/memberships_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/screens/add_membership_screen.dart';
import 'package:gym/models/membership.dart'; // <--- THIS IMPORT IS CRUCIAL
import 'package:intl/intl.dart';

class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});

  // Helper to determine membership status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memberships'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search memberships...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<MembershipProvider>(context, listen: false).searchMemberships(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<MembershipProvider>(
              builder: (context, membershipProvider, child) {
                if (membershipProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (membershipProvider.memberships.isEmpty) {
                  return const Center(child: Text('No memberships found.'));
                } else {
                  return ListView.builder(
                    itemCount: membershipProvider.memberships.length,
                    itemBuilder: (context, index) {
                      final detailedMembership = membershipProvider.memberships[index];
                      final membership = detailedMembership.membership;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(membership.status),
                            child: Text(
                              membership.status[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${detailedMembership.customerFirstName} ${detailedMembership.customerLastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Plan: ${detailedMembership.planName}'),
                              Text(
                                'Dates: ${DateFormat('MMM d, yyyy').format(membership.startDate)} - '
                                    '${DateFormat('MMM d, yyyy').format(membership.endDate)}',
                              ),
                              Text('Status: ${membership.status}'),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddMembershipScreen(
                                  membership: membership,
                                  // Pass customer/plan details if needed for pre-filling, or re-fetch in screen
                                ),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, membershipProvider, membership);
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
              builder: (context) => const AddMembershipScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MembershipProvider membershipProvider, Membership membership) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Membership'),
          content: Text('Are you sure you want to delete this membership?'),
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
                membershipProvider.deleteMembership(membership.membershipId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membership deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}