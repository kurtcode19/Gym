// lib/screens/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/product.dart';
import 'package:gym/models/product_category.dart';
import 'package:gym/providers/product_provider.dart';
import 'package:gym/providers/product_category_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // Optional: for editing existing product

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final categoryProvider = Provider.of<ProductCategoryProvider>(context, listen: false);

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'product_name': widget.product!.productName,
        'category_id': widget.product!.categoryId,
        'description': widget.product!.description,
        'unit_price': widget.product!.unitPrice.toString(),
        'stock_quantity': widget.product!.stockQuantity.toString(),
        'status': widget.product!.status,
      };
    } else {
      initialValues = {
        'unit_price': '0.00', // Default initial price
        'stock_quantity': '0', // Default initial stock
        'status': 'Available', // Default status for new products
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'product_name',
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Product name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'category_id',
                decoration: const InputDecoration(labelText: 'Category (Optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Uncategorized')),
                  ...categoryProvider.categories
                      .where((cat) => cat.status == 'Active') // Only show active categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category.categoryId,
                            child: Text(category.categoryName),
                          ))
                      .toList(),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'unit_price',
                decoration: const InputDecoration(labelText: 'Unit Price (\$)', hintText: 'e.g., 25.99'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Unit price cannot be empty';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'stock_quantity',
                decoration: const InputDecoration(labelText: 'Stock Quantity', hintText: 'e.g., 100'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Stock quantity cannot be empty';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  if (int.parse(value) < 0) return 'Stock cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'status',
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) => value == null || value.isEmpty ? 'Status cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'Available', child: Text('Available')),
                  DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                  DropdownMenuItem(value: 'Discontinued', child: Text('Discontinued')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newProduct = Product(
                      productId: isEditing ? widget.product!.productId : null,
                      productName: data['product_name'],
                      categoryId: data['category_id'],
                      description: data['description'],
                      unitPrice: double.parse(data['unit_price']),
                      stockQuantity: int.parse(data['stock_quantity']),
                      status: data['status'],
                    );

                    if (isEditing) {
                      await Provider.of<ProductProvider>(context, listen: false).updateProduct(newProduct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newProduct.productName} updated successfully!')),
                      );
                    } else {
                      await Provider.of<ProductProvider>(context, listen: false).addProduct(newProduct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newProduct.productName} added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Product' : 'Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}