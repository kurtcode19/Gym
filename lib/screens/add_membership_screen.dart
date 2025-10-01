// lib/screens/add_membership_screen.dart - UPDATED CONTENT
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/models/membership.dart'; // Corrected import
import 'package:gym/models/customer.dart'; // Corrected import
import 'package:gym/models/membership_plan.dart'; // Corrected import
import 'package:gym/providers/membership_provider.dart'; // Corrected import
import 'package:gym/providers/customer_provider.dart'; // Corrected import
import 'package:gym/providers/membership_plan_provider.dart'; // Corrected import

class AddMembershipScreen extends StatefulWidget {
  final Membership? membership; // Optional: for editing existing membership

  const AddMembershipScreen({super.key, this.membership});

  @override
  State<AddMembershipScreen> createState() => _AddMembershipScreenState();
}

class _AddMembershipScreenState extends State<AddMembershipScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  MembershipPlan? _selectedPlan; // Keep track of selected plan for end date calculation

  @override
  void initState() {
    super.initState();
    if (widget.membership != null) {
      // If editing, try to pre-select the plan to recalculate end date if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final planProvider = Provider.of<MembershipPlanProvider>(context, listen: false);
        _selectedPlan = planProvider.plans.firstWhere(
          (plan) => plan.planId == widget.membership!.planId,
          orElse: () => throw Exception('Membership Plan not found for ID: ${widget.membership!.planId}'),
        );
        setState(() {}); // Rebuild to ensure _selectedPlan is set if needed for display logic
      });
    }
  }

  // Helper to dynamically calculate end date when start date or plan changes
  void _updateEndDate() {
    if (_formKey.currentState == null) return;

    final startDate = _formKey.currentState?.fields['start_date']?.value as DateTime?;

    if (startDate != null && _selectedPlan != null) {
      final calculatedEndDate = _selectedPlan!.calculateEndDate(startDate);
      // Update the form field directly
      _formKey.currentState?.fields['end_date']?.didChange(calculatedEndDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.membership != null;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final planProvider = Provider.of<MembershipPlanProvider>(context);

    // Initial values for the form when editing
    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'customer_id': widget.membership!.customerId,
        'plan_id': widget.membership!.planId,
        'start_date': widget.membership!.startDate,
        'end_date': widget.membership!.endDate,
        'status': widget.membership!.status,
      };
    } else {
      // Default to today for new memberships
      initialValues = {
        'start_date': DateTime.now(),
        'end_date': DateTime.now(), // Will be updated by _updateEndDate
        'status': 'Pending', // Default status
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Membership' : 'Add Membership'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          enabled: !customerProvider.isLoading && !planProvider.isLoading, // Disable form if data is loading
          child: ListView(
            children: [
              // Customer Selection
              FormBuilderDropdown<String>(
                name: 'customer_id',
                decoration: const InputDecoration(labelText: 'Customer'),
                validator: (value) => value == null ? 'Please select a customer' : null,
                items: customerProvider.customers
                    .map((customer) => DropdownMenuItem<String>(
                          value: customer.customerId,
                          child: Text('${customer.firstName} ${customer.lastName} (${customer.email})'),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Plan Selection
              FormBuilderDropdown<String>(
                name: 'plan_id',
                decoration: const InputDecoration(labelText: 'Membership Plan'),
                validator: (value) => value == null ? 'Please select a plan' : null,
                onChanged: (planId) {
                  setState(() {
                    _selectedPlan = planProvider.plans.firstWhere(
                      (plan) => plan.planId == planId,
                      orElse: () => throw Exception('Membership Plan not found for ID: $planId'),
                    );
                  });
                  _updateEndDate(); // Recalculate end date when plan changes
                },
                items: planProvider.plans
                    .map((plan) => DropdownMenuItem<String>(
                          value: plan.planId,
                          child: Text(
                            '${plan.planName} '
                            '(${NumberFormat.currency(symbol: '\$').format(plan.monthlyFee)}) '
                            '[${plan.durationValue} ${plan.durationUnit.toDisplayString()}${plan.durationValue > 1 ? '' : ''}]',
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Start Date
              FormBuilderDateTimePicker(
                name: 'start_date',
                decoration: const InputDecoration(labelText: 'Start Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Start date cannot be empty' : null,
                onChanged: (_) => _updateEndDate(), // Recalculate end date when start date changes
              ),
              const SizedBox(height: 16),
              // End Date (auto-calculated, read-only unless editing and manually overridden)
              FormBuilderDateTimePicker(
                name: 'end_date',
                decoration: const InputDecoration(labelText: 'End Date', enabled: false), // Make it read-only
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'End date cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              // Status
              FormBuilderDropdown<String>(
                name: 'status',
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) => value == null || value.isEmpty ? 'Status cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                  DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newMembership = Membership(
                      membershipId: isEditing ? widget.membership!.membershipId : null,
                      customerId: data['customer_id'],
                      planId: data['plan_id'],
                      startDate: data['start_date'],
                      endDate: data['end_date'],
                      status: data['status'],
                    );

                    if (isEditing) {
                      await Provider.of<MembershipProvider>(context, listen: false).updateMembership(newMembership);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Membership updated successfully!')),
                      );
                    } else {
                      await Provider.of<MembershipProvider>(context, listen: false).addMembership(newMembership);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Membership added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Membership' : 'Add Membership'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}