// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:gym/screens/product_categories_screen.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/product_provider.dart';
import 'package:gym/providers/product_category_provider.dart';
import 'package:gym/models/product.dart';
import 'package:gym/screens/add_product_screen.dart';
import 'package:gym/screens/add_product_category_screen.dart'; // NEW IMPORT
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategoryId;
  
  const ProductsScreen({
    super.key,
    this.initialCategoryId,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    // Fetch Categories for the filter bar
    Provider.of<ProductCategoryProvider>(context, listen: false).fetchProductCategories();

    // Fetch Products
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (_selectedCategoryId != null) {
      productProvider.filterProductsByCategory(_selectedCategoryId!);
    } else {
      productProvider.fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (categoryId == null) {
      productProvider.fetchProducts(); 
    } else {
      productProvider.filterProductsByCategory(categoryId);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available': return Colors.green;
      case 'out of stock': return Colors.red;
      case 'discontinued': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<ProductCategoryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          // NEW: Add Category Navigation
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Add New Category',
            onPressed: () async {
              // Navigate to Add Category Screen
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductCategoriesScreen()),
              );
              // Refresh categories list when returning so the new chip appears
              if (mounted) {
                Provider.of<ProductCategoryProvider>(context, listen: false).fetchProductCategories();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<ProductProvider>(context, listen: false)
                              .searchProducts('', categoryId: _selectedCategoryId);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                Provider.of<ProductProvider>(context, listen: false)
                    .searchProducts(query, categoryId: _selectedCategoryId);
              },
            ),
          ),

          // 2. Category Filter Bar
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildFilterChip(label: 'All', id: null, isSelected: _selectedCategoryId == null),
                ...categoryProvider.categories.map((cat) {
                  return _buildFilterChip(
                    label: cat.categoryName,
                    id: cat.categoryId,
                    isSelected: _selectedCategoryId == cat.categoryId,
                  );
                }),
              ],
            ),
          ),

          // 3. Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (productProvider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategoryId != null 
                              ? 'No products in this category'
                              : 'No products found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        if (_selectedCategoryId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddProductScreen(
                                      initialCategoryId: _selectedCategoryId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Product Here'),
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final detailedProduct = productProvider.products[index];
                      final product = detailedProduct.product;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductScreen(product: product),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Icon Box
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      product.productName.isNotEmpty ? product.productName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.productName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Only show category name if viewing "All"
                                      if (_selectedCategoryId == null)
                                        Text(
                                          detailedProduct.categoryName ?? 'Uncategorized',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(product.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              product.status ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(product.status),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Stock: ${product.stockQuantity}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Price & Action
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(product.unitPrice),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _confirmDelete(context, productProvider, product),
                                      child: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(
                initialCategoryId: _selectedCategoryId,
              ),
            ),
          );
        },
        label: const Text("New Product"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String? id, required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            _onCategorySelected(id);
          }
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductProvider productProvider, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product?'),
          content: Text('Are you sure you want to delete "${product.productName}"?\n\nThis cannot be undone.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                productProvider.deleteProduct(product.productId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.productName} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}