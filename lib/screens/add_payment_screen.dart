// lib/screens/add_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/models/payment.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/membership_provider.dart'; // To select memberships

class AddPaymentScreen extends StatefulWidget {
  final Payment? payment; // Optional: for editing existing payment

  const AddPaymentScreen({super.key, this.payment});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.payment != null;
    final membershipProvider = Provider.of<MembershipProvider>(context);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'membership_id': widget.payment!.membershipId,
        'amount': widget.payment!.amount.toStringAsFixed(2),
        'method': widget.payment!.method,
        'payment_date': widget.payment!.paymentDate,
        'status': widget.payment!.status,
      };
    } else {
      initialValues = {
        'amount': '0.00',
        'method': 'Cash',
        'payment_date': DateTime.now(),
        'status': 'Completed',
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Payment' : 'Add New Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          enabled: !membershipProvider.isLoading, // Disable form if memberships are loading
          child: ListView(
            children: [
              // Membership Selection
              FormBuilderDropdown<String>(
                name: 'membership_id',
                decoration: const InputDecoration(labelText: 'Associated Membership'),
                validator: (value) => value == null ? 'Please select a membership' : null,
                items: membershipProvider.memberships
                    .map((detailedMembership) => DropdownMenuItem<String>(
                          value: detailedMembership.membership.membershipId,
                          child: Text(
                            '${detailedMembership.customerFirstName} ${detailedMembership.customerLastName} '
                            '(${detailedMembership.planName} - ${detailedMembership.membership.status})',
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Amount
              FormBuilderTextField(
                name: 'amount',
                decoration: const InputDecoration(labelText: 'Amount (\$)', hintText: 'e.g., 50.00'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Amount cannot be empty';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Payment Method
              FormBuilderDropdown<String>(
                name: 'method',
                decoration: const InputDecoration(labelText: 'Payment Method'),
                validator: (value) => value == null || value.isEmpty ? 'Payment method cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Online', child: Text('Online Payment')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
              ),
              const SizedBox(height: 16),
              // Payment Date
              FormBuilderDateTimePicker(
                name: 'payment_date',
                decoration: const InputDecoration(labelText: 'Payment Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Payment date cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              // Status
              FormBuilderDropdown<String>(
                name: 'status',
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) => value == null || value.isEmpty ? 'Status cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Failed', child: Text('Failed')),
                  DropdownMenuItem(value: 'Refunded', child: Text('Refunded')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newPayment = Payment(
                      paymentId: isEditing ? widget.payment!.paymentId : null,
                      membershipId: data['membership_id'],
                      amount: double.parse(data['amount']),
                      method: data['method'],
                      paymentDate: data['payment_date'],
                      status: data['status'],
                    );

                    if (isEditing) {
                      await Provider.of<PaymentProvider>(context, listen: false).updatePayment(newPayment);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment updated successfully!')),
                      );
                    } else {
                      await Provider.of<PaymentProvider>(context, listen: false).addPayment(newPayment);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Payment' : 'Add Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}