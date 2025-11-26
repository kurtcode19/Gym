// lib/screens/add_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:gym/models/payment.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/providers/membership_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final Payment? payment; 
  final String? preSelectedMembershipId;

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

  InputDecoration _fieldDecoration(String label, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedMembershipId = widget.preSelectedMembershipId;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.payment != null) {
        _loadMembershipDetails(widget.payment!.membershipId, context);
      } else if (widget.preSelectedMembershipId != null) {
        // If coming from membership details screen, load that fee immediately
        _loadMembershipDetails(widget.preSelectedMembershipId!, context);
      }
    });
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
      
      // If adding new payment (not editing), auto-fill amount
      if (widget.payment == null && widget.preSelectedMembershipId != null) {
         _formKey.currentState?.fields['amount']?.didChange(_planMonthlyFee.toStringAsFixed(2));
      }
    } catch (e) {
      debugPrint('Error loading membership details: $e');
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
        debugPrint('Error loading membership: $e');
      }
    }
  }

  List<DetailedMembership> _getActiveMemberships(MembershipProvider membershipProvider) {
    return membershipProvider.memberships.where((dm) {
      final status = dm.membership.status.toLowerCase();
      // Allow payment for Pending/Active, maybe Cancelled if paying off debt
      return status != 'expired'; 
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Record' : 'New Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: FormBuilder(
                key: _formKey,
                initialValue: initialValues,
                enabled: !membershipProvider.isLoading && !_isSubmitting,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Membership Link"),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            FormBuilderDropdown<String>(
                              name: 'membership_id',
                              decoration: _fieldDecoration('Select Membership', Icons.card_membership),
                              validator: (value) => value == null ? 'Required' : null,
                              items: activeMemberships
                                  .map((detailedMembership) => DropdownMenuItem<String>(
                                        value: detailedMembership.membership.membershipId,
                                        child: Text(
                                          '${detailedMembership.customerFirstName} ${detailedMembership.customerLastName} - \$${detailedMembership.planMonthlyFee}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) => _onMembershipChanged(value, context),
                            ),
                            if (_selectedMembershipId != null && !isEditing)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Standard Fee: \$${_planMonthlyFee.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Transaction Details"),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'amount',
                                    decoration: _fieldDecoration('Amount', Icons.attach_money, hintText: '0.00'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Required';
                                      if (double.tryParse(value) == null) return 'Invalid #';
                                      if (double.parse(value) <= 0) return 'Must be > 0';
                                      return null;
                                    },
                                  ),
                                ),
                                if (_selectedMembershipId != null && !isEditing)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.auto_fix_high, color: Colors.blue),
                                      tooltip: 'Set to Plan Fee',
                                      onPressed: () {
                                        _formKey.currentState?.fields['amount']?.didChange(_planMonthlyFee.toStringAsFixed(2));
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FormBuilderDropdown<String>(
                              name: 'method',
                              decoration: _fieldDecoration('Method', Icons.payment),
                              validator: (value) => value == null ? 'Required' : null,
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'Card', child: Text('Credit/Debit Card')),
                                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                                DropdownMenuItem(value: 'Online', child: Text('Online Payment')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FormBuilderDateTimePicker(
                              name: 'payment_date',
                              decoration: _fieldDecoration('Date', Icons.calendar_today),
                              inputType: InputType.date,
                              format: DateFormat('yyyy-MM-dd'),
                              validator: (value) => value == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            FormBuilderDropdown<String>(
                              name: 'status',
                              decoration: _fieldDecoration('Status', Icons.rule),
                              validator: (value) => value == null ? 'Required' : null,
                              items: const [
                                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'Failed', child: Text('Failed')),
                                DropdownMenuItem(value: 'Refunded', child: Text('Refunded')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Helper Info
                    if (!isEditing) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Marking as "Completed" will automatically update the membership status to Active.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () async {
                          if (_formKey.currentState?.saveAndValidate() ?? false) {
                            setState(() => _isSubmitting = true);
                            
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
                                if (mounted) _showSnackBar('Payment updated!', isError: false);
                              } else {
                                await Provider.of<PaymentProvider>(context, listen: false).addPayment(paymentToSave);
                                if (mounted) _showSnackBar('Payment recorded successfully!', isError: false);
                              }
                              if (mounted) Navigator.of(context).pop();
                            } catch (e) {
                              if (mounted) _showSnackBar('Error: $e', isError: true);
                            } finally {
                              if (mounted) setState(() => _isSubmitting = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Update Payment' : 'Confirm Payment',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
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
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}