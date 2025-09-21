// lib/providers/product_category_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/product_category.dart';
import 'package:gym/providers/database_helper.dart';

class ProductCategoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<ProductCategory> _categories = [];
  List<ProductCategory> _filteredCategories = [];
  bool _isLoading = false;

  ProductCategoryProvider(this._dbHelper) {
    fetchProductCategories();
  }

  List<ProductCategory> get categories => _filteredCategories;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchProductCategories() async {
    _setLoading(true);
    try {
      final categoryMaps = await _dbHelper.getProductCategories();
      _categories = categoryMaps.map((map) => ProductCategory.fromJson(map)).toList();
      _filteredCategories = List.from(_categories);
    } catch (e) {
      print('Error fetching product categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProductCategory(ProductCategory category) async {
    try {
      await _dbHelper.insertProductCategory(category.toJson());
      _categories.add(category);
      _filteredCategories = List.from(_categories);
      notifyListeners();
    } catch (e) {
      print('Error adding product category: $e');
    }
  }

  Future<void> updateProductCategory(ProductCategory category) async {
    try {
      await _dbHelper.updateProductCategory(category.toJson());
      final index = _categories.indexWhere((c) => c.categoryId == category.categoryId);
      if (index != -1) {
        _categories[index] = category;
        _filteredCategories = List.from(_categories);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating product category: $e');
    }
  }

  Future<void> deleteProductCategory(String categoryId) async {
    try {
      await _dbHelper.deleteProductCategory(categoryId);
      _categories.removeWhere((c) => c.categoryId == categoryId);
      _filteredCategories.removeWhere((c) => c.categoryId == categoryId);
      notifyListeners();
    } catch (e) {
      print('Error deleting product category: $e');
    }
  }

  void searchProductCategories(String query) {
    if (query.isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      _filteredCategories = _categories.where((category) {
        final lowerCaseQuery = query.toLowerCase();
        return category.categoryName.toLowerCase().contains(lowerCaseQuery) ||
               (category.description?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}