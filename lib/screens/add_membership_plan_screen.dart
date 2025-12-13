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
  State<AddMembershipPlanScreen> createState() =>
      _AddMembershipPlanScreenState();
}

class _AddMembershipPlanScreenState extends State<AddMembershipPlanScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plan != null;

    final initialValues = isEditing
        ? {
            'plan_name': widget.plan!.planName,
            'monthly_fee': widget.plan!.monthlyFee.toString(),
            'duration_value': widget.plan!.durationValue.toString(),
            'duration_unit': widget.plan!.durationUnit,
          }
        : {
            'duration_value': '12',
            'duration_unit': DurationUnit.months,
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // ----------------------------------------------------------------------
      // PREMIUM APP BAR
      // ----------------------------------------------------------------------
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        title: Text(
          isEditing ? "Edit Membership Plan" : "Add Membership Plan",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteDialog(context),
            )
        ],
      ),

      // ----------------------------------------------------------------------
      // BODY
      // ----------------------------------------------------------------------
      body: Column(
        children: [
          // ------------------------------------------------------------------
          // PREMIUM HEADER
          // ------------------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEEF4FF),
                  Color(0xFFE9F5FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isEditing
                      ? "Update Membership Plan"
                      : "Create New Membership Plan",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? "Modify existing plan details"
                      : "Fill out details to create a new plan",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                )
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // FORM CARD
          // ------------------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: FormBuilder(
                  key: _formKey,
                  initialValue: initialValues,
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(22),
                      children: [
                        _sectionHeader("Plan Information"),
                        const SizedBox(height: 16),

                        _textField(
                          name: "plan_name",
                          label: "Plan Name",
                          icon: Icons.badge_outlined,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),

                        _textField(
                          name: "monthly_fee",
                          label: "Monthly Fee (₱)",
                          icon: Icons.attach_money_outlined,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          hintText: "e.g. 3000.00",
                        ),

                        const SizedBox(height: 30),
                        _sectionHeader("Duration"),
                        const SizedBox(height: 16),

                        _durationFields(),

                        const SizedBox(height: 36),
                        _submitButton(isEditing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SECTION HEADER
  // --------------------------------------------------------------------------
  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        )
      ],
    );
  }

  // --------------------------------------------------------------------------
  // PREMIUM TEXT FIELD
  // --------------------------------------------------------------------------
  Widget _textField({
    required String name,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "$label is required";
        }
        if (name == "monthly_fee") {
          if (value == null || value.isEmpty) return "Fee is required";
          if (double.tryParse(value) == null) return "Enter a valid number";
          if (double.parse(value) <= 0) return "Fee must be positive";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DURATION FIELDS (Value + Unit)
  // --------------------------------------------------------------------------
  Widget _durationFields() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: FormBuilderTextField(
            name: "duration_value",
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              if (int.tryParse(value) == null) {
                return "Must be number";
              }
              if (int.parse(value) <= 0) {
                return "Must be positive";
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: "Duration",
              hintText: "e.g. 12",
              prefixIcon: Icon(Icons.timelapse, color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: FormBuilderDropdown<DurationUnit>(
            name: "duration_unit",
            validator: (value) => value == null ? "Required" : null,
            decoration: InputDecoration(
              labelText: "Unit",
              prefixIcon: Icon(Icons.schedule, color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
            items: DurationUnit.values
                .map(
                  (unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit.toDisplayString()),
                  ),
                )
                .toList(),
          ),
        )
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SUBMIT BUTTON
  // --------------------------------------------------------------------------
  Widget _submitButton(bool isEditing) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

          final data = _formKey.currentState!.value;
          final plan = MembershipPlan(
            planId: isEditing ? widget.plan!.planId : null,
            planName: data['plan_name'],
            monthlyFee: double.parse(data['monthly_fee']),
            durationValue: int.parse(data['duration_value']),
            durationUnit: data['duration_unit'],
          );

          try {
            final provider =
                Provider.of<MembershipPlanProvider>(context, listen: false);

            if (isEditing) {
              await provider.updateMembershipPlan(plan);
              _success("${plan.planName} updated successfully!");
            } else {
              await provider.addMembershipPlan(plan);
              _success("${plan.planName} added successfully!");
            }

            Navigator.pop(context);
          } catch (e) {
            _error("Failed to save plan: $e");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isEditing ? Icons.save : Icons.add),
            const SizedBox(width: 8),
            Text(
              isEditing ? "Update Plan" : "Add Plan",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DELETE DIALOG
  // --------------------------------------------------------------------------
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Delete Plan"),
          ],
        ),
        content: Text(
            'Are you sure you want to delete "${widget.plan!.planName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<MembershipPlanProvider>(context, listen: false)
                  .deleteMembershipPlan(widget.plan!.planId);

              Navigator.pop(context);
              Navigator.pop(context);
              _success("Plan deleted successfully!");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SNACKBAR HELPERS
  // --------------------------------------------------------------------------
  void _success(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
