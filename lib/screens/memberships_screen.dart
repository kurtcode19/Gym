// lib/screens/memberships_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/screens/add_membership_screen.dart';
import 'package:gym/models/membership.dart';
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

  // Helper to get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'expired':
        return Icons.error;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
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
                hintText: 'Search memberships...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              onChanged: (query) {
                Provider.of<MembershipProvider>(context, listen: false).searchMemberships(query);
              },
            ),
          ),
          // Membership Count and Status Summary
          Consumer<MembershipProvider>(
            builder: (context, membershipProvider, child) {
              if (membershipProvider.memberships.isNotEmpty) {
                final activeCount = membershipProvider.memberships
                    .where((m) => m.membership.status.toLowerCase() == 'active')
                    .length;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${membershipProvider.memberships.length} membership${membershipProvider.memberships.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (activeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$activeCount active',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
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
          // Membership List
          Expanded(
            child: Consumer<MembershipProvider>(
              builder: (context, membershipProvider, child) {
                if (membershipProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading memberships...'),
                      ],
                    ),
                  );
                } else if (membershipProvider.memberships.isEmpty) {
                  return _buildEmptyState(context);
                } else {
                  return _buildMembershipList(membershipProvider, context);
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Memberships',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first membership to get started',
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
                  builder: (context) => const AddMembershipScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Membership'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipList(MembershipProvider membershipProvider, BuildContext context) {
    return ListView.separated(
      itemCount: membershipProvider.memberships.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final detailedMembership = membershipProvider.memberships[index];
        final membership = detailedMembership.membership;
        return _buildMembershipCard(detailedMembership, membershipProvider, context);
      },
    );
  }

  Widget _buildMembershipCard(DetailedMembership detailedMembership, MembershipProvider membershipProvider, BuildContext context) {
    final membership = detailedMembership.membership;
    final statusColor = _getStatusColor(membership.status);
    
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
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Icon(
            _getStatusIcon(membership.status),
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          '${detailedMembership.customerFirstName} ${detailedMembership.customerLastName}',
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    membership.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detailedMembership.planName,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormat('MMM d, yyyy').format(membership.startDate)} - ${DateFormat('MMM d, yyyy').format(membership.endDate)}',
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
                  builder: (context) => AddMembershipScreen(membership: membership),
                ),
              );
            } else if (value == 'delete') {
              _confirmDelete(context, membershipProvider, membership);
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
              builder: (context) => AddMembershipScreen(membership: membership),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, MembershipProvider membershipProvider, Membership membership) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Delete Membership'),
            ],
          ),
          content: const Text('Are you sure you want to delete this membership?'),
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
                membershipProvider.deleteMembership(membership.membershipId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Membership deleted successfully.'),
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