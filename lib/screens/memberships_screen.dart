import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/screens/add_membership_screen.dart';
import 'package:gym/screens/add_payment_screen.dart';
import 'package:gym/models/membership.dart';
import 'package:intl/intl.dart';
import 'package:gym/utils/email_sender.dart';   // 👈 NEW

class MembershipsScreen extends StatefulWidget {
  const MembershipsScreen({super.key});

  @override
  State<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends State<MembershipsScreen> {
  bool _filtersExpanded = false;

  // STATUS COLOR
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "expired":
        return Colors.red;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // STATUS ICON
  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Icons.check_circle;
      case "expired":
        return Icons.timer_off;
      case "pending":
        return Icons.pending;
      case "cancelled":
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MembershipProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Memberships",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // SEARCH + FILTER BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(.08),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search by name or plan...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: provider.searchMemberships,
                      ),
                    ),

                    const SizedBox(width: 12),

                    GestureDetector(
                      onTap: () {
                        setState(() => _filtersExpanded = !_filtersExpanded);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(.08),
                                blurRadius: 6)
                          ],
                        ),
                        child: Icon(
                          _filtersExpanded
                              ? Icons.filter_list_off
                              : Icons.filter_list,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  height: _filtersExpanded ? 60 : 0,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child:
                      _filtersExpanded ? _buildFilterOptions(provider) : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Consumer<MembershipProvider>(
            builder: (_, prov, __) {
              if (prov.memberships.isNotEmpty) {
                final active = prov.memberships
                    .where((m) =>
                        m.membership.status.toLowerCase() == "active")
                    .length;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${prov.memberships.length} Total Memberships",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (active > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$active Active",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.memberships.isEmpty
                    ? _emptyState()
                    : _membershipList(provider),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        label: const Text("New Membership"),
        icon: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddMembershipScreen()));
        },
      ),
    );
  }

  //
  // MEMBERSHIP LIST
  //
  Widget _membershipList(MembershipProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.memberships.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final detailed = provider.memberships[index];
        return _membershipCard(context, provider, detailed);
      },
    );
  }

  //
  // UPDATED CARD WITH EMAIL BUTTON
  //
  Widget _membershipCard(BuildContext ctx,
      MembershipProvider provider, DetailedMembership d) {
    final m = d.membership;
    final color = _statusColor(m.status);
    final expired =
        m.status.toLowerCase() == "expired" ||
            m.status.toLowerCase() == "cancelled";

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          //
          // MAIN LIST TILE
          //
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_statusIcon(m.status), color: color, size: 26),
            ),

            title: Text(
              "${d.customerFirstName} ${d.customerLastName}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(d.planName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          m.status,
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${DateFormat('MMM d, yyyy').format(m.startDate)} - "
                    "${DateFormat('MMM d, yyyy').format(m.endDate)}",
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

            //
            // MENU BUTTON
            //
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == "renew") {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddMembershipScreen(membership: m, isRenewal: true),
                    ),
                  );
                } else if (value == "payment") {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddPaymentScreen(preSelectedMembershipId: m.membershipId),
                    ),
                  );
                } else if (value == "edit") {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => AddMembershipScreen(membership: m),
                    ),
                  );
                } else if (value == "delete") {
                  _confirmDelete(ctx, provider, m);
                }
              },
              itemBuilder: (_) => [
                if (expired)
                  const PopupMenuItem(
                    value: "renew",
                    child: Row(
                      children: [
                        Icon(Icons.autorenew, color: Colors.green),
                        SizedBox(width: 10),
                        Text("Renew"),
                      ],
                    ),
                  ),
                if (!expired)
                  const PopupMenuItem(
                    value: "payment",
                    child: Row(
                      children: [
                        Icon(Icons.payment, color: Colors.blue),
                        SizedBox(width: 10),
                        Text("Make Payment"),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.black87),
                      SizedBox(width: 10),
                      Text("Edit"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Delete"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          //
          // ⭐ NEW: EXPIRE SOON EMAIL REMINDER BUTTON
          //
          if (m.isExpiringSoon)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.email, color: Colors.white),
                  label: const Text(
                    "Send Expiry Reminder",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    try {
                      await sendExpiryEmail(
                        email: d.customerEmail,
                        memberName:
                            "${d.customerFirstName} ${d.customerLastName}",
                        expiryDate: m.endDate,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Email app opened!")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Failed to open email: $e"),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // DELETE CONFIRMATION
  void _confirmDelete(
      BuildContext context, MembershipProvider provider, Membership m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Membership?"),
        content:
            const Text("Are you sure you want to delete this membership?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text("Delete", style: TextStyle(color: Colors.white)),
            onPressed: () {
              provider.deleteMembership(m.membershipId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Membership deleted")),
              );
            },
          ),
        ],
      ),
    );
  }

  // FILTER OPTIONS
  Widget _buildFilterOptions(MembershipProvider provider) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _chip("All", provider),
        _chip("Active", provider),
        _chip("Pending", provider),
        _chip("Expired", provider),
        _chip("Cancelled", provider),
        _chip("Expiring Soon", provider),
        _chip("Expired This Month", provider),
      ],
    );
  }

  Widget _chip(String label, MembershipProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        selected: provider.currentFilter == label,
        selectedColor: Colors.blue.shade200,
        onSelected: (_) => provider.applyFilter(label),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No memberships found",
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
