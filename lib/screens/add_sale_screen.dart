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
  String? _selectedProductId;
  final TextEditingController _quantityController = TextEditingController(text: '1');

  // --- UI Helpers ---
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
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be positive.')));
      return;
    }
    if (selectedProduct.stockQuantity < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough stock. Available: ${selectedProduct.stockQuantity}')));
      return;
    }

    int existingIndex = _currentSaleItems.indexWhere((item) => item.productId == selectedProduct.productId);
    if (existingIndex != -1) {
      SaleItem existingItem = _currentSaleItems[existingIndex];
      if (selectedProduct.stockQuantity < (existingItem.quantity + quantity)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exceeds available stock.')));
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

  void _showAddCustomerModal(BuildContext context) {
    final customerFormKey = GlobalKey<FormBuilderState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Customer'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: FormBuilder(
            key: customerFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(name: 'first_name', decoration: _fieldDecoration('First Name', Icons.person), validator: (val) => val == null || val.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'last_name', decoration: _fieldDecoration('Last Name', Icons.person_outline), validator: (val) => val == null || val.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'email', 
                  decoration: _fieldDecoration('Email', Icons.email), 
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!val.contains('@')) return 'Invalid email';
                    return null;
                  }
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'phone', decoration: _fieldDecoration('Phone', Icons.phone), keyboardType: TextInputType.phone),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (customerFormKey.currentState?.saveAndValidate() ?? false) {
                final data = customerFormKey.currentState!.value;
                final newId = const Uuid().v4();
                final newCustomer = Customer(
                  customerId: newId,
                  firstName: data['first_name'],
                  lastName: data['last_name'],
                  email: data['email'],

                );

                try {
                  await Provider.of<CustomerProvider>(context, listen: false).addCustomer(newCustomer);
                  setState(() => _selectedCustomerId = newId);
                  _formKey.currentState?.fields['customer_id']?.didChange(newId);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Sale' : 'New Sale'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          enabled: !customerProvider.isLoading && !productProvider.isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Transaction Details
              _buildSectionHeader('Transaction Details'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderDropdown<String>(
                              name: 'customer_id',
                              decoration: _fieldDecoration('Customer', Icons.person),
                              validator: (value) => value == null ? 'Required' : null,
                              onChanged: (val) => setState(() => _selectedCustomerId = val),
                              items: customerProvider.customers
                                  .map((c) => DropdownMenuItem(value: c.customerId, child: Text('${c.firstName} ${c.lastName}')))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                            child: IconButton(
                              icon: const Icon(Icons.person_add, color: Colors.blue),
                              tooltip: 'New Customer',
                              onPressed: () => _showAddCustomerModal(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderDateTimePicker(
                              name: 'sale_date',
                              decoration: _fieldDecoration('Date', Icons.calendar_today),
                              inputType: InputType.date,
                              format: DateFormat('yyyy-MM-dd'),
                              validator: (value) => value == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FormBuilderDropdown<String>(
                              name: 'payment_method',
                              decoration: _fieldDecoration('Method', Icons.payment),
                              items: ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Other']
                                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Add Products
              _buildSectionHeader('Add Items'),
              _buildAddProductSection(context, productProvider),

              const SizedBox(height: 24),

              // 3. Shopping Cart List
              _buildSectionHeader('Order Summary'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    if (_currentSaleItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Center(child: Text("Cart is empty", style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _currentSaleItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _currentSaleItems[index];
                          final product = productProvider.products.firstWhere(
                            (p) => p.product.productId == item.productId,
                            orElse: () => DetailedProduct(product: Product(productId: '', productName: 'Unknown', unitPrice: 0, stockQuantity: 0))
                          ).product;
                          
                          return ListTile(
                            title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  NumberFormat.currency(symbol: '\$').format(item.quantity * item.unitPrice),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300),
                                  onPressed: () => _removeSaleItem(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    // Total Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            NumberFormat.currency(symbol: '\$').format(_totalAmount),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      if (_currentSaleItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add items to cart.')));
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
                        } else {
                          await Provider.of<SaleProvider>(context, listen: false).addSale(newSale, finalSaleItems);
                        }
                        // Refresh products to update stock
                        if (mounted) {
                          await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale saved successfully!')));
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: Text(isEditing ? 'Update Sale' : 'Complete Sale', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: _fieldDecoration('Select Product', Icons.inventory_2),
              value: _selectedProductId,
              isExpanded: true,
              items: productProvider.products
                  .where((p) => p.product.status == 'Available' && p.product.stockQuantity > 0)
                  .map((p) => DropdownMenuItem(
                        value: p.product.productId,
                        child: Text(
                          '${p.product.productName} (\$${p.product.unitPrice}) - ${p.product.stockQuantity} in stock',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedProductId = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: _fieldDecoration('Quantity', Icons.onetwothree),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (int.tryParse(value) == null && value.isNotEmpty) _quantityController.text = '1';
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
                      setState(() => _selectedProductId = null);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product first.')));
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }
}