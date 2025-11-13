// lib/screens/add_payment_screen.dart - UPDATED CONTENT
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/models/payment.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/membership_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final Payment? payment; // Optional: for editing existing payment
  final String? preSelectedMembershipId; // Optional: pre-select a membership

  const AddPaymentScreen({
    super.key, 
    this.payment,
    this.preSelectedMembershipId
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _selectedMembershipId;
  double _planMonthlyFee = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMembershipId = widget.preSelectedMembershipId;
    
    // Pre-fill amount if editing
    if (widget.payment != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMembershipDetails(widget.payment!.membershipId, context);
      });
    }
  }

  void _loadMembershipDetails(String membershipId, BuildContext context) {
    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    try {
      final selectedMembership = membershipProvider.memberships.firstWhere(
        (dm) => dm.membership.membershipId == membershipId,
      );
      setState(() {
        _planMonthlyFee = selectedMembership.planMonthlyFee;
      });
    } catch (e) {
      print('Error loading membership details: $e');
    }
  }

  void _onMembershipChanged(String? membershipId, BuildContext context) {
    if (membershipId != null) {
      setState(() {
        _selectedMembershipId = membershipId;
      });
      
      // Auto-fill the amount based on the selected membership's plan
      final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
      try {
        final selectedMembership = membershipProvider.memberships.firstWhere(
          (dm) => dm.membership.membershipId == membershipId,
        );
        
        final monthlyFee = selectedMembership.planMonthlyFee;
        setState(() {
          _planMonthlyFee = monthlyFee;
        });
        
        // Update the form field with the monthly fee
        _formKey.currentState?.fields['amount']?.didChange(monthlyFee.toStringAsFixed(2));
      } catch (e) {
        print('Error loading membership: $e');
      }
    }
  }

  // Helper method to get active memberships (not expired/cancelled)
  List<DetailedMembership> _getActiveMemberships(MembershipProvider membershipProvider) {
    return membershipProvider.memberships.where((dm) {
      final status = dm.membership.status.toLowerCase();
      return status != 'expired' && status != 'cancelled';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.payment != null;
    final membershipProvider = Provider.of<MembershipProvider>(context);
    final activeMemberships = _getActiveMemberships(membershipProvider);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'membership_id': widget.payment!.membershipId,
        'amount': widget.payment!.amount.toStringAsFixed(2),
        'method': widget.payment!.method,
        'payment_date': widget.payment!.paymentDate,
        'status': widget.payment!.status,
      };
      _selectedMembershipId = widget.payment!.membershipId;
    } else {
      initialValues = {
        'membership_id': _selectedMembershipId,
        'amount': '0.00',
        'method': 'Cash',
        'payment_date': DateTime.now(),
        'status': 'Completed',
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Payment' : 'Add New Payment'),
        actions: [
          if (_selectedMembershipId != null && !isEditing)
            IconButton(
              icon: const Icon(Icons.attach_money),
              tooltip: 'Use Plan Monthly Fee',
              onPressed: () {
                _formKey.currentState?.fields['amount']?.didChange(_planMonthlyFee.toStringAsFixed(2));
              },
            ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: FormBuilder(
                key: _formKey,
                initialValue: initialValues,
                enabled: !membershipProvider.isLoading && !_isSubmitting,
                child: ListView(
                  children: [
                    // Membership Selection
                    FormBuilderDropdown<String>(
                      name: 'membership_id',
                      decoration: InputDecoration(
                        labelText: 'Associated Membership',
                        hintText: 'Select a membership',
                        suffixIcon: membershipProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                      validator: (value) => value == null ? 'Please select a membership' : null,
                      items: activeMemberships
                          .map((detailedMembership) => DropdownMenuItem<String>(
                                value: detailedMembership.membership.membershipId,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${detailedMembership.customerFirstName} ${detailedMembership.customerLastName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${detailedMembership.planName} - \$${detailedMembership.planMonthlyFee}/month',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Status: ${detailedMembership.membership.status}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getStatusColor(detailedMembership.membership.status),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => _onMembershipChanged(value, context),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Amount Field with Auto-fill Button
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'amount',
                            decoration: const InputDecoration(
                              labelText: 'Amount (\$)',
                              hintText: 'e.g., 50.00',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Amount cannot be empty';
                              if (double.tryParse(value) == null) return 'Invalid number';
                              if (double.parse(value) <= 0) return 'Amount must be positive';
                              return null;
                            },
                          ),
                        ),
                        if (_selectedMembershipId != null && !isEditing)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 16.0),
                            child: IconButton(
                              icon: const Icon(Icons.auto_awesome, color: Colors.blue),
                              tooltip: 'Auto-fill with monthly fee',
                              onPressed: () {
                                _formKey.currentState?.fields['amount']?.didChange(_planMonthlyFee.toStringAsFixed(2));
                              },
                            ),
                          ),
                      ],
                    ),
                    
                    if (_selectedMembershipId != null && !isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Plan monthly fee: \$$_planMonthlyFee',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
                    
                    // Status with helpful information
                    FormBuilderDropdown<String>(
                      name: 'status',
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        hintText: 'Select payment status',
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Status cannot be empty' : null,
                      items: const [
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Completed - Will activate membership'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Row(
                            children: [
                              Icon(Icons.pending, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text('Pending'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Failed',
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Failed - Will set membership to pending'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Refunded',
                          child: Row(
                            children: [
                              Icon(Icons.undo, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Refunded - Will set membership to pending'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (!isEditing) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Completed payments will automatically activate the membership',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        if (_formKey.currentState?.saveAndValidate() ?? false) {
                          setState(() {
                            _isSubmitting = true;
                          });
                          
                          final data = _formKey.currentState!.value;
                          final paymentToSave = Payment(
                            paymentId: isEditing ? widget.payment!.paymentId : null,
                            membershipId: data['membership_id'],
                            amount: double.parse(data['amount']),
                            method: data['method'],
                            paymentDate: data['payment_date'],
                            status: data['status'],
                          );

                          try {
                            if (isEditing) {
                              await Provider.of<PaymentProvider>(context, listen: false).updatePayment(paymentToSave);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Payment updated successfully!')),
                              );
                            } else {
                              await Provider.of<PaymentProvider>(context, listen: false).addPayment(paymentToSave);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Payment added successfully!')),
                              );
                            }
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving payment: $e')),
                            );
                          } finally {
                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Update Payment' : 'Add Payment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}