import 'package:flutter/material.dart';
import 'package:gym/screens/product_categories_screen.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/product_provider.dart';
import 'package:gym/providers/product_category_provider.dart';
import 'package:gym/models/product.dart';
import 'package:gym/screens/add_product_screen.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategoryId;

  const ProductsScreen({super.key, this.initialCategoryId});

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
    Provider.of<ProductCategoryProvider>(context, listen: false)
        .fetchProductCategories();

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (_selectedCategoryId != null) {
      productProvider.filterProductsByCategory(_selectedCategoryId!);
    } else {
      productProvider.fetchProducts();
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);

    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (categoryId == null) {
      provider.fetchProducts();
    } else {
      provider.filterProductsByCategory(categoryId);
    }
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
    final theme = Theme.of(context);
    final categoryProvider = Provider.of<ProductCategoryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ⭐ PREMIUM APP BAR
      appBar: AppBar(
        title: const Text(
          "Inventory",
          style: TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: "Add Category",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProductCategoriesScreen()),
              );
              if (mounted) {
                Provider.of<ProductCategoryProvider>(context, listen: false)
                    .fetchProductCategories();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // ⭐ PREMIUM SEARCH BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<ProductProvider>(context, listen: false)
                              .searchProducts("", categoryId: _selectedCategoryId);
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (q) {
                Provider.of<ProductProvider>(context, listen: false)
                    .searchProducts(q, categoryId: _selectedCategoryId);
              },
            ),
          ),

          const SizedBox(height: 8),

          // ⭐ PREMIUM CATEGORY FILTER BAR
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip("All", null),
                ...categoryProvider.categories.map(
                  (cat) => _categoryChip(
                      cat.categoryName, cat.categoryId),
                ),
              ],
            ),
          ),

          // ⭐ PRODUCT LIST
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.products.isEmpty) {
                  return _emptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.products.length,
                  itemBuilder: (_, i) {
                    final item = provider.products[i];
                    final p = item.product;

                    return _productCard(context, provider, item);
                  },
                );
              },
            ),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text("New Product"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddProductScreen(initialCategoryId: _selectedCategoryId),
            ),
          );
        },
      ),
    );
  }

  // ⭐ FILTER CHIP BUILDER
  Widget _categoryChip(String label, String? id) {
    final isSelected = _selectedCategoryId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Theme.of(context).primaryColor.withOpacity(.15),
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade400,
          ),
        ),
        onSelected: (_) => _onCategorySelected(id),
      ),
    );
  }

  // ⭐ EMPTY STATE
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 90, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "No products found",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ⭐ PREMIUM PRODUCT CARD
  Widget _productCard(
    BuildContext context,
    ProductProvider provider,
    DetailedProduct detailed,
  ) {
    final p = detailed.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductScreen(product: p),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    p.productName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    if (_selectedCategoryId == null)
                      Text(
                        detailed.categoryName ?? "Uncategorized",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                      ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(p.status).withOpacity(.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.status ?? "Unknown",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: _getStatusColor(p.status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Stock: ${p.stockQuantity}",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // Price & delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(locale: "en_PH", symbol: "₱")
                        .format(p.unitPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _confirmDelete(context, provider, p),
                    child: Icon(Icons.delete_outline,
                        size: 20, color: Colors.grey.shade400),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ⭐ DELETE CONFIRMATION
  void _confirmDelete(
      BuildContext context, ProductProvider provider, Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product?"),
        content: Text(
          'Are you sure you want to delete "${product.productName}"?\nThis cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text("Delete", style: TextStyle(color: Colors.white)),
            onPressed: () {
              provider.deleteProduct(product.productId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${product.productName} deleted.")),
              );
            },
          ),
        ],
      ),
    );
  }
}
