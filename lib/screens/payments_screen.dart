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
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search payments...',
                prefixIcon: Icon(Icons.search),
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
                  return const Center(child: Text('No payments found.'));
                } else {
                  return ListView.builder(
                    itemCount: paymentProvider.payments.length,
                    itemBuilder: (context, index) {
                      final detailedPayment = paymentProvider.payments[index];
                      final payment = detailedPayment.payment;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(payment.status),
                            child: Text(
                              payment.status[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${detailedPayment.customerFirstName} ${detailedPayment.customerLastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Method: ${payment.method} • Status: ${payment.status}',
                              ),
                              Text(
                                'Date: ${DateFormat('MMM d, yyyy').format(payment.paymentDate)}',
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                NumberFormat.currency(symbol: '\$').format(payment.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  _confirmDelete(context, paymentProvider, payment);
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPaymentScreen(payment: payment),
                              ),
                            );
                          },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPaymentScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PaymentProvider paymentProvider, Payment payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Payment'),
          content: Text('Are you sure you want to delete this payment of ${NumberFormat.currency(symbol: '\$').format(payment.amount)}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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