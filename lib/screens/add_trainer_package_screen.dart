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

  int _planType = 0; // 0 = session-based, 1 = unlimited

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _planType = widget.package!.totalSessions == -1 ? 1 : 0;
    }
  }

  // ------------------------ PREMIUM FIELD DECORATION ------------------------
  InputDecoration _premiumField(String label, IconData icon,
      {String? hint, String? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }

  // ------------------------ SECTION TITLE ------------------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------ PREMIUM CARD ------------------------
  Widget _premiumCard(Widget child) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.package != null;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final trainerProvider = Provider.of<TrainerProvider>(context);

    final customerList = customerProvider.customers;
    final trainerList = trainerProvider.trainers;

    // Defensive: ensure lists are not empty
    if (customerList.isEmpty || trainerList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sell PT Package"),
        ),
        body: const Center(
          child: Text("Required data missing. Please sync your database."),
        ),
      );
    }

    final initialValues = widget.package == null
        ? {
            'start_date': DateTime.now(),
            'end_date': DateTime.now().add(const Duration(days: 30)),
            'sessions': '10',
            'price': '0.00'
          }
        : {
            'customer_id': widget.package!.customerId,
            'trainer_id': widget.package!.trainerId,
            'start_date': widget.package!.startDate,
            'end_date': widget.package!.endDate,
            'sessions': widget.package!.totalSessions == -1
                ? "Unlimited"
                : widget.package!.totalSessions.toString(),
            'package_name': widget.package!.packageName,
            'price': widget.package!.price.toStringAsFixed(2),
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(.08),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isEditing ? "Edit PT Package" : "Sell PT Package",
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Participants"),
              _premiumCard(
                Column(
                  children: [
                    FormBuilderDropdown<String>(
                      name: 'customer_id',
                      decoration: _premiumField("Select Member", Icons.person),
                      validator: (v) => v == null ? "Required" : null,
                      items: customerList
                          .map((c) => DropdownMenuItem(
                                value: c.customerId,
                                child:
                                    Text("${c.firstName} ${c.lastName}"),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDropdown<String>(
                      name: 'trainer_id',
                      decoration: _premiumField(
                          "Select Trainer", Icons.sports_gymnastics),
                      validator: (v) => v == null ? "Required" : null,
                      items: trainerList
                          .map((t) => DropdownMenuItem(
                                value: t.trainerId,
                                child: Text("${t.firstName} ${t.lastName}"),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle("Plan Configuration"),
              _premiumCard(
                Column(
                  children: [
                    ToggleButtons(
                      isSelected: [_planType == 0, _planType == 1],
                      onPressed: (i) {
                        setState(() {
                          _planType = i;
                          _formKey.currentState?.fields['sessions']
                              ?.didChange(i == 1 ? "Unlimited" : "10");
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      selectedColor: Colors.white,
                      fillColor: Colors.blueAccent,
                      children: const [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text("Session-Based")),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text("Unlimited")),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (_planType == 0)
                      FormBuilderTextField(
                        name: 'sessions',
                        decoration:
                            _premiumField("Number of Sessions", Icons.repeat),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),

                    const SizedBox(height: 16),

                    FormBuilderDateTimePicker(
                      name: 'start_date',
                      inputType: InputType.date,
                      decoration:
                          _premiumField("Start Date", Icons.date_range),
                    ),

                    const SizedBox(height: 16),

                    FormBuilderDateTimePicker(
                      name: 'end_date',
                      inputType: InputType.date,
                      decoration:
                          _premiumField("End Date", Icons.event_busy),
                    ),

                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: 'package_name',
                      decoration: _premiumField(
                          "Package Name", Icons.label,
                          hint: "e.g. 12-Session Promo"),
                    ),

                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: 'price',
                      decoration: _premiumField("Total Price", Icons.money,
                          prefix: "₱ "),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitButton(isEditing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEditing ? "Update Package" : "Activate Package",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------ SUBMIT LOGIC (ERROR-PROTECTED) ------------------------
  VoidCallback _submitButton(bool isEditing) {
    return () async {
      try {
        if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
          _toast("Please complete all required fields.");
          return;
        }

        final data = _formKey.currentState!.value;

        // Defensive: ensure customer & trainer selections exist
        if (data['customer_id'] == null ||
            data['trainer_id'] == null) {
          _toast("Customer and trainer must be selected.");
          return;
        }

        // Validate price
        double? price = double.tryParse(data['price'].toString());
        if (price == null || price < 0) {
          _toast("Invalid price.");
          return;
        }

        // Validate session count
        int sessions = -1;
        if (_planType == 0) {
          sessions = int.tryParse(data['sessions'].toString()) ?? -1;
          if (sessions <= 0) {
            _toast("Number of sessions must be a positive number.");
            return;
          }
        }

        // Validate dates
        final start = data['start_date'];
        final end = data['end_date'];

        if (start is! DateTime || end is! DateTime) {
          _toast("Invalid date format.");
          return;
        }

        if (end.isBefore(start)) {
          _toast("End date cannot be before start date.");
          return;
        }

        final provider =
            Provider.of<TrainerPackageProvider>(context, listen: false);

        final pkg = TrainerPackage(
          packageId: isEditing ? widget.package!.packageId : null,
          customerId: data['customer_id'],
          trainerId: data['trainer_id'],
          packageName: data['package_name'],
          price: price,
          totalSessions: sessions,
          sessionsUsed: isEditing ? widget.package!.sessionsUsed : 0,
          startDate: start,
          endDate: end,
          status: "Active",
        );

        if (isEditing) {
          await provider.updatePackage(pkg);
          _toast("Package updated!");
        } else {
          await provider.addPackage(pkg);
          _toast("Package activated!");
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        _toast("Unexpected error: $e");
      }
    };
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
