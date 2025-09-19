// lib/screens/add_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:intl/intl.dart'; // For date formatting if needed, though FormBuilderDateTimePicker handles it.

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer; // Optional: for editing existing customer

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    // Initial values for the form when editing
    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'first_name': widget.customer!.firstName,
        'last_name': widget.customer!.lastName,
        'email': widget.customer!.email,
        'phone_number': widget.customer!.phoneNumber,
        'date_joined': widget.customer!.dateJoined,
        'address': widget.customer!.address,
        'emergency_contact_phone': widget.customer!.emergencyContactPhone,
      };
    } else {
      initialValues = {
        'date_joined': DateTime.now(), // Default for new customers
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'first_name',
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.isEmpty ? 'First name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'last_name',
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.isEmpty ? 'Last name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'email',
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email cannot be empty';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'phone_number',
                decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'date_joined',
                decoration: const InputDecoration(labelText: 'Date Joined'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Date joined cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'address',
                decoration: const InputDecoration(labelText: 'Address (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'emergency_contact_phone',
                decoration: const InputDecoration(labelText: 'Emergency Contact Phone (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newCustomer = Customer(
                      customerId: isEditing ? widget.customer!.customerId : null,
                      firstName: data['first_name'],
                      lastName: data['last_name'],
                      email: data['email'],
                      phoneNumber: data['phone_number'],
                      dateJoined: data['date_joined'],
                      address: data['address'],
                      emergencyContactPhone: data['emergency_contact_phone'],
                    );

                    if (isEditing) {
                      await Provider.of<CustomerProvider>(context, listen: false).updateCustomer(newCustomer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newCustomer.firstName} updated successfully!')),
                      );
                    } else {
                      await Provider.of<CustomerProvider>(context, listen: false).addCustomer(newCustomer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newCustomer.firstName} added successfully!')),
                      );
                    }
                    Navigator.of(context).pop(); // Go back to previous screen
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Customer' : 'Add Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}