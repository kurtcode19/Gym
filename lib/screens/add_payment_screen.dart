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
    this.preSelectedMembershipId,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _selectedMembershipId;
  double _planMonthlyFee = 0.0;
  bool _isSubmitting = false;

  InputDecoration _fieldDecoration(String label, IconData icon,
      {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
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
        _loadMembershipDetails(widget.preSelectedMembershipId!, context);
      }
    });
  }

  void _loadMembershipDetails(String membershipId, BuildContext context) {
    final membershipProvider =
        Provider.of<MembershipProvider>(context, listen: false);

    try {
      final selectedMembership = membershipProvider.memberships.firstWhere(
        (dm) => dm.membership.membershipId == membershipId,
      );

      setState(() {
        _planMonthlyFee = selectedMembership.planMonthlyFee;
      });

      if (widget.payment == null) {
        _formKey.currentState?.fields['amount']
            ?.didChange(_planMonthlyFee.toStringAsFixed(2));
      }
    } catch (_) {}
  }

  void _onMembershipChanged(String? membershipId, BuildContext context) {
    if (membershipId == null) return;

    setState(() => _selectedMembershipId = membershipId);

    final membershipProvider =
        Provider.of<MembershipProvider>(context, listen: false);

    try {
      final selectedMembership = membershipProvider.memberships.firstWhere(
        (dm) => dm.membership.membershipId == membershipId,
      );

      setState(() {
        _planMonthlyFee = selectedMembership.planMonthlyFee;
      });

      _formKey.currentState?.fields['amount']
          ?.didChange(_planMonthlyFee.toStringAsFixed(2));
    } catch (_) {}
  }

  List<DetailedMembership> _getActiveMemberships(
      MembershipProvider membershipProvider) {
    return membershipProvider.memberships
        .where((dm) => dm.membership.status.toLowerCase() != "expired")
        .toList();
  }

  // ---------------------------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.payment != null;
    final membershipProvider = Provider.of<MembershipProvider>(context);
    final activeMemberships = _getActiveMemberships(membershipProvider);

    final initialValues = isEditing
        ? {
            'membership_id': widget.payment!.membershipId,
            'amount': widget.payment!.amount.toStringAsFixed(2),
            'method': widget.payment!.method,
            'payment_date': widget.payment!.paymentDate,
            'status': widget.payment!.status,
          }
        : {
            'membership_id': _selectedMembershipId,
            'amount': '0.00',
            'method': 'Cash',
            'payment_date': DateTime.now(),
            'status': 'Completed',
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // ----------------------------------------------------------------------
      // PREMIUM APP BAR
      // ----------------------------------------------------------------------
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(.12),
        centerTitle: true,
        title: Text(
          isEditing ? "Edit Payment" : "Record Payment",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
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
                    _sectionHeader("Membership Link"),

                    // ===================== MEMBERSHIP CARD =====================
                    Card(
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(.05),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            FormBuilderDropdown<String>(
                              name: 'membership_id',
                              decoration: _fieldDecoration(
                                'Select Membership',
                                Icons.card_membership,
                              ),
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                              items: activeMemberships
                                  .map(
                                    (dm) => DropdownMenuItem(
                                      value: dm.membership.membershipId,
                                      child: Text(
                                        "${dm.customerFirstName} ${dm.customerLastName} • ₱${dm.planMonthlyFee}",
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  _onMembershipChanged(value, context),
                            ),

                            if (_selectedMembershipId != null && !isEditing)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        size: 16, color: Colors.blueAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Monthly Fee: ₱${_planMonthlyFee.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    _sectionHeader("Transaction Details"),

                    // ===================== DETAILS CARD =====================
                    Card(
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(.05),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'amount',
                                    decoration: _fieldDecoration(
                                        "Amount", Icons.attach_money),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return "Required";
                                      }
                                      if (double.tryParse(v) == null) {
                                        return "Invalid number";
                                      }
                                      if (double.parse(v) <= 0) {
                                        return "Must be greater than 0";
                                      }
                                      return null;
                                    },
                                  ),
                                ),

                                // Autofill button
                                if (_selectedMembershipId != null &&
                                    !isEditing)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: IconButton(
                                      onPressed: () {
                                        _formKey
                                            .currentState
                                            ?.fields['amount']
                                            ?.didChange(_planMonthlyFee
                                                .toStringAsFixed(2));
                                      },
                                      icon: const Icon(Icons.auto_fix_high),
                                      color: Colors.blueAccent,
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueAccent.withOpacity(.12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            FormBuilderDropdown<String>(
                              name: 'method',
                              decoration:
                                  _fieldDecoration('Payment Method', Icons.payment),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(
                                    value: 'Card',
                                    child: Text('Credit/Debit Card')),
                                DropdownMenuItem(
                                    value: 'Bank Transfer',
                                    child: Text('Bank Transfer')),
                                DropdownMenuItem(
                                    value: 'Online',
                                    child: Text('Online Payment')),
                                DropdownMenuItem(
                                    value: 'Other', child: Text('Other')),
                              ],
                            ),

                            const SizedBox(height: 16),

                            FormBuilderDateTimePicker(
                              name: 'payment_date',
                              decoration: _fieldDecoration(
                                  "Payment Date", Icons.calendar_today),
                              inputType: InputType.date,
                              format: DateFormat("yyyy-MM-dd"),
                            ),

                            const SizedBox(height: 16),

                            FormBuilderDropdown<String>(
                              name: 'status',
                              decoration: _fieldDecoration(
                                  'Status', Icons.flag_circle_rounded),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Completed',
                                    child: Text('Completed')),
                                DropdownMenuItem(
                                    value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(
                                    value: 'Failed', child: Text('Failed')),
                                DropdownMenuItem(
                                    value: 'Refunded',
                                    child: Text('Refunded')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!isEditing) ...[
                      const SizedBox(height: 14),
                      _infoNote(
                        "Marking as Completed will update the membership status to Active.",
                      ),
                    ],

                    const SizedBox(height: 34),

                    // ===================== SUBMIT BUTTON =====================
                    SizedBox(
                      height: 55,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_formKey.currentState
                                        ?.saveAndValidate() ??
                                    false) {
                                  setState(() => _isSubmitting = true);

                                  final data =
                                      _formKey.currentState!.value;

                                  final paymentToSave = Payment(
                                    paymentId: isEditing
                                        ? widget.payment!.paymentId
                                        : null,
                                    membershipId: data['membership_id'],
                                    amount: double.parse(data['amount']),
                                    method: data['method'],
                                    paymentDate: data['payment_date'],
                                    status: data['status'],
                                  );

                                  try {
                                    final provider =
                                        Provider.of<PaymentProvider>(
                                            context,
                                            listen: false);

                                    if (isEditing) {
                                      await provider.updatePayment(
                                          paymentToSave);
                                      _showSnackBar("Payment updated!");
                                    } else {
                                      await provider.addPayment(
                                          paymentToSave);
                                      _showSnackBar(
                                          "Payment recorded successfully!");
                                    }

                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    _showSnackBar("Error: $e",
                                        isError: true);
                                  } finally {
                                    if (mounted) {
                                      setState(() =>
                                          _isSubmitting = false);
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing
                                    ? "Update Payment"
                                    : "Confirm Payment",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HEADER
  // ---------------------------------------------------------------------------
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INFO NOTE
  // ---------------------------------------------------------------------------
  Widget _infoNote(String msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline,
            size: 18, color: Colors.amber.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
