// lib/screens/payments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/payment_provider.dart';
import 'package:gym/models/payment.dart';
import 'package:gym/screens/add_payment_screen.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'failed': return Colors.red;
      case 'refunded': return Colors.orange;
      case 'pending': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash': return Icons.payments_outlined;
      case 'credit card': return Icons.credit_card;
      case 'debit card': return Icons.credit_card_outlined;
      case 'bank transfer': return Icons.account_balance;
      case 'check': return Icons.fact_check_outlined;
      default: return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payments History', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by name or amount...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                Provider.of<PaymentProvider>(context, listen: false).searchPayments(query);
              },
            ),
          ),

          Expanded(
            child: Consumer<PaymentProvider>(
              builder: (context, paymentProvider, child) {
                if (paymentProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (paymentProvider.payments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No payment records found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: paymentProvider.payments.length,
                    itemBuilder: (context, index) {
                      final detailedPayment = paymentProvider.payments[index];
                      final payment = detailedPayment.payment;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPaymentScreen(payment: payment),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Method Icon
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(payment.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getMethodIcon(payment.method),
                                    color: _getStatusColor(payment.status),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${detailedPayment.customerFirstName} ${detailedPayment.customerLastName}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy • h:mm a').format(payment.paymentDate),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Via ${payment.method ?? "Unknown"}',
                                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),

                                // Amount & Status
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.currency(symbol: '\$').format(payment.amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(payment.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        payment.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(payment.status),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Subtle Delete Button
                                    InkWell(
                                      onTap: () => _confirmDelete(context, paymentProvider, payment),
                                      child: Icon(Icons.delete_outline, size: 18, color: Colors.grey[400]),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPaymentScreen(),
            ),
          );
        },
        label: const Text("Receive Payment"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _confirmDelete(BuildContext context, PaymentProvider paymentProvider, Payment payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Payment?'),
          content: Text('Are you sure you want to delete this payment of ${NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(payment.amount)}?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                paymentProvider.deletePayment(payment.paymentId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}