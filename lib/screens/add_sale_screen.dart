import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:gym/models/sale.dart';
import 'package:gym/models/sale_item.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/models/product.dart';
import 'package:gym/providers/sale_provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/providers/product_provider.dart';

class AddSaleScreen extends StatefulWidget {
  final DetailedSale? detailedSale;

  const AddSaleScreen({super.key, this.detailedSale});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<SaleItem> _currentSaleItems = [];
  double _totalAmount = 0.0;
  String? _selectedCustomerId;
  String? _selectedProductId;
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    if (widget.detailedSale != null) {
      _currentSaleItems = widget.detailedSale!.items.map((e) => e.saleItem).toList();
      _selectedCustomerId = widget.detailedSale!.sale.customerId;
    }
    _calculateTotal();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _currentSaleItems) {
      total += item.quantity * item.unitPrice;
    }
    setState(() {
      _totalAmount = total;
    });
    _formKey.currentState?.fields['total_amount']?.didChange(_totalAmount.toStringAsFixed(2));
  }

  void _removeSaleItem(int index) {
    setState(() {
      _currentSaleItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _addSaleItem(Product selectedProduct, int quantity) {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be positive.')),
      );
      return;
    }
    if (selectedProduct.stockQuantity < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough stock for ${selectedProduct.productName}. Available: ${selectedProduct.stockQuantity}')),
      );
      return;
    }

    int existingIndex = _currentSaleItems.indexWhere((item) => item.productId == selectedProduct.productId);
    if (existingIndex != -1) {
      SaleItem existingItem = _currentSaleItems[existingIndex];
      if (selectedProduct.stockQuantity < (existingItem.quantity + quantity)) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Adding ${selectedProduct.productName} would exceed available stock.')),
         );
         return;
      }
      setState(() {
        _currentSaleItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + quantity);
      });
    } else {
      setState(() {
        _currentSaleItems.add(SaleItem(
          saleId: widget.detailedSale?.sale.saleId ?? const Uuid().v4(),
          productId: selectedProduct.productId,
          quantity: quantity,
          unitPrice: selectedProduct.unitPrice,
        ));
      });
    }
    _calculateTotal();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.detailedSale != null;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'customer_id': widget.detailedSale!.sale.customerId,
        'sale_date': widget.detailedSale!.sale.saleDate,
        'payment_method': widget.detailedSale!.sale.paymentMethod,
        'total_amount': widget.detailedSale!.sale.totalAmount.toStringAsFixed(2),
      };
    } else {
      initialValues = {
        'sale_date': DateTime.now(),
        'payment_method': 'Cash',
        'total_amount': '0.00',
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Sale' : 'Create New Sale'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          enabled: !customerProvider.isLoading && !productProvider.isLoading,
          child: ListView(
            children: [
              // Customer Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Customer Information', 
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FormBuilderDropdown<String>(
                        name: 'customer_id',
                        decoration: InputDecoration(
                          labelText: 'Select Customer',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        ),
                        validator: (value) => value == null ? 'Please select a customer' : null,
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomerId = val;
                          });
                        },
                        items: customerProvider.customers
                            .map((customer) => DropdownMenuItem<String>(
                                  value: customer.customerId,
                                  child: Text('${customer.firstName} ${customer.lastName} (${customer.email})'),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sale Details
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Sale Details', 
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FormBuilderDateTimePicker(
                        name: 'sale_date',
                        decoration: InputDecoration(
                          labelText: 'Sale Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        ),
                        inputType: InputType.date,
                        format: DateFormat('yyyy-MM-dd'),
                        validator: (value) => value == null ? 'Sale date cannot be empty' : null,
                      ),
                      const SizedBox(height: 12),
                      FormBuilderDropdown<String>(
                        name: 'payment_method',
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        ),
                        items: ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Other']
                            .map((method) => DropdownMenuItem(
                                  value: method,
                                  child: Text(method),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add Products Section
              _buildAddProductSection(context, productProvider),
              const SizedBox(height: 16),

              // Sale Items List
              if (_currentSaleItems.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Sale Items (${_currentSaleItems.length})', 
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._currentSaleItems.asMap().entries.map((entry) {
                          final itemIndex = entry.key;
                          final item = entry.value;
                          final product = productProvider.products.firstWhere(
                            (p) => p.product.productId == item.productId,
                            orElse: () => DetailedProduct(
                              product: Product(
                                productId: '', 
                                productName: 'Unknown Product', 
                                unitPrice: 0, 
                                stockQuantity: 0
                              )
                            )
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.product.productName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color.fromARGB(255, 0, 0, 0)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$').format(item.quantity * item.unitPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _removeSaleItem(itemIndex),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount:',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(symbol: '\$').format(_totalAmount),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    if (_currentSaleItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add at least one product to the sale.')),
                      );
                      return;
                    }

                    final data = _formKey.currentState!.value;
                    final saleId = isEditing ? widget.detailedSale!.sale.saleId : const Uuid().v4();

                    final newSale = Sale(
                      saleId: saleId,
                      customerId: data['customer_id'],
                      saleDate: data['sale_date'],
                      totalAmount: _totalAmount,
                      paymentMethod: data['payment_method'],
                    );

                    final finalSaleItems = _currentSaleItems.map((item) => item.copyWith(saleId: saleId)).toList();

                    try {
                      if (isEditing) {
                        await Provider.of<SaleProvider>(context, listen: false).updateSale(newSale, finalSaleItems);
                        await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sale updated successfully!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        await Provider.of<SaleProvider>(context, listen: false).addSale(newSale, finalSaleItems);
                        await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sale added successfully!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEditing ? Icons.save : Icons.add_shopping_cart),
                    const SizedBox(width: 8),
                    Text(isEditing ? 'Update Sale' : 'Create Sale'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddProductSection(BuildContext context, ProductProvider productProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Add Products', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Product',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              value: _selectedProductId,
              items: productProvider.products
                  .where((p) => p.product.status == 'Available' && p.product.stockQuantity > 0)
                  .map((p) => DropdownMenuItem(
                        value: p.product.productId,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.product.productName),
                            Text(
                              'Stock: ${p.product.stockQuantity} • \$${p.product.unitPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      hintText: '1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (int.tryParse(value) == null && value.isNotEmpty) {
                         _quantityController.text = '1';
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedProductId != null) {
                      final product = productProvider.products
                          .firstWhere((p) => p.product.productId == _selectedProductId)
                          .product;
                      final quantity = int.tryParse(_quantityController.text) ?? 1;
                      _addSaleItem(product, quantity);
                      _quantityController.text = '1';
                      setState(() {
                        _selectedProductId = null;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a product first.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}