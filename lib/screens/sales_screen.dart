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
        title: const Text('Sales History'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search sales by customer or product...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (query) {
                Provider.of<SaleProvider>(context, listen: false).searchSales(query);
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Stats Overview
          Consumer<SaleProvider>(
            builder: (context, saleProvider, child) {
              final totalSales = saleProvider.sales.length;
              final totalRevenue = saleProvider.sales.fold<double>(
                0, (sum, sale) => sum + sale.sale.totalAmount
              );
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard(
                      context,
                      'Total Sales',
                      totalSales.toString(),
                      Icons.receipt,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context,
                      'Revenue',
                      NumberFormat.currency(symbol: '\P').format(totalRevenue),
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Sales List
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, saleProvider, child) {
                if (saleProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading sales...'),
                      ],
                    ),
                  );
                } else if (saleProvider.sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sales found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first sale to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: saleProvider.sales.length,
                    itemBuilder: (context, index) {
                      final detailedSale = saleProvider.sales[index];
                      final sale = detailedSale.sale;
                      return _buildSaleCard(context, detailedSale, saleProvider, sale);
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
              builder: (context) => const AddSaleScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, DetailedSale detailedSale, SaleProvider saleProvider, Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSaleScreen(detailedSale: detailedSale),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(sale.saleDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(sale.saleDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Sale Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detailedSale.customerFirstName} ${detailedSale.customerLastName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detailedSale.items.map((item) => item.productName).join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sale.paymentMethod ?? 'N/A',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Amount and Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(symbol: '\P').format(sale.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddSaleScreen(detailedSale: detailedSale),
                            ),
                          );
                        },
                        tooltip: 'Edit Sale',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                        onPressed: () {
                          _confirmDelete(context, saleProvider, sale);
                        },
                        tooltip: 'Delete Sale',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SaleProvider saleProvider, Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Delete Sale'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this sale from ${DateFormat('MMM d, yyyy').format(sale.saleDate)}? This will also remove all associated sale items.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
              onPressed: () {
                saleProvider.deleteSale(sale.saleId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sale deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}