// lib/screens/add_pt_session_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:gym/models/pt_session.dart';
import 'package:gym/models/trainer_package.dart';
import 'package:gym/providers/pt_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/utils/app_refresher.dart';

class AddPTSessionScreen extends StatefulWidget {
  const AddPTSessionScreen({super.key});

  @override
  State<AddPTSessionScreen> createState() => _AddPTSessionScreenState();
}

class _AddPTSessionScreenState extends State<AddPTSessionScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<TrainerPackage> _availablePackages = [];
  bool _isLoadingPackages = false;
  double _trainerRate = 0.0;
  bool _usingPackage = false;

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Future<void> _fetchPackages(String customerId) async {
    setState(() => _isLoadingPackages = true);
    final db = DatabaseHelper();
    final allPackages = await db.getTrainerPackages();

    final filtered = allPackages
        .map((m) => TrainerPackage.fromJson(m))
        .where((p) =>
            p.customerId == customerId &&
            p.calculatedStatus == 'Active' &&
            p.sessionsRemaining > 0)
        .toList();

    setState(() {
      _availablePackages = filtered;
      _isLoadingPackages = false;
    });
  }

  void _onTrainerSelected(String? trainerId) {
    if (trainerId == null) return;
    final provider = Provider.of<TrainerProvider>(context, listen: false);
    final trainer =
        provider.trainers.firstWhere((t) => t.trainerId == trainerId);

    setState(() => _trainerRate = trainer.ratePerSession);

    if (!_usingPackage) {
      _formKey.currentState?.fields['cost']
          ?.didChange(_trainerRate.toStringAsFixed(2));
    }
  }

  void _onPaymentMethodChanged(String? value) {
    setState(() => _usingPackage = value != "cash");

    if (value == "cash") {
      // Cash session → paid manually
      _formKey.currentState?.fields['cost']
          ?.didChange(_trainerRate.toStringAsFixed(2));
      _formKey.currentState?.fields['is_paid']?.didChange(false);
    } else {
      // Package session → no revenue recorded here
      _formKey.currentState?.fields['cost']?.didChange("0.00");
      _formKey.currentState?.fields['is_paid']?.didChange(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          title: const Text('Book PT Session'),
          elevation: 0,
          centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          initialValue: {
            'start_time': DateTime.now().add(const Duration(hours: 1)),
            'duration': '60',
            'cost': '0.00',
            'is_paid': false,
            'package_id': 'cash',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Who"),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FormBuilderDropdown<String>(
                        name: 'customer_id',
                        decoration: _fieldDecoration('Customer', Icons.person),
                        items: customerProvider.customers
                            .map((c) => DropdownMenuItem(
                                value: c.customerId,
                                child: Text(
                                    '${c.firstName} ${c.lastName}')))
                            .toList(),
                        onChanged: (val) =>
                            val != null ? _fetchPackages(val) : null,
                        validator: (val) =>
                            val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<String>(
                        name: 'trainer_id',
                        decoration:
                            _fieldDecoration('Trainer', Icons.sports_gymnastics),
                        items: trainerProvider.trainers
                            .map((t) => DropdownMenuItem(
                                value: t.trainerId,
                                child: Text(
                                    '${t.firstName} ${t.lastName} (₱${t.ratePerSession})')))
                            .toList(),
                        onChanged: _onTrainerSelected,
                        validator: (val) =>
                            val == null ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader("When"),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FormBuilderDateTimePicker(
                        name: 'start_time',
                        inputType: InputType.both,
                        decoration:
                            _fieldDecoration('Date & Time', Icons.calendar_today),
                        validator: (val) =>
                            val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'duration',
                        decoration:
                            _fieldDecoration('Duration (min)', Icons.timer),
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader("Payment"),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _isLoadingPackages
                          ? const LinearProgressIndicator()
                          : FormBuilderDropdown<String>(
                              name: 'package_id',
                              decoration: _fieldDecoration(
                                  'Payment Method', Icons.payment),
                              items: [
                                const DropdownMenuItem(
                                    value: 'cash',
                                    child:
                                        Text('Pay Per Session (Cash/Card)')),
                                ..._availablePackages.map((p) =>
                                    DropdownMenuItem(
                                        value: p.packageId,
                                        child: Text(
                                            '${p.packageName} (${p.sessionsRemaining} left)'))),
                              ],
                              onChanged: _onPaymentMethodChanged,
                            ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'cost',
                              readOnly: _usingPackage,
                              decoration: _fieldDecoration(
                                  'Cost (₱)', Icons.attach_money),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormBuilderSwitch(
                              name: 'is_paid',
                              enabled: !_usingPackage,
                              title: const Text("Paid?",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!(_formKey.currentState?.saveAndValidate() ?? false))
                      return;

                    final data = _formKey.currentState!.value;
                    final ptProvider =
                        Provider.of<PTProvider>(context, listen: false);

                    final duration = int.parse(data['duration']);

                    if (!ptProvider.checkAvailability(
                        data['trainer_id'],
                        data['start_time'],
                        duration)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trainer is busy!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newSession = PTSession(
                      sessionId: const Uuid().v4(),
                      customerId: data['customer_id'],
                      trainerId: data['trainer_id'],
                      packageId:
                          data['package_id'] == 'cash' ? null : data['package_id'],
                      startTime: data['start_time'],
                      durationMinutes: duration,
                      cost: double.parse(data['cost']),
                      status: "Completed",
                      isPaid: data['package_id'] == 'cash'
                          ? data['is_paid']
                          : false, // packages never mark paid
                      trainerPaid: false,
                      notes: null,
                    );

                    await ptProvider.addSession(newSession);

                    if (mounted) {
                      await AppRefresher.refreshAll(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Session Booked Successfully!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Confirm Booking",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700])),
    );
  }
}
