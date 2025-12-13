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

  get productName => null;
}

class ProductProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedProduct> _products = [];
  List<DetailedProduct> _filteredProducts = [];
  bool _isLoading = false;
  String? _currentCategoryFilter;

  ProductProvider(this._dbHelper) {
    fetchProducts();
  }

  List<DetailedProduct> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get currentCategoryFilter => _currentCategoryFilter;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchProducts({String? categoryId}) async {
    _setLoading(true);
    try {
      final productMaps = await _dbHelper.getDetailedProducts();
      _products = productMaps.map((map) => DetailedProduct.fromMap(map)).toList();
      
      // Apply category filter if provided
      if (categoryId != null) {
        _filteredProducts = _products.where((p) => p.product.categoryId == categoryId).toList();
        _currentCategoryFilter = categoryId;
      } else {
        _filteredProducts = List.from(_products);
        _currentCategoryFilter = null;
      }
    } catch (e) {
      print('Error fetching detailed products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _dbHelper.insertProduct(product.toJson());
      await fetchProducts(categoryId: _currentCategoryFilter); // Re-fetch with current filter
    } catch (e) {
      print('Error adding product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _dbHelper.updateProduct(product.toJson());
      await fetchProducts(categoryId: _currentCategoryFilter); // Re-fetch with current filter
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

  void searchProducts(String query, {String? categoryId}) {
    if (query.isEmpty && categoryId == null) {
      _filteredProducts = List.from(_products);
      _currentCategoryFilter = null;
    } else {
      _filteredProducts = _products.where((detailedProduct) {
        // Apply category filter
        final matchesCategory = categoryId == null || detailedProduct.product.categoryId == categoryId;
        
        // Apply search query filter
        final matchesSearch = query.isEmpty ? true : 
            detailedProduct.product.productName.toLowerCase().contains(query.toLowerCase()) ||
            (detailedProduct.categoryName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (detailedProduct.product.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
        
        return matchesCategory && matchesSearch;
      }).toList();
      
      _currentCategoryFilter = categoryId;
    }
    notifyListeners();
  }

  // Method to filter products by category only (without search)
  void filterProductsByCategory(String? categoryId) {
    if (categoryId == null) {
      _filteredProducts = List.from(_products);
      _currentCategoryFilter = null;
    } else {
      _filteredProducts = _products.where((p) => p.product.categoryId == categoryId).toList();
      _currentCategoryFilter = categoryId;
    }
    notifyListeners();
  }

  // Method to clear all filters
  void clearFilters() {
    _filteredProducts = List.from(_products);
    _currentCategoryFilter = null;
    notifyListeners();
  }
}