// lib/screens/sales_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/screens/add_sale_screen.dart';
import 'package:gym/models/sale.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search sales...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<SaleProvider>(context, listen: false).searchSales(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, saleProvider, child) {
                if (saleProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (saleProvider.sales.isEmpty) {
                  return const Center(child: Text('No sales found.'));
                } else {
                  return ListView.builder(
                    itemCount: saleProvider.sales.length,
                    itemBuilder: (context, index) {
                      final detailedSale = saleProvider.sales[index];
                      final sale = detailedSale.sale;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              DateFormat('dd').format(sale.saleDate),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '${detailedSale.customerFirstName} ${detailedSale.customerLastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date: ${DateFormat('MMM d, yyyy').format(sale.saleDate)}',
                              ),
                              Text(
                                'Items: ${detailedSale.items.map((item) => item.productName).join(', ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('Payment Method: ${sale.paymentMethod ?? 'N/A'}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                NumberFormat.currency(symbol: '\$').format(sale.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  _confirmDelete(context, saleProvider, sale);
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to edit screen, passing the full detailedSale for pre-filling
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddSaleScreen(detailedSale: detailedSale),
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
              builder: (context) => const AddSaleScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SaleProvider saleProvider, Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Sale'),
          content: Text('Are you sure you want to delete this sale from ${DateFormat('MMM d, yyyy').format(sale.saleDate)}? This will also remove all associated sale items.'),
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
                saleProvider.deleteSale(sale.saleId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sale deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}