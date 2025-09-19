// lib/screens/add_membership_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/membership.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/models/membership_plan.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_plan_provider.dart';
import 'package:intl/intl.dart';

class AddMembershipScreen extends StatefulWidget {
  final Membership? membership; // Optional: for editing existing membership

  const AddMembershipScreen({super.key, this.membership});

  @override
  State<AddMembershipScreen> createState() => _AddMembershipScreenState();
}

class _AddMembershipScreenState extends State<AddMembershipScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.membership != null;
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final planProvider = Provider.of<MembershipPlanProvider>(context, listen: false);

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
        'end_date': DateTime.now().add(const Duration(days: 365)), // Default 1 year
        'status': 'Active', // Default status
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
                items: planProvider.plans
                    .map((plan) => DropdownMenuItem<String>(
                          value: plan.planId,
                          child: Text('${plan.planName} (${NumberFormat.currency(symbol: '\$').format(plan.monthlyFee)}/month)'),
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
              ),
              const SizedBox(height: 16),
              // End Date
              FormBuilderDateTimePicker(
                name: 'end_date',
                decoration: const InputDecoration(labelText: 'End Date'),
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