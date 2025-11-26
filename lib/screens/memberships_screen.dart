// lib/screens/memberships_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/screens/add_membership_screen.dart';
import 'package:gym/screens/add_payment_screen.dart';
import 'package:gym/models/membership.dart';
import 'package:intl/intl.dart';

class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green;
      case 'expired': return Colors.red;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Icons.check_circle;
      case 'expired': return Icons.timer_off;
      case 'pending': return Icons.pending;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Memberships', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by name or plan...',
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
                Provider.of<MembershipProvider>(context, listen: false).searchMemberships(query);
              },
            ),
          ),
          
          // Summary Row
          Consumer<MembershipProvider>(
            builder: (context, membershipProvider, child) {
              if (membershipProvider.memberships.isNotEmpty) {
                final activeCount = membershipProvider.memberships
                    .where((m) => m.membership.status.toLowerCase() == 'active')
                    .length;
                
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${membershipProvider.memberships.length} Total Memberships',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      if (activeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$activeCount Active',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),

          // Membership List
          Expanded(
            child: Consumer<MembershipProvider>(
              builder: (context, membershipProvider, child) {
                if (membershipProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMembershipScreen(),
            ),
          );
        },
        label: const Text("New Membership"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No memberships found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMembershipList(MembershipProvider membershipProvider, BuildContext context) {
    return ListView.separated(
      itemCount: membershipProvider.memberships.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final detailedMembership = membershipProvider.memberships[index];
        return _buildMembershipCard(detailedMembership, membershipProvider, context);
      },
    );
  }

  Widget _buildMembershipCard(DetailedMembership detailedMembership, MembershipProvider membershipProvider, BuildContext context) {
    final membership = detailedMembership.membership;
    final statusColor = _getStatusColor(membership.status);
    final isExpired = membership.status.toLowerCase() == 'expired' || membership.status.toLowerCase() == 'cancelled';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getStatusIcon(membership.status), color: statusColor, size: 24),
        ),
        title: Text(
          '${detailedMembership.customerFirstName} ${detailedMembership.customerLastName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.fitness_center, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(detailedMembership.planName, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    membership.status,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormat('MMM d, yyyy').format(membership.startDate)} - ${DateFormat('MMM d, yyyy').format(membership.endDate)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'renew') {
              // Renew Logic: Open Edit screen but potentially treat as "Renew"
              // For simplicity, we open AddMembershipScreen with existing data 
              // but you might want to clear dates to default to "Now"
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMembershipScreen(
                    membership: membership,
                    isRenewal: true, // NEW FLAG to handle renewal logic
                  ),
                ),
              );
            } else if (value == 'payment') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentScreen(
                    preSelectedMembershipId: membership.membershipId,
                  ),
                ),
              );
            } else if (value == 'edit') {
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
            // RENEW BUTTON (Only if expired/cancelled)
            if (isExpired)
              const PopupMenuItem<String>(
                value: 'renew',
                child: Row(
                  children: [
                    Icon(Icons.autorenew, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('Renew Membership'),
                  ],
                ),
              ),
            
            if (!isExpired) // Only show Make Payment if active/pending
              const PopupMenuItem<String>(
                value: 'payment',
                child: Row(
                  children: [
                    Icon(Icons.payment, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Text('Make Payment'),
                  ],
                ),
              ),
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Text('Edit Details'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
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
          title: const Text('Delete Membership?'),
          content: const Text('Are you sure you want to delete this membership record?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                membershipProvider.deleteMembership(membership.membershipId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membership deleted successfully.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}