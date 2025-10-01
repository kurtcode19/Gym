// lib/screens/add_membership_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/models/membership.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/models/membership_plan.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_plan_provider.dart';

class AddMembershipScreen extends StatefulWidget {
  final Membership? membership;

  const AddMembershipScreen({super.key, this.membership});

  @override
  State<AddMembershipScreen> createState() => _AddMembershipScreenState();
}

class _AddMembershipScreenState extends State<AddMembershipScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _scrollController = ScrollController();
  MembershipPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    if (widget.membership != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final planProvider = Provider.of<MembershipPlanProvider>(context, listen: false);
        try {
          _selectedPlan = planProvider.plans.firstWhere(
            (plan) => plan.planId == widget.membership!.planId,
          );
          setState(() {});
        } catch (e) {
          // Plan not found, will handle in UI
        }
      });
    }
  }

  void _updateEndDate() {
    if (_formKey.currentState == null) return;

    final startDate = _formKey.currentState?.fields['start_date']?.value as DateTime?;

    if (startDate != null && _selectedPlan != null) {
      final calculatedEndDate = _selectedPlan!.calculateEndDate(startDate);
      _formKey.currentState?.fields['end_date']?.didChange(calculatedEndDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.membership != null;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final planProvider = Provider.of<MembershipPlanProvider>(context);
    final theme = Theme.of(context);

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
      initialValues = {
        'start_date': DateTime.now(),
        'end_date': DateTime.now(),
        'status': 'Pending',
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Membership' : 'Add Membership'),
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.card_membership,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEditing ? 'Update Membership' : 'Create New Membership',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: initialValues,
                    enabled: !customerProvider.isLoading && !planProvider.isLoading,
                    child: Scrollbar(
                      controller: _scrollController,
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildSectionHeader('Member Information'),
                          const SizedBox(height: 16),
                          _buildCustomerDropdown(customerProvider),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Plan Details'),
                          const SizedBox(height: 16),
                          _buildPlanDropdown(planProvider),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Membership Period'),
                          const SizedBox(height: 16),
                          _buildDatePickers(context),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Status'),
                          const SizedBox(height: 16),
                          _buildStatusDropdown(),
                          const SizedBox(height: 32),
                          _buildSubmitButton(isEditing, context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildCustomerDropdown(CustomerProvider customerProvider) {
    return FormBuilderDropdown<String>(
      name: 'customer_id',
      decoration: InputDecoration(
        labelText: 'Customer',
        prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) => value == null ? 'Please select a customer' : null,
      items: customerProvider.customers
          .map((customer) => DropdownMenuItem<String>(
                value: customer.customerId,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${customer.firstName} ${customer.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      customer.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPlanDropdown(MembershipPlanProvider planProvider) {
    return FormBuilderDropdown<String>(
      name: 'plan_id',
      decoration: InputDecoration(
        labelText: 'Membership Plan',
        prefixIcon: Icon(Icons.fitness_center, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) => value == null ? 'Please select a plan' : null,
      onChanged: (planId) {
        setState(() {
          try {
            _selectedPlan = planProvider.plans.firstWhere(
              (plan) => plan.planId == planId,
            );
          } catch (e) {
            _selectedPlan = null;
          }
        });
        _updateEndDate();
      },
      items: planProvider.plans
          .map((plan) => DropdownMenuItem<String>(
                value: plan.planId,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.planName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat.currency(symbol: '\$').format(plan.monthlyFee)}/month • ${plan.durationValue} ${plan.durationUnit.toDisplayString()}${plan.durationValue > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDatePickers(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FormBuilderDateTimePicker(
            name: 'start_date',
            decoration: InputDecoration(
              labelText: 'Start Date',
              prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            inputType: InputType.date,
            format: DateFormat('yyyy-MM-dd'),
            validator: (value) => value == null ? 'Start date cannot be empty' : null,
            onChanged: (_) => _updateEndDate(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderDateTimePicker(
            name: 'end_date',
            decoration: InputDecoration(
              labelText: 'End Date',
              prefixIcon: Icon(Icons.event_available, color: Colors.grey[600]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              enabled: false,
            ),
            inputType: InputType.date,
            format: DateFormat('yyyy-MM-dd'),
            validator: (value) => value == null ? 'End date cannot be empty' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return FormBuilderDropdown<String>(
      name: 'status',
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.info_outline, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) => value == null || value.isEmpty ? 'Status cannot be empty' : null,
      items: const [
        DropdownMenuItem(
          value: 'Active',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Active'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'Pending',
          child: Row(
            children: [
              Icon(Icons.pending, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Pending'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'Expired',
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Expired'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'Cancelled',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text('Cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEditing, BuildContext context) {
    return ElevatedButton(
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

          try {
            if (isEditing) {
              await Provider.of<MembershipProvider>(context, listen: false).updateMembership(newMembership);
              _showSuccessSnackbar(context, 'Membership updated successfully!');
            } else {
              await Provider.of<MembershipProvider>(context, listen: false).addMembership(newMembership);
              _showSuccessSnackbar(context, 'Membership added successfully!');
            }
            Navigator.of(context).pop();
          } catch (e) {
            _showErrorSnackbar(context, 'Failed to save membership: $e');
          }
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(55),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isEditing ? Icons.save : Icons.add),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'Update Membership' : 'Add Membership',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}