// lib/screens/add_product_category_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/product_category.dart';
import 'package:gym/providers/product_category_provider.dart';

class AddProductCategoryScreen extends StatefulWidget {
  final ProductCategory? category; // Optional: for editing existing category

  const AddProductCategoryScreen({super.key, this.category});

  @override
  State<AddProductCategoryScreen> createState() => _AddProductCategoryScreenState();
}

class _AddProductCategoryScreenState extends State<AddProductCategoryScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    Map<String, dynamic> initialValues = {};
    if (isEditing) {
      initialValues = {
        'category_name': widget.category!.categoryName,
        'description': widget.category!.description,
        'status': widget.category!.status,
      };
    } else {
      initialValues = {
        'status': 'Active', // Default status for new categories
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product Category' : 'Add Product Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'category_name',
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (value) => value == null || value.isEmpty ? 'Category name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'status',
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) => value == null || value.isEmpty ? 'Status cannot be empty' : null,
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final data = _formKey.currentState!.value;
                    final newCategory = ProductCategory(
                      categoryId: isEditing ? widget.category!.categoryId : null,
                      categoryName: data['category_name'],
                      description: data['description'],
                      status: data['status'],
                    );

                    if (isEditing) {
                      await Provider.of<ProductCategoryProvider>(context, listen: false).updateProductCategory(newCategory);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newCategory.categoryName} updated successfully!')),
                      );
                    } else {
                      await Provider.of<ProductCategoryProvider>(context, listen: false).addProductCategory(newCategory);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${newCategory.categoryName} added successfully!')),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Category' : 'Add Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}