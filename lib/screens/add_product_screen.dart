import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:gym/models/product.dart';
import 'package:gym/providers/product_provider.dart';
import 'package:gym/providers/product_category_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // For editing
  final String? initialCategoryId;

  const AddProductScreen({
    super.key,
    this.product,
    this.initialCategoryId,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.product != null;
    final categoryProvider =
        Provider.of<ProductCategoryProvider>(context, listen: false);

    // INITIAL VALUES
    final initialValues = isEditing
        ? {
            'product_name': widget.product!.productName,
            'category_id': widget.product!.categoryId,
            'description': widget.product!.description,
            'unit_price': widget.product!.unitPrice.toString(),
            'stock_quantity': widget.product!.stockQuantity.toString(),
            'status': widget.product!.status,
          }
        : {
            'category_id': widget.initialCategoryId,
            'unit_price': "0",
            'stock_quantity': "0",
            'status': "Available",
          };

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Product" : "Add Product",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: initialValues,
                    child: ListView(
                      children: [
                        _sectionTitle("Basic Information"),

                        const SizedBox(height: 14),
                        _textField(
                          name: 'product_name',
                          label: 'Product Name',
                          icon: Icons.label_important,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),

                        const SizedBox(height: 20),
                        _sectionTitle("Category"),

                        const SizedBox(height: 14),
                        _categoryDropdown(categoryProvider),

                        const SizedBox(height: 20),
                        _sectionTitle("Details"),

                        const SizedBox(height: 14),
                        _textField(
                          name: 'description',
                          label: 'Description',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 20),
                        _sectionTitle("Pricing & Stock"),

                        const SizedBox(height: 14),
                        _textField(
                          name: 'unit_price',
                          label: 'Unit Price (₱)',
                          icon: Icons.payments_outlined,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            final val = double.tryParse(v);
                            if (val == null) return "Invalid number";
                            if (val < 0) return "Cannot be negative";
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        _textField(
                          name: 'stock_quantity',
                          label: 'Stock Quantity',
                          icon: Icons.inventory,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            final val = int.tryParse(v);
                            if (val == null) return "Invalid number";
                            if (val < 0) return "Cannot be negative";
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        _sectionTitle("Status"),

                        const SizedBox(height: 14),
                        _statusDropdown(),

                        const SizedBox(height: 35),

                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => _submit(context, isEditing),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(55),
                            backgroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            isEditing ? "Save Changes" : "Add Product",
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section Title
  // ---------------------------------------------------------------------------
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.grey[700],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text Field Component
  // ---------------------------------------------------------------------------
  Widget _textField({
    required String name,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return FormBuilderTextField(
      name: name,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category Dropdown
  // ---------------------------------------------------------------------------
  Widget _categoryDropdown(ProductCategoryProvider provider) {
    return FormBuilderDropdown<String>(
      name: 'category_id',
      decoration: InputDecoration(
        labelText: "Category",
        prefixIcon: const Icon(Icons.category_outlined),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text("Uncategorized")),
        ...provider.categories
            .where((c) => c.status == "Active")
            .map((c) => DropdownMenuItem(
                  value: c.categoryId,
                  child: Text(c.categoryName),
                )),
      ],
      validator: (v) {
        // example validation: require category selection
        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Status Dropdown
  // ---------------------------------------------------------------------------
  Widget _statusDropdown() {
    return FormBuilderDropdown<String>(
      name: 'status',
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(Icons.info_outline),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Available', child: Text('Available')),
        DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
        DropdownMenuItem(value: 'Discontinued', child: Text('Discontinued')),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMIT WITH ERROR TRAPPING
  // ---------------------------------------------------------------------------
  void _submit(BuildContext context, bool isEditing) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      _toastError(context, "Please correct the highlighted errors.");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final data = _formKey.currentState!.value;
      final provider = Provider.of<ProductProvider>(context, listen: false);

      // 🔴 Check for duplicate product name (if adding OR renaming)
      final exists = provider.products.any((p) =>
          p.product.productName.trim().toLowerCase() ==
              data['product_name'].trim().toLowerCase() &&
          p.product.productId != widget.product?.productId);

      if (exists) {
        _toastError(context, "A product with this name already exists.");
        setState(() => isSubmitting = false);
        return;
      }

      // Construct product object
      final product = Product(
        productId: isEditing ? widget.product!.productId : null,
        productName: data['product_name'],
        categoryId: data['category_id'],
        description: data['description'],
        unitPrice: double.parse(data['unit_price']),
        stockQuantity: int.parse(data['stock_quantity']),
        status: data['status'],
      );

      // SAVE
      if (isEditing) {
        await provider.updateProduct(product);
        _toastSuccess(context, "Product updated!");
      } else {
        await provider.addProduct(product);
        _toastSuccess(context, "Product added!");
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toastError(context, "Error saving product: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // TOAST HELPERS
  // ---------------------------------------------------------------------------
  void _toastSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toastError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
