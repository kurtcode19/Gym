// lib/screens/add_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:intl/intl.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    final theme = Theme.of(context);

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
        'date_joined': DateTime.now(),
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
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
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEditing ? 'Update Customer Information' : 'Create New Customer',
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
                          _buildSectionHeader('Personal Information'),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'first_name',
                            label: 'First Name',
                            icon: Icons.person_outline,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'last_name',
                            label: 'Last Name',
                            icon: Icons.person_outline,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'email',
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'phone_number',
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Additional Information'),
                          const SizedBox(height: 16),
                          _buildDatePicker(context),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'address',
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            name: 'emergency_contact_phone',
                            label: 'Emergency Contact Phone',
                            icon: Icons.emergency_outlined,
                            keyboardType: TextInputType.phone,
                          ),
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
    int maxLines = 1,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
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
      maxLines: maxLines,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) return '$label is required';
              if (name == 'email' && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return FormBuilderDateTimePicker(
      name: 'date_joined',
      decoration: InputDecoration(
        labelText: 'Date Joined',
        prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
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
      inputType: InputType.date,
      format: DateFormat('yyyy-MM-dd'),
      validator: (value) => value == null ? 'Date joined is required' : null,
    );
  }

  Widget _buildSubmitButton(bool isEditing, BuildContext context) {
    return ElevatedButton(
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

          try {
            if (isEditing) {
              await Provider.of<CustomerProvider>(context, listen: false).updateCustomer(newCustomer);
              _showSuccessSnackbar(context, '${newCustomer.firstName} updated successfully!');
            } else {
              await Provider.of<CustomerProvider>(context, listen: false).addCustomer(newCustomer);
              _showSuccessSnackbar(context, '${newCustomer.firstName} added successfully!');
            }
            Navigator.of(context).pop();
          } catch (e) {
            _showErrorSnackbar(context, 'Failed to save customer: $e');
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
          Icon(isEditing ? Icons.save : Icons.person_add),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'Update Customer' : 'Add Customer',
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
              Text('Delete Customer'),
            ],
          ),
          content: Text('Are you sure you want to delete ${widget.customer!.firstName} ${widget.customer!.lastName}?'),
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
                Provider.of<CustomerProvider>(context, listen: false)
                    .deleteCustomer(widget.customer!.customerId);
                Navigator.of(context)
                  ..pop()
                  ..pop();
                _showSuccessSnackbar(context, 'Customer deleted successfully!');
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