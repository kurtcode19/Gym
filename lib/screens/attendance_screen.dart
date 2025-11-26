// lib/screens/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/attendance_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_provider.dart'; // Import Membership Provider
import 'package:gym/models/attendance.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormBuilderState> _checkInFormKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchAttendanceRecords();
      // Ensure memberships are loaded for the auto-select logic
      Provider.of<MembershipProvider>(context, listen: false).fetchMemberships();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC: Auto-select Type based on Membership ---
  void _onCustomerSelected(String? customerId) {
    if (customerId == null) return;

    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    
    // Check if this customer has an ACTIVE membership
    final hasActiveMembership = membershipProvider.memberships.any((m) => 
      m.membership.customerId == customerId && 
      m.membership.status.toLowerCase() == 'active' &&
      m.membership.endDate.isAfter(DateTime.now())
    );

    if (hasActiveMembership) {
      // Auto-set to Member
      _checkInFormKey.currentState?.fields['type']?.didChange('Member');
      _checkInFormKey.currentState?.fields['amount_paid']?.didChange('0.00');
    } else {
      // Auto-set to Walk-In
      _checkInFormKey.currentState?.fields['type']?.didChange('Walk-In');
      _checkInFormKey.currentState?.fields['amount_paid']?.didChange('15.00'); // Default walk-in price
    }
  }

  void _showCheckInModal(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check In / Walk-In'),
        content: SingleChildScrollView(
          child: FormBuilder(
            key: _checkInFormKey,
            initialValue: const {
              'type': 'Member', 
              'amount_paid': '0.00',
              'facility_used': 'Gym'
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderDropdown<String>(
                  name: 'member_id',
                  decoration: const InputDecoration(labelText: 'Select Customer', border: OutlineInputBorder()),
                  validator: (val) => val == null ? 'Required' : null,
                  items: customerProvider.customers
                      .map((c) => DropdownMenuItem(
                            value: c.customerId,
                            child: Text('${c.firstName} ${c.lastName}'),
                          ))
                      .toList(),
                  // Apply logic when customer changes
                  onChanged: (val) => _onCustomerSelected(val),
                ),
                const SizedBox(height: 12),
                FormBuilderDropdown<String>(
                  name: 'type',
                  decoration: const InputDecoration(labelText: 'Visit Type', border: OutlineInputBorder()),
                  items: ['Member', 'Walk-In', 'Guest']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    // Manual override logic
                    if (val == 'Walk-In') {
                      _checkInFormKey.currentState?.fields['amount_paid']?.didChange('15.00');
                    } else if (val == 'Member') {
                       _checkInFormKey.currentState?.fields['amount_paid']?.didChange('0.00');
                    }
                  },
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'amount_paid',
                  decoration: const InputDecoration(labelText: 'Amount Paid', prefixText: '\$', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'facility_used',
                  decoration: const InputDecoration(labelText: 'Facility', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_checkInFormKey.currentState?.saveAndValidate() ?? false) {
                final data = _checkInFormKey.currentState!.value;
                
                final newAttendance = Attendance(
                  attendanceId: const Uuid().v4(),
                  memberId: data['member_id'],
                  checkinTime: DateTime.now(),
                  checkoutTime: null,
                  type: data['type'],
                  amountPaid: double.tryParse(data['amount_paid'].toString()) ?? 0.0,
                  facilityUsed: data['facility_used'],
                );

                await Provider.of<AttendanceProvider>(context, listen: false).addAttendance(newAttendance);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  // New Function: Confirm Clear History
  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will delete all past attendance records. Active check-ins will not be deleted.\n\nAre you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<AttendanceProvider>(context, listen: false).clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared.')));
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          // Clear History Button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear History',
            onPressed: () => _confirmClearHistory(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
             Tab(text: 'Active (${attendanceProvider.activeCheckIns.length})'),
             const Tab(text: 'History'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCheckInModal(context),
        icon: const Icon(Icons.login),
        label: const Text('Check In'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(context, attendanceProvider.activeCheckIns, true),
          _buildList(context, attendanceProvider.historyCheckIns, false),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<DetailedAttendance> list, bool isActive) {
    if (list.isEmpty) return const Center(child: Text("No records found", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (ctx, i) {
        final item = list[i];
        final att = item.attendance;
        final duration = (att.checkoutTime ?? DateTime.now()).difference(att.checkinTime);
        final durationStr = '${duration.inHours}h ${duration.inMinutes % 60}m';

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: att.type == 'Walk-In' ? Colors.orange[100] : Colors.blue[100],
              child: Icon(att.type == 'Walk-In' ? Icons.local_activity : Icons.person),
            ),
            title: Text('${item.customerFirstName} ${item.customerLastName}'),
            subtitle: Text(
              '${att.type} • In: ${DateFormat('h:mm a').format(att.checkinTime)} • Duration: $durationStr'
              '${att.amountPaid > 0 ? '\nPaid: \$${att.amountPaid}' : ''}',
            ),
            isThreeLine: att.amountPaid > 0,
            trailing: isActive
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
                    onPressed: () => Provider.of<AttendanceProvider>(context, listen: false).checkOut(att.attendanceId),
                    child: const Text('Out'),
                  )
                : Text(DateFormat('MMM d').format(att.date)),
          ),
        );
      },
    ); 
  }
}