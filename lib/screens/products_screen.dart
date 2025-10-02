// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/product_provider.dart';
import 'package:gym/models/product.dart';
import 'package:gym/screens/add_product_screen.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  final String? filteredCategoryId;
  final String? filteredCategoryName;
  
  const ProductsScreen({
    super.key,
    this.filteredCategoryId,
    this.filteredCategoryName,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Apply category filter when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.filteredCategoryId != null) {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        productProvider.filterProductsByCategory(widget.filteredCategoryId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'out of stock':
        return Colors.red;
      case 'discontinued':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.filteredCategoryId != null 
            ? Text('Products - ${widget.filteredCategoryName}')
            : const Text('Products'),
        leading: widget.filteredCategoryId != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<ProductProvider>(context, listen: false)
                              .searchProducts('', categoryId: widget.filteredCategoryId);
                        },
                      )
                    : null,
              ),
              onChanged: (query) {
                Provider.of<ProductProvider>(context, listen: false)
                    .searchProducts(query, categoryId: widget.filteredCategoryId);
              },
            ),
          ),
          if (widget.filteredCategoryId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Chip(
                    label: Text('Category: ${widget.filteredCategoryName}'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      // Clear category filter and navigate back
                      Provider.of<ProductProvider>(context, listen: false).clearFilters();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
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
                        const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          widget.filteredCategoryId != null 
                              ? 'No products found in ${widget.filteredCategoryName} category'
                              : 'No products found.',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (widget.filteredCategoryId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddProductScreen(
                                      initialCategoryId: widget.filteredCategoryId,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Add Product to this Category'),
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final detailedProduct = productProvider.products[index];
                      final product = detailedProduct.product;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(product.status),
                            child: Text(
                              product.productName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(product.productName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.filteredCategoryId == null) // Only show category if not filtered
                                Text(
                                  'Category: ${detailedProduct.categoryName ?? 'Uncategorized'}',
                                ),
                              Text(
                                'Price: ${NumberFormat.currency(symbol: '\$').format(product.unitPrice)} '
                                '• Stock: ${product.stockQuantity}',
                              ),
                              Text('Status: ${product.status ?? 'N/A'}'),
                            ],
                          ),
                          isThreeLine: widget.filteredCategoryId == null,
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductScreen(product: product),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, productProvider, product);
                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(
                initialCategoryId: widget.filteredCategoryId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductProvider productProvider, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "${product.productName}"? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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