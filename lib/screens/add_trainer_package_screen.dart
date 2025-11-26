// lib/screens/add_trainer_package_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gym/models/trainer_package.dart';
import 'package:gym/providers/trainer_package_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/trainer_provider.dart';

class AddTrainerPackageScreen extends StatefulWidget {
  const AddTrainerPackageScreen({super.key});

  @override
  State<AddTrainerPackageScreen> createState() => _AddTrainerPackageScreenState();
}

class _AddTrainerPackageScreenState extends State<AddTrainerPackageScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  
  // 0 = Session Based (e.g., 10 sessions)
  // 1 = Time Based (e.g., Unlimited for 1 month)
  int _planType = 0; 

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sell PT Package')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: {
            'start_date': DateTime.now(),
            'end_date': DateTime.now().add(const Duration(days: 30)), // Default 1 month
            'sessions': '10',
            'price': '0.00',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. People
              FormBuilderDropdown<String>(
                name: 'customer_id',
                decoration: const InputDecoration(labelText: 'Select Member', border: OutlineInputBorder()),
                validator: (val) => val == null ? 'Required' : null,
                items: customerProvider.customers.map((c) => 
                  DropdownMenuItem(value: c.customerId, child: Text('${c.firstName} ${c.lastName}'))
                ).toList(),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'trainer_id',
                decoration: const InputDecoration(labelText: 'Select Trainer', border: OutlineInputBorder()),
                validator: (val) => val == null ? 'Required' : null,
                items: trainerProvider.trainers.map((t) => 
                  DropdownMenuItem(value: t.trainerId, child: Text('${t.firstName} ${t.lastName}'))
                ).toList(),
              ),
              
              const SizedBox(height: 24),
              const Text("Plan Type", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // 2. Plan Type Toggle
              ToggleButtons(
                isSelected: [_planType == 0, _planType == 1],
                onPressed: (index) {
                  setState(() {
                    _planType = index;
                    // Update end date logic if switching
                    if (_planType == 1) {
                       _formKey.currentState?.fields['sessions']?.didChange('Unlimited');
                    } else {
                       _formKey.currentState?.fields['sessions']?.didChange('10');
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 40) / 2, minHeight: 45),
                children: const [
                  Text("Count Based (e.g. 10 Sess)"),
                  Text("Time Based (Unlimited)"),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Dynamic Fields
              if (_planType == 0) ...[
                FormBuilderTextField(
                  name: 'sessions',
                  decoration: const InputDecoration(labelText: 'Number of Sessions', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                FormBuilderDateTimePicker(
                  name: 'end_date', // Validity period for the sessions
                  inputType: InputType.date,
                  decoration: const InputDecoration(labelText: 'Valid Until (Expiry)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                ),
              ] else ...[
                // Time Based Logic
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'start_date',
                        inputType: InputType.date,
                        decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'end_date',
                        inputType: InputType.date,
                        decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'package_name',
                decoration: const InputDecoration(labelText: 'Package Name', hintText: 'e.g. Summer Body Promo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'price',
                decoration: const InputDecoration(labelText: 'Total Price (₱)', prefixText: '₱ ', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final data = _formKey.currentState!.value;
                      
                      final pkg = TrainerPackage(
                        customerId: data['customer_id'],
                        trainerId: data['trainer_id'],
                        packageName: data['package_name'] ?? (_planType == 0 ? "${data['sessions']} Sessions" : "Unlimited"),
                        price: double.parse(data['price']),
                        // If Plan Type 0 (Count), use number. If Type 1 (Time), use -1 for unlimited
                        totalSessions: _planType == 0 ? int.parse(data['sessions']) : -1,
                        startDate: data['start_date'] ?? DateTime.now(),
                        endDate: data['end_date'],
                        status: 'Active',
                      );

                      await Provider.of<TrainerPackageProvider>(context, listen: false).addPackage(pkg);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package Activated!')));
                      }
                    }
                  },
                  child: const Text('Activate Package'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}