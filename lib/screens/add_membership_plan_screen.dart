// lib/screens/add_membership_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/membership_plan.dart';
import 'package:gym/providers/membership_plan_provider.dart';

class AddMembershipPlanScreen extends StatefulWidget {
  final MembershipPlan? plan;

  const AddMembershipPlanScreen({super.key, this.plan});

  @override
  State<AddMembershipPlanScreen> createState() => _AddMembershipPlanScreenState();
}

class _AddMembershipPlanScreenState extends State<AddMembershipPlanScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plan != null;
    final theme = Theme.of(context);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'plan_name': widget.plan!.planName,
        'monthly_fee': widget.plan!.monthlyFee.toString(),
        'duration_value': widget.plan!.durationValue.toString(),
        'duration_unit': widget.plan!.durationUnit,
      };
    } else {
      initialValues = {
        'duration_value': '12',
        'duration_unit': DurationUnit.months,
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Membership Plan' : 'Add Membership Plan'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteDialog(context),
            ),
        ],
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
                      Icons.fitness_center,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEditing ? 'Update Membership Plan' : 'Create New Plan',
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
                    child: Scrollbar(
                      controller: _scrollController,
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildSectionHeader('Plan Information'),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'plan_name',
                            label: 'Plan Name',
                            icon: Icons.badge_outlined,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'monthly_fee',
                            label: 'Fee (\₱)',
                            icon: Icons.attach_money_outlined,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            hintText: 'e.g., 50.00',
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Duration'),
                          const SizedBox(height: 16),
                          _buildDurationFields(),
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

  Widget _buildTextField({
    required String name,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) return '$label is required';
              if (name == 'monthly_fee') {
                if (double.tryParse(value) == null) return 'Invalid number';
                if (double.parse(value) <= 0) return 'Monthly fee must be positive';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDurationFields() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: FormBuilderTextField(
            name: 'duration_value',
            decoration: InputDecoration(
              labelText: 'Duration Value',
              hintText: 'e.g., 12',
              prefixIcon: Icon(Icons.numbers, color: Colors.grey[600]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Value cannot be empty';
              if (int.tryParse(value) == null) return 'Invalid number';
              if (int.parse(value) <= 0) return 'Value must be positive';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: FormBuilderDropdown<DurationUnit>(
            name: 'duration_unit',
            decoration: InputDecoration(
              labelText: 'Unit',
              prefixIcon: Icon(Icons.timelapse, color: Colors.grey[600]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) => value == null ? 'Unit cannot be empty' : null,
            items: DurationUnit.values
                .map((unit) => DropdownMenuItem<DurationUnit>(
                      value: unit,
                      child: Text(unit.toDisplayString()),
                    ))
                .toList(),
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
          final newPlan = MembershipPlan(
            planId: isEditing ? widget.plan!.planId : null,
            planName: data['plan_name'],
            monthlyFee: double.parse(data['monthly_fee']),
            durationValue: int.parse(data['duration_value']),
            durationUnit: data['duration_unit'] as DurationUnit,
          );

          try {
            if (isEditing) {
              await Provider.of<MembershipPlanProvider>(context, listen: false).updateMembershipPlan(newPlan);
              _showSuccessSnackbar(context, '${newPlan.planName} updated successfully!');
            } else {
              await Provider.of<MembershipPlanProvider>(context, listen: false).addMembershipPlan(newPlan);
              _showSuccessSnackbar(context, '${newPlan.planName} added successfully!');
            }
            Navigator.of(context).pop();
          } catch (e) {
            _showErrorSnackbar(context, 'Failed to save plan: $e');
          }
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(55),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isEditing ? Icons.save : Icons.add),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'Update Plan' : 'Add Plan',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Plan'),
            ],
          ),
          content: Text('Are you sure you want to delete "${widget.plan!.planName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Provider.of<MembershipPlanProvider>(context, listen: false)
                    .deleteMembershipPlan(widget.plan!.planId);
                Navigator.of(context)
                  ..pop()
                  ..pop();
                _showSuccessSnackbar(context, 'Plan deleted successfully!');
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
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