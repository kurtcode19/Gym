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

  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  final TextEditingController _productSearchController =
      TextEditingController();

  InputDecoration _premiumField(String label, IconData icon,
      {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.detailedSale != null) {
      _currentSaleItems =
          widget.detailedSale!.items.map((e) => e.saleItem).toList();
      _selectedCustomerId = widget.detailedSale!.sale.customerId;
    }

    _calculateTotal();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _productSearchController.dispose();
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

    _formKey.currentState?.fields['total_amount']
        ?.didChange(_totalAmount.toStringAsFixed(2));
  }

  void _removeSaleItem(int index) {
    setState(() {
      _currentSaleItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _addSaleItem(Product selectedProduct, int quantity) {
    if (quantity <= 0) {
      _showError("Quantity must be positive.");
      return;
    }

    if (selectedProduct.stockQuantity < quantity) {
      _showError("Not enough stock. Only ${selectedProduct.stockQuantity} available.");
      return;
    }

    int index = _currentSaleItems.indexWhere(
        (item) => item.productId == selectedProduct.productId);

    if (index != -1) {
      final existing = _currentSaleItems[index];

      if (selectedProduct.stockQuantity < existing.quantity + quantity) {
        _showError("Not enough stock.");
        return;
      }

      setState(() {
        _currentSaleItems[index] =
            existing.copyWith(quantity: existing.quantity + quantity);
      });
    } else {
      _currentSaleItems.add(
        SaleItem(
          saleId: widget.detailedSale?.sale.saleId ?? const Uuid().v4(),
          productId: selectedProduct.productId,
          quantity: quantity,
          unitPrice: selectedProduct.unitPrice,
        ),
      );
    }

    _calculateTotal();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  // ---------------------------------------------------------------------------
  // PRODUCT POPUP
  // ---------------------------------------------------------------------------

  void _openProductPicker(ProductProvider provider) {
    showDialog(
      context: context,
      builder: (popupCtx) => StatefulBuilder(
        builder: (popupCtx, update) {
          final filtered = provider.products.where((p) {
            final keyword = _productSearchController.text.toLowerCase();
            return p.product.status == "Available" &&
                p.product.stockQuantity > 0 &&
                p.product.productName.toLowerCase().contains(keyword);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Choose Product", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _productSearchController,
                  decoration: InputDecoration(
                    hintText: "Search product...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => update(() {}),
                )
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemBuilder: (_, i) {
                  final prod = filtered[i].product;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedProductId = prod.productId);
                      Navigator.pop(context);
                    },
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text("₱${prod.unitPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                            Text("${prod.stockQuantity} in stock",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600))
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN UI (PREMIUM STYLE)
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.detailedSale != null;

    final customerProvider = Provider.of<CustomerProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final initialValues = isEditing
        ? {
            'customer_id': widget.detailedSale!.sale.customerId,
            'sale_date': widget.detailedSale!.sale.saleDate,
            'payment_method': widget.detailedSale!.sale.paymentMethod,
            'total_amount':
                widget.detailedSale!.sale.totalAmount.toStringAsFixed(2)
          }
        : {
            'sale_date': DateTime.now(),
            'payment_method': 'Cash',
            'total_amount': '0.00',
          };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // ---------------- PREMIUM APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 6,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(.08),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isEditing ? "Edit Sale" : "New Sale",
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("Transaction Details"),
              _transactionCard(customerProvider),

              const SizedBox(height: 24),

              _sectionHeader("Add Items"),
              _productPickerCard(productProvider),

              const SizedBox(height: 24),

              _sectionHeader("Order Summary"),
              _summaryCard(productProvider),

              const SizedBox(height: 32),

              _submitButton(isEditing, productProvider),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI SECTIONS (Cards)
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
      ],
    );
  }

  Widget _transactionCard(CustomerProvider provider) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.05),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            FormBuilderDropdown(
              name: 'customer_id',
              decoration: _premiumField("Customer", Icons.person),
              validator: (v) => v == null ? "Required" : null,
              items: provider.customers
                  .map((c) => DropdownMenuItem(
                      value: c.customerId,
                      child: Text("${c.firstName} ${c.lastName}")))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCustomerId = val),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: "sale_date",
                    decoration:
                        _premiumField("Sale Date", Icons.calendar_today),
                    inputType: InputType.date,
                    format: DateFormat("yyyy-MM-dd"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderDropdown(
                    name: "payment_method",
                    decoration:
                        _premiumField("Payment Method", Icons.payment),
                    items: ["Cash", "Credit Card", "Debit Card", "Bank Transfer", "Other"]
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _productPickerCard(ProductProvider provider) {
    final selectedName = _selectedProductId == null
        ? ""
        : provider.products
            .firstWhere((p) => p.product.productId == _selectedProductId!)
            .product
            .productName;

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.05),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _openProductPicker(provider),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(text: selectedName),
                  decoration: _premiumField(
                      "Select Product", Icons.shopping_bag,
                      hint: "Tap to choose a product"),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration:
                        _premiumField("Quantity", Icons.onetwothree),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedProductId == null) {
                      _showError("Select a product first.");
                      return;
                    }

                    final product = provider.products
                        .firstWhere((p) =>
                            p.product.productId == _selectedProductId!)
                        .product;

                    final qty =
                        int.tryParse(_quantityController.text) ?? 1;

                    _addSaleItem(product, qty);

                    setState(() => _selectedProductId = null);
                    _quantityController.text = "1";
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("Add Item"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(ProductProvider provider) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.05),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          if (_currentSaleItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text("Your cart is empty",
                  style: TextStyle(color: Colors.grey)),
            ),
          if (_currentSaleItems.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentSaleItems.length,
              itemBuilder: (_, index) {
                final item = _currentSaleItems[index];
                final prod = provider.products
                    .firstWhere((p) => p.product.productId == item.productId)
                    .product;

                return Column(
                  children: [
                    ListTile(
                      title: Text(prod.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${item.quantity} × ₱${item.unitPrice}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "₱${(item.quantity * item.unitPrice).toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () => _removeSaleItem(index),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(.06),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  "₱${_totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT BUTTON
  // ---------------------------------------------------------------------------

  Widget _submitButton(bool isEditing, ProductProvider productProvider) {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

          if (_currentSaleItems.isEmpty) {
            _showError("Please add at least one product.");
            return;
          }

          final data = _formKey.currentState!.value;

          final saleId = isEditing
              ? widget.detailedSale!.sale.saleId
              : const Uuid().v4();

          final sale = Sale(
            saleId: saleId,
            customerId: data['customer_id'],
            saleDate: data['sale_date'],
            totalAmount: _totalAmount,
            paymentMethod: data['payment_method'],
          );

          final items = _currentSaleItems
              .map((i) => i.copyWith(saleId: saleId))
              .toList();

          try {
            final provider =
                Provider.of<SaleProvider>(context, listen: false);

            if (isEditing) {
              await provider.updateSale(sale, items);
            } else {
              await provider.addSale(sale, items);
            }

            await productProvider.fetchProducts();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Sale saved successfully!")));
              Navigator.pop(context);
            }
          } catch (e) {
            _showError("Error: $e");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          isEditing ? "Update Sale" : "Complete Sale",
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
