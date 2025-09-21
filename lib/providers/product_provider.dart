// lib/providers/product_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/product.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/product_category.dart'; // For category names

// Model to hold joined product data for display
class DetailedProduct {
  final Product product;
  final String? categoryName;

  DetailedProduct({
    required this.product,
    this.categoryName,
  });

  factory DetailedProduct.fromMap(Map<String, dynamic> map) {
    return DetailedProduct(
      product: Product.fromJson(map),
      categoryName: map['category_name'],
    );
  }
}

class ProductProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedProduct> _products = [];
  List<DetailedProduct> _filteredProducts = [];
  bool _isLoading = false;

  ProductProvider(this._dbHelper) {
    fetchProducts();
  }

  List<DetailedProduct> get products => _filteredProducts;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      final productMaps = await _dbHelper.getDetailedProducts();
      _products = productMaps.map((map) => DetailedProduct.fromMap(map)).toList();
      _filteredProducts = List.from(_products);
    } catch (e) {
      print('Error fetching detailed products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _dbHelper.insertProduct(product.toJson());
      await fetchProducts(); // Re-fetch all to get the detailed view
    } catch (e) {
      print('Error adding product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _dbHelper.updateProduct(product.toJson());
      await fetchProducts(); // Re-fetch all to get the detailed view
    } catch (e) {
      print('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _dbHelper.deleteProduct(productId);
      _products.removeWhere((p) => p.product.productId == productId);
      _filteredProducts.removeWhere((p) => p.product.productId == productId);
      notifyListeners();
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((detailedProduct) {
        final lowerCaseQuery = query.toLowerCase();
        return detailedProduct.product.productName.toLowerCase().contains(lowerCaseQuery) ||
               (detailedProduct.categoryName?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
               (detailedProduct.product.description?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}