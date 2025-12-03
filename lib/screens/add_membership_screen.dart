// lib/screens/add_membership_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/membership.dart';
import 'package:gym/models/membership_plan.dart';
import 'package:gym/providers/membership_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/membership_plan_provider.dart';
import 'package:intl/intl.dart';

class AddMembershipScreen extends StatefulWidget {
  final Membership? membership;
  final bool isRenewal;

  const AddMembershipScreen({
    super.key,
    this.membership,
    this.isRenewal = false,
  });

  @override
  State<AddMembershipScreen> createState() => _AddMembershipScreenState();
}

class _AddMembershipScreenState extends State<AddMembershipScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final ScrollController _scroll = ScrollController();
  MembershipPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();

    if (widget.membership != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final planProvider =
            Provider.of<MembershipPlanProvider>(context, listen: false);
        try {
          _selectedPlan = planProvider.plans.firstWhere(
            (plan) => plan.planId == widget.membership!.planId,
          );
          setState(() {});
        } catch (_) {}
      });
    }
  }

  void _updateEndDate() {
    final start =
        _formKey.currentState?.fields["start_date"]?.value as DateTime?;

    if (start != null && _selectedPlan != null) {
      final newEnd = _selectedPlan!.calculateEndDate(start);
      _formKey.currentState?.fields["end_date"]?.didChange(newEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.membership != null;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final planProvider = Provider.of<MembershipPlanProvider>(context);

    final theme = Theme.of(context);

    final initialValues = isEditing
        ? {
            "customer_id": widget.membership!.customerId,
            "plan_id": widget.membership!.planId,
            "start_date": widget.membership!.startDate,
            "end_date": widget.membership!.endDate,
            "status": widget.membership!.status,
          }
        : {
            "start_date": DateTime.now(),
            "end_date": DateTime.now(),
            "status": "Pending",
          };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          isEditing ? "Edit Membership" : "Add Membership",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          _buildPremiumHeader(theme, isEditing),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FormBuilder(
                  key: _formKey,
                  initialValue: initialValues,
                  child: Scrollbar(
                    controller: _scroll,
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _sectionTitle("Member Information"),
                        const SizedBox(height: 12),
                        _customerDropdown(customerProvider),

                        const SizedBox(height: 24),
                        _sectionTitle("Plan Details"),
                        const SizedBox(height: 12),
                        _planDropdown(planProvider),

                        if (_selectedPlan != null) _planPriceTag(_selectedPlan!),

                        const SizedBox(height: 24),
                        _sectionTitle("Membership Period"),
                        const SizedBox(height: 12),
                        _datePickers(),

                        const SizedBox(height: 24),
                        _sectionTitle("Status"),
                        const SizedBox(height: 12),
                        _statusDropdown(),

                        const SizedBox(height: 32),
                        _submitButton(isEditing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // PREMIUM HEADER
  // ----------------------------------------------------------------------

  Widget _buildPremiumHeader(ThemeData theme, bool isEditing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.08),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_membership,
                size: 40, color: theme.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            isEditing ? "Update Membership" : "Create New Membership",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // SECTION TITLE
  // ----------------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: Colors.black87,
      ),
    );
  }

  // ----------------------------------------------------------------------
  // CUSTOMER DROPDOWN
  // ----------------------------------------------------------------------

  Widget _customerDropdown(CustomerProvider provider) {
    return FormBuilderDropdown<String>(
      name: "customer_id",
      validator: (v) => v == null ? "Select a customer" : null,
      decoration: _premiumInput("Customer", Icons.person),
      items: provider.customers
          .map(
            (c) => DropdownMenuItem(
              value: c.customerId,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${c.firstName} ${c.lastName}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(c.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ----------------------------------------------------------------------
  // PLAN DROPDOWN
  // ----------------------------------------------------------------------

  Widget _planDropdown(MembershipPlanProvider provider) {
    return FormBuilderDropdown<String>(
      name: "plan_id",
      validator: (v) => v == null ? "Select a plan" : null,
      decoration: _premiumInput("Membership Plan", Icons.fitness_center),
      onChanged: (planId) {
        setState(() {
          _selectedPlan = provider.plans.firstWhere(
            (p) => p.planId == planId,
            orElse: () => provider.plans.first,
          );
        });
        _updateEndDate();
      },
      items: provider.plans
          .map(
            (plan) => DropdownMenuItem(
              value: plan.planId,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.planName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${plan.monthlyFee.toStringAsFixed(2)} / month • ${plan.durationValue} ${plan.durationUnit.toDisplayString()}${plan.durationValue > 1 ? 's' : ''}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ----------------------------------------------------------------------
  // PLAN PRICE TAG (PREMIUM HIGHLIGHT)
  // ----------------------------------------------------------------------

  Widget _planPriceTag(MembershipPlan plan) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(.08),
        border: Border.all(color: Colors.green.withOpacity(.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "₱${plan.monthlyFee.toStringAsFixed(2)} / month",
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // DATE PICKERS
  // ----------------------------------------------------------------------

  Widget _datePickers() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderDateTimePicker(
            name: "start_date",
            inputType: InputType.date,
            format: DateFormat("yyyy-MM-dd"),
            decoration: _premiumInput("Start Date", Icons.calendar_today),
            onChanged: (_) => _updateEndDate(),
            validator: (v) => v == null ? "Required" : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FormBuilderDateTimePicker(
            name: "end_date",
            inputType: InputType.date,
            enabled: false,
            format: DateFormat("yyyy-MM-dd"),
            decoration: _premiumInput("End Date", Icons.event_available)
                .copyWith(
                  fillColor: Colors.grey[200],
                ),
            validator: (v) => v == null ? "Required" : null,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // STATUS DROPDOWN
  // ----------------------------------------------------------------------

  Widget _statusDropdown() {
    return FormBuilderDropdown<String>(
      name: "status",
      validator: (v) => v == null ? "Required" : null,
      decoration: _premiumInput("Status", Icons.info_outline),
      items: const [
        DropdownMenuItem(
          value: "Active",
          child: Text("Active"),
        ),
        DropdownMenuItem(value: "Pending", child: Text("Pending")),
        DropdownMenuItem(value: "Expired", child: Text("Expired")),
        DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // PREMIUM INPUT DECORATION
  // ----------------------------------------------------------------------

  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ----------------------------------------------------------------------
  // SUBMIT BUTTON
  // ----------------------------------------------------------------------

  Widget _submitButton(bool isEditing) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState?.saveAndValidate() ?? false) {
          final data = _formKey.currentState!.value;

          final membership = Membership(
            membershipId: isEditing ? widget.membership!.membershipId : null,
            customerId: data["customer_id"],
            planId: data["plan_id"],
            startDate: data["start_date"],
            endDate: data["end_date"],
            status: data["status"],
          );

          try {
            final provider =
                Provider.of<MembershipProvider>(context, listen: false);

            if (isEditing) {
              await provider.updateMembership(membership);
              _success("Membership updated!");
            } else {
              await provider.addMembership(membership);
              _success("Membership added!");
            }

            Navigator.pop(context);
          } catch (e) {
            _error("Failed: $e");
          }
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(55),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isEditing ? Icons.save : Icons.add),
          const SizedBox(width: 10),
          Text(
            isEditing ? "Update Membership" : "Add Membership",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _success(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
