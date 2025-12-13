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

    Map<String, dynamic> initialValues = isEditing
        ? {
            'first_name': widget.customer!.firstName,
            'last_name': widget.customer!.lastName,
            'email': widget.customer!.email,
            'phone_number': widget.customer!.phoneNumber,
            'date_joined': widget.customer!.dateJoined,
            'address': widget.customer!.address,
            'emergency_contact_phone': widget.customer!.emergencyContactPhone,
          }
        : {
            'date_joined': DateTime.now(),
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // ----------------------------------------------------------------------
      // PREMIUM APP BAR
      // ----------------------------------------------------------------------
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black), // back button black
        backgroundColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        title: Text(
          isEditing ? "Edit Customer" : "Add New Customer",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteDialog(context),
            ),
        ],
      ),

      // ----------------------------------------------------------------------
      // BODY
      // ----------------------------------------------------------------------
      body: Column(
        children: [
          // ------------------------------------------------------------------
          // PREMIUM HEADER PANEL
          // ------------------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEEF4FF),
                  Color(0xFFE9F5FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child:
                      const Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 14),
                Text(
                  isEditing
                      ? "Update Customer Information"
                      : "Create New Customer",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? "Modify details and save changes"
                      : "Fill in the details to register a new member",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // FORM SECTION
          // ------------------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FormBuilder(
                  key: _formKey,
                  initialValue: initialValues,
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(22),
                      children: [
                        _sectionHeader("Personal Information"),

                        const SizedBox(height: 16),
                        _textField(
                          name: "first_name",
                          label: "First Name",
                          icon: Icons.person_outline,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),

                        _textField(
                          name: "last_name",
                          label: "Last Name",
                          icon: Icons.person_outline,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),

                        _textField(
                          name: "email",
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),

                        _textField(
                          name: "phone_number",
                          label: "Phone Number",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 30),
                        _sectionHeader("Additional Information"),
                        const SizedBox(height: 16),

                        _datePicker(),

                        const SizedBox(height: 16),
                        _textField(
                          name: "address",
                          label: "Address",
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        _textField(
                          name: "emergency_contact_phone",
                          label: "Emergency Contact Phone",
                          icon: Icons.emergency_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 36),
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
        ),
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
    int maxLines = 1,
  }) {
    return FormBuilderTextField(
      name: name,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return "$label is required";
              }
              if (name == 'email' &&
                  !RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(value)) {
                return "Enter a valid email";
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PREMIUM DATE PICKER
  // --------------------------------------------------------------------------
  Widget _datePicker() {
    return FormBuilderDateTimePicker(
      name: 'date_joined',
      inputType: InputType.date,
      format: DateFormat("yyyy-MM-dd"),
      validator: (val) => val == null ? "Required" : null,
      decoration: InputDecoration(
        labelText: "Date Joined",
        prefixIcon:
            Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600),
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
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
      ),
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
            final provider =
                Provider.of<CustomerProvider>(context, listen: false);

            if (isEditing) {
              await provider.updateCustomer(newCustomer);
              _success("Customer updated successfully!");
            } else {
              await provider.addCustomer(newCustomer);
              _success("Customer added successfully!");
            }

            Navigator.pop(context);
          } catch (e) {
            _error("Failed to save customer: $e");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isEditing ? Icons.save : Icons.person_add, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isEditing ? "Update Customer" : "Add Customer",
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Delete Customer"),
          ],
        ),
        content: Text(
            "Are you sure you want to delete ${widget.customer!.firstName} ${widget.customer!.lastName}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Provider.of<CustomerProvider>(context, listen: false)
                  .deleteCustomer(widget.customer!.customerId);

              Navigator.pop(context);
              Navigator.pop(context);
              _success("Customer deleted successfully!");
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SNACKBARS
  // --------------------------------------------------------------------------
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
