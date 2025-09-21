// lib/screens/add_sale_screen.dart
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
  String? _selectedProductId; // Moved to state
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
        title: Text(isEditing ? 'Edit Sale' : 'Add New Sale'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          enabled: !customerProvider.isLoading && !productProvider.isLoading,
          child: ListView(
            children: [
              FormBuilderDropdown<String>(
                name: 'customer_id',
                decoration: const InputDecoration(labelText: 'Customer'),
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
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'sale_date',
                decoration: const InputDecoration(labelText: 'Sale Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: (value) => value == null ? 'Sale date cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              // Fixed Add Product Section
              _buildAddProductSection(context, productProvider),
              const SizedBox(height: 16),
              if (_currentSaleItems.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sale Items:', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
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
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text('${product.product.productName} x ${item.quantity}'),
                          subtitle: Text(NumberFormat.currency(symbol: '\$').format(item.unitPrice)),
                          trailing: Text(NumberFormat.currency(symbol: '\$').format(item.quantity * item.unitPrice)),
                          leading: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeSaleItem(itemIndex),
                          ),
                        ),
                      );
                    }).toList(),
                    const Divider(),
                  ],
                ),
              FormBuilderTextField(
                name: 'total_amount',
                decoration: const InputDecoration(labelText: 'Total Amount (\$)', enabled: false),
                initialValue: _totalAmount.toStringAsFixed(2),
                keyboardType: TextInputType.number,
                validator: (value) => _totalAmount <= 0 && _currentSaleItems.isEmpty ? 'Sale cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'payment_method',
                decoration: const InputDecoration(labelText: 'Payment Method'),
                validator: (value) => value == null || value.isEmpty ? 'Payment method cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'Online', child: Text('Online Transfer')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
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

                    if (isEditing) {
                      await Provider.of<SaleProvider>(context, listen: false).updateSale(newSale, finalSaleItems);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sale updated successfully!')),
                      );
                    } else {
                      await Provider.of<SaleProvider>(context, listen: false).addSale(newSale, finalSaleItems);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sale added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  } else if (_currentSaleItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least one product to the sale.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Sale' : 'Add Sale'),
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Products', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            // Fixed DropdownButtonFormField
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Product'),
              value: _selectedProductId, // Use value instead of initialValue
              items: productProvider.products
                  .where((p) => p.product.status == 'Available' && p.product.stockQuantity > 0)
                  .map((p) => DropdownMenuItem(
                        value: p.product.productId,
                        child: Text('${p.product.productName} (Stock: ${p.product.stockQuantity}, \$${p.product.unitPrice.toStringAsFixed(2)})'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity', hintText: '1'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (int.tryParse(value) == null && value.isNotEmpty) {
                         _quantityController.text = '1';
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
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
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}