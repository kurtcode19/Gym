// lib/screens/add_membership_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/membership_plan.dart';
import 'package:gym/providers/membership_plan_provider.dart';

class AddMembershipPlanScreen extends StatefulWidget {
  final MembershipPlan? plan; // Optional: for editing existing plan

  const AddMembershipPlanScreen({super.key, this.plan});

  @override
  State<AddMembershipPlanScreen> createState() => _AddMembershipPlanScreenState();
}

class _AddMembershipPlanScreenState extends State<AddMembershipPlanScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Membership Plan' : 'Add Membership Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: isEditing
              ? {
                  'plan_name': widget.plan!.planName,
                  'monthly_fee': widget.plan!.monthlyFee.toString(),
                  'duration': widget.plan!.duration.toString(),
                }
              : {},
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'plan_name',
                decoration: const InputDecoration(labelText: 'Plan Name'),
                validator: (value) => value == null || value.isEmpty ? 'Plan name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'monthly_fee',
                decoration: const InputDecoration(labelText: 'Monthly Fee (\$)', hintText: 'e.g., 50.00'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Monthly fee cannot be empty';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) <= 0) return 'Monthly fee must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'duration',
                decoration: const InputDecoration(labelText: 'Duration (months)', hintText: 'e.g., 12'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Duration cannot be empty';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  if (int.parse(value) <= 0) return 'Duration must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newPlan = MembershipPlan(
                      planId: isEditing ? widget.plan!.planId : null,
                      planName: data['plan_name'],
                      monthlyFee: double.parse(data['monthly_fee']),
                      duration: int.parse(data['duration']),
                    );

                    if (isEditing) {
                      await Provider.of<MembershipPlanProvider>(context, listen: false).updateMembershipPlan(newPlan);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newPlan.planName} updated successfully!')),
                      );
                    } else {
                      await Provider.of<MembershipPlanProvider>(context, listen: false).addMembershipPlan(newPlan);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newPlan.planName} added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Make button wide
                ),
                child: Text(isEditing ? 'Update Plan' : 'Add Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}