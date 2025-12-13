// lib/screens/add_trainer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/trainer.dart';
import 'package:gym/providers/trainer_provider.dart';
import 'package:intl/intl.dart';

class AddTrainerScreen extends StatefulWidget {
  final Trainer? trainer;

  const AddTrainerScreen({super.key, this.trainer});

  @override
  State<AddTrainerScreen> createState() => _AddTrainerScreenState();
}

class _AddTrainerScreenState extends State<AddTrainerScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  // ---------------------- PREMIUM FIELD DECORATION ----------------------
  InputDecoration _premiumField(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.4),
      ),
    );
  }

  // ---------------------- PREMIUM SECTION HEADER ----------------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------- PREMIUM CARD ----------------------
  Widget _premiumCard(Widget child) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.trainer != null;

    // ---------------------- INITIAL VALUES ----------------------
    final initialValues = {
      "first_name": widget.trainer?.firstName,
      "last_name": widget.trainer?.lastName,
      "email": widget.trainer?.email,
      "phone_number": widget.trainer?.phoneNumber,
      "hire_date": widget.trainer?.hireDate ?? DateTime.now(),
      "rate_per_session":
          widget.trainer != null ? widget.trainer!.ratePerSession.toString() : "0.00",
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
          isEditing ? "Edit Trainer" : "Add Trainer",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              const SizedBox(height: 10),

              // ---------------------- PERSONAL INFO ----------------------
              _sectionTitle("Personal Information"),
              _premiumCard(
                Column(
                  children: [
                    FormBuilderTextField(
                      name: "first_name",
                      decoration: _premiumField("First Name", Icons.person),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Required"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: "last_name",
                      decoration: _premiumField("Last Name", Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Required"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    FormBuilderDateTimePicker(
                      name: "hire_date",
                      inputType: InputType.date,
                      decoration: _premiumField("Date Hired", Icons.date_range),
                      format: DateFormat("yyyy-MM-dd"),
                      validator: (v) =>
                          v == null ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: "rate_per_session",
                      decoration: _premiumField(
                          "Rate Per Class (₱)", Icons.monetization_on),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Required";
                        if (double.tryParse(value) == null) {
                          return "Invalid number";
                        }
                        if (double.parse(value) < 0) return "Cannot be negative";
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------- CONTACT INFO ----------------------
              _sectionTitle("Contact Details"),
              _premiumCard(
                Column(
                  children: [
                    FormBuilderTextField(
                      name: "email",
                      decoration: _premiumField("Email Address", Icons.email),
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(value.trim())) {
                          return "Invalid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: "phone_number",
                      decoration: _premiumField("Phone Number", Icons.phone),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ---------------------- SUBMIT BUTTON ----------------------
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
                        _showSnack("Please fix the errors in the form.", true);
                        return;
                      }

                      final data = _formKey.currentState!.value;

                      // EXTRA SAFETY CHECKS
                      final rateText = data["rate_per_session"].toString();
                      final parsedRate = double.tryParse(rateText);
                      if (parsedRate == null) {
                        _showSnack("Invalid rate per class.", true);
                        return;
                      }

                      if (parsedRate < 0) {
                        _showSnack("Rate cannot be negative.", true);
                        return;
                      }

                      final hireDate = data["hire_date"];
                      if (hireDate is! DateTime) {
                        _showSnack("Invalid hire date.", true);
                        return;
                      }

                      final trainer = Trainer(
                        trainerId: widget.trainer?.trainerId,
                        firstName: data["first_name"],
                        lastName: data["last_name"],
                        email: data["email"],
                        phoneNumber: data["phone_number"],
                        hireDate: hireDate,
                        ratePerSession: parsedRate,
                      );

                      final provider =
                          Provider.of<TrainerProvider>(context, listen: false);

                      if (widget.trainer != null) {
                        await provider.updateTrainer(trainer);
                        _showSnack("Trainer updated successfully!");
                      } else {
                        await provider.addTrainer(trainer);
                        _showSnack("Trainer added successfully!");
                      }

                      if (mounted) Navigator.pop(context);

                    } catch (e) {
                      _showSnack("Unexpected error: $e", true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? "Save Changes" : "Add Trainer",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

  // ---------------------- SNACKBAR ----------------------
  void _showSnack(String msg, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
