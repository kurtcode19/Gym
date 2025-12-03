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

      // ⭐ PREMIUM APP BAR
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
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: Column(
        children: [
          // ⭐ Header Graphic
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withOpacity(.15),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 45,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isEditing ? "Update Product Details" : "Create New Product",
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ],
            ),
          ),

          // ⭐ FORM CARD
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
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Product name cannot be empty'
                              : null,
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
                          label: 'Description (Optional)',
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
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) {
                              return 'Invalid number';
                            }
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
                            if (v == null || v.isEmpty) return 'Required';
                            if (int.tryParse(v) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        _sectionTitle("Status"),

                        const SizedBox(height: 14),
                        _statusDropdown(),

                        const SizedBox(height: 35),

                        // ⭐ SUBMIT BUTTON
                        ElevatedButton(
                          onPressed: () => _submit(context, isEditing),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(55),
                            backgroundColor: theme.primaryColor,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isEditing ? "Save Changes" : "Add Product",
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        )
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
  // ⭐ Reusable Components
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
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _categoryDropdown(ProductCategoryProvider categoryProvider) {
    return FormBuilderDropdown<String>(
      name: 'category_id',
      decoration: InputDecoration(
        labelText: "Category",
        prefixIcon: const Icon(Icons.category_outlined),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text("Uncategorized")),
        ...categoryProvider.categories
            .where((cat) => cat.status == "Active")
            .map(
              (cat) => DropdownMenuItem(
                value: cat.categoryId,
                child: Text(cat.categoryName),
              ),
            )
      ],
    );
  }

  Widget _statusDropdown() {
    return FormBuilderDropdown<String>(
      name: 'status',
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(Icons.info_outline),
        filled: true,
        fillColor: Colors.grey[100],
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
  // ⭐ Submit Logic
  // ---------------------------------------------------------------------------
  void _submit(BuildContext context, bool isEditing) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final data = _formKey.currentState!.value;

      final newProduct = Product(
        productId: isEditing ? widget.product!.productId : null,
        productName: data['product_name'],
        categoryId: data['category_id'],
        description: data['description'],
        unitPrice: double.tryParse(data['unit_price']) ?? 0,
        stockQuantity: int.tryParse(data['stock_quantity']) ?? 0,
        status: data['status'],
      );

      final provider =
          Provider.of<ProductProvider>(context, listen: false);

      if (isEditing) {
        await provider.updateProduct(newProduct);
        _toast(context, "${newProduct.productName} updated!");
      } else {
        await provider.addProduct(newProduct);
        _toast(context, "${newProduct.productName} added!");
      }

      Navigator.pop(context);
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
