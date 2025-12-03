// lib/screens/add_trainer_package_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/trainer_package.dart';
import 'package:gym/providers/trainer_package_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/trainer_provider.dart';

class AddTrainerPackageScreen extends StatefulWidget {
  final TrainerPackage? package;

  const AddTrainerPackageScreen({super.key, this.package});

  @override
  State<AddTrainerPackageScreen> createState() =>
      _AddTrainerPackageScreenState();
}

class _AddTrainerPackageScreenState extends State<AddTrainerPackageScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _planType = 0; // 0 = Session Based, 1 = Unlimited

  InputDecoration _fieldDecoration(String label, IconData icon,
      {String? hintText, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _planType = widget.package!.totalSessions == -1 ? 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.package != null;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);

    Map<String, dynamic> initialValues = isEditing
        ? {
            'customer_id': widget.package!.customerId,
            'trainer_id': widget.package!.trainerId,
            'start_date': widget.package!.startDate,
            'end_date': widget.package!.endDate,
            'sessions': widget.package!.totalSessions == -1
                ? 'Unlimited'
                : widget.package!.totalSessions.toString(),
            'package_name': widget.package!.packageName,
            'price': widget.package!.price.toStringAsFixed(2),
          }
        : {
            'start_date': DateTime.now(),
            'end_date': DateTime.now().add(const Duration(days: 30)),
            'sessions': '10',
            'price': '0.00',
          };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Package' : 'Sell PT Package'),
        centerTitle: true,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Participants"),
              _buildParticipantsCard(customerProvider, trainerProvider),

              const SizedBox(height: 24),
              _buildSectionHeader("Plan Configuration"),
              _buildPlanCard(),

              const SizedBox(height: 32),
              _buildSubmitButton(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  // UI WIDGETS -----------------------------------------------------------------------------------

  Widget _buildParticipantsCard(
      CustomerProvider customerProvider, TrainerProvider trainerProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FormBuilderDropdown<String>(
              name: 'customer_id',
              decoration: _fieldDecoration('Select Member', Icons.person),
              validator: (val) => val == null ? 'Required' : null,
              items: customerProvider.customers
                  .map((c) => DropdownMenuItem(
                        value: c.customerId,
                        child: Text("${c.firstName} ${c.lastName}"),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            FormBuilderDropdown<String>(
              name: 'trainer_id',
              decoration:
                  _fieldDecoration('Select Trainer', Icons.sports_gymnastics),
              validator: (val) => val == null ? 'Required' : null,
              items: trainerProvider.trainers
                  .map((t) => DropdownMenuItem(
                        value: t.trainerId,
                        child: Text("${t.firstName} ${t.lastName}"),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: ToggleButtons(
                isSelected: [_planType == 0, _planType == 1],
                onPressed: (index) {
                  setState(() {
                    _planType = index;

                    if (_planType == 1) {
                      _formKey.currentState?.fields['sessions']
                          ?.didChange('Unlimited');
                    } else {
                      _formKey.currentState?.fields['sessions']
                          ?.didChange('10');
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: Theme.of(context).primaryColor,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("Session Based"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("Unlimited Time"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_planType == 0) ...[
              FormBuilderTextField(
                name: 'sessions',
                decoration:
                    _fieldDecoration('Number of Sessions', Icons.repeat),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'end_date',
                inputType: InputType.date,
                decoration:
                    _fieldDecoration('Valid Until (Expiry)', Icons.event_busy),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: FormBuilderDateTimePicker(
                      name: 'start_date',
                      inputType: InputType.date,
                      decoration:
                          _fieldDecoration('Start Date', Icons.date_range),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderDateTimePicker(
                      name: 'end_date',
                      inputType: InputType.date,
                      decoration: _fieldDecoration(
                          'End Date', Icons.event_busy),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'package_name',
              decoration: _fieldDecoration('Package Name', Icons.label,
                  hintText: 'e.g. Summer Body Promo'),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'price',
              decoration:
                  _fieldDecoration('Total Price', Icons.attach_money,
                      prefixText: '₱ '),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _handleSubmit(isEditing),
        child: Text(
          isEditing ? 'Update Package' : 'Activate Package',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // SUBMISSION + ERROR TRAPPING ---------------------------------------------------------------------

  VoidCallback _handleSubmit(bool isEditing) {
    return () async {
      try {
        if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
          _toast("Please complete all required fields.");
          return;
        }

        final data = _formKey.currentState!.value;
        final packageProvider =
            Provider.of<TrainerPackageProvider>(context, listen: false);

        final String customerId = data['customer_id'];
        final String trainerId = data['trainer_id'];

        // -----------------------------
        // 1. LOAD ALL EXISTING PACKAGES
        // -----------------------------
        final existingPackages =
            await packageProvider.getPackagesForCustomer(customerId);

        // Filter same trainer packages except current editing one
        final activeForTrainer = existingPackages.where((p) {
          if (isEditing && p.packageId == widget.package!.packageId) return false;
          return p.trainerId == trainerId && p.status == "Active";
        }).toList();

        // -----------------------------
        // 2. BLOCK IF ACTIVE PACKAGE EXISTS
        // -----------------------------
        if (!isEditing && activeForTrainer.isNotEmpty) {
          final p = activeForTrainer.first;

          // Session-based?
          if (p.totalSessions > 0 && p.sessionsRemaining > 0) {
            _toast(
                "This member still has ${p.sessionsRemaining} unused sessions.\nCannot sell a new package.");
            return;
          }

          // Unlimited still active?
          final now = DateTime.now();
          if (p.totalSessions == -1 && p.endDate.isAfter(now)) {
            _toast(
                "Existing unlimited package is still active.\nCannot add a new one.");
            return;
          }
        }

        // Build package object
        double price = double.parse(data['price']);
        int totalSessions =
            _planType == 0 ? int.parse(data['sessions']) : -1;

        DateTime startDate = data['start_date'] ?? DateTime.now();
        DateTime endDate = data['end_date'];

        final pkg = TrainerPackage(
          packageId: isEditing ? widget.package!.packageId : null,
          customerId: customerId,
          trainerId: trainerId,
          packageName: data['package_name'] ??
              (_planType == 0
                  ? "${data['sessions']} Sessions"
                  : "Unlimited"),
          price: price,
          totalSessions: totalSessions,
          sessionsUsed: isEditing ? widget.package!.sessionsUsed : 0,
          startDate: startDate,
          endDate: endDate,
          status: "Active",
        );

        // -----------------------------
        // 3. SAVE PACKAGE
        // -----------------------------
        if (isEditing) {
          await packageProvider.updatePackage(pkg);
          _toast("Package Updated!");
        } else {
          await packageProvider.addPackage(pkg);
          _toast("Package Activated!");
        }

        if (mounted) Navigator.pop(context);

      } catch (e) {
        _toast("Unexpected Error: $e");
      }
    };
  }

  // HELPER: Show messages
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
