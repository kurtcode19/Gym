// lib/providers/sale_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/models/sale.dart';
import 'package:gym/models/sale_item.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/models/product.dart';
import 'package:sqflite/sqflite.dart';

// Model to hold joined sale item data for display
class DetailedSaleItem {
  final SaleItem saleItem;
  final String productName;
  final String? productDescription;

  DetailedSaleItem({
    required this.saleItem,
    required this.productName,
    this.productDescription,
  });

  factory DetailedSaleItem.fromMap(Map<String, dynamic> map) {
    return DetailedSaleItem(
      saleItem: SaleItem.fromJson(map),
      productName: map['product_name'],
      productDescription: map['product_description'],
    );
  }
}

// Model to hold joined sale data (sale + customer info + list of detailed items)
class DetailedSale {
  final Sale sale;
  final String customerFirstName;
  final String customerLastName;
  final List<DetailedSaleItem> items;

  DetailedSale({
    required this.sale,
    required this.customerFirstName,
    required this.customerLastName,
    required this.items,
  });

  factory DetailedSale.fromMap(Map<String, dynamic> map, List<DetailedSaleItem> items) {
    return DetailedSale(
      sale: Sale.fromJson(map),
      customerFirstName: map['customer_first_name'],
      customerLastName: map['customer_last_name'],
      items: items,
    );
  }
}

class SaleProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedSale> _sales = [];
  List<DetailedSale> _filteredSales = [];
  bool _isLoading = false;

  SaleProvider(this._dbHelper) {
    fetchSales();
  }

  List<DetailedSale> get sales => _filteredSales;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchSales() async {
    _setLoading(true);
    try {
      final saleMaps = await _dbHelper.getDetailedSales();
      List<DetailedSale> fetchedSales = [];

      for (var saleMap in saleMaps) {
        final saleId = saleMap['sale_id'] as String;
        final itemMaps = await _dbHelper.getDetailedSaleItemsForSale(saleId);
        final items = itemMaps.map((map) => DetailedSaleItem.fromMap(map)).toList();
        fetchedSales.add(DetailedSale.fromMap(saleMap, items));
      }

      _sales = fetchedSales;
      _filteredSales = List.from(_sales);
    } catch (e) {
      print('Error fetching detailed sales: $e');
    } finally {
      _setLoading(false);
    }
  }

  // This method will handle inserting a new sale and its associated items as a transaction
  Future<void> addSale(Sale sale, List<SaleItem> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      try {
        await txn.insert('SALE', sale.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
        for (var item in items) {
          await txn.insert('SALE_ITEM', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await fetchSales(); // Re-fetch all to update the list
      } catch (e) {
        print('Transaction failed to add sale: $e');
        // Rethrow or handle error appropriately
      }
    });
  }

  // This method will handle updating a sale and its associated items as a transaction
  Future<void> updateSale(Sale sale, List<SaleItem> newItems) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      try {
        await txn.update(
          'SALE',
          sale.toJson(),
          where: 'sale_id = ?',
          whereArgs: [sale.saleId],
        );

        // Delete old items and insert new ones
        await txn.delete(
          'SALE_ITEM',
          where: 'sale_id = ?',
          whereArgs: [sale.saleId],
        );
        for (var item in newItems) {
          await txn.insert('SALE_ITEM', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await fetchSales(); // Re-fetch all to update the list
      } catch (e) {
        print('Transaction failed to update sale: $e');
        // Rethrow or handle error appropriately
      }
    });
  }

  // Delete a sale and its associated items (CASCADE in DB schema should handle items)
  Future<void> deleteSale(String saleId) async {
    try {
      await _dbHelper.deleteSale(saleId);
      _sales.removeWhere((s) => s.sale.saleId == saleId);
      _filteredSales.removeWhere((s) => s.sale.saleId == saleId);
      notifyListeners();
    } catch (e) {
      print('Error deleting sale: $e');
    }
  }

  void searchSales(String query) {
    if (query.isEmpty) {
      _filteredSales = List.from(_sales);
    } else {
      _filteredSales = _sales.where((detailedSale) {
        final lowerCaseQuery = query.toLowerCase();
        return detailedSale.customerFirstName.toLowerCase().contains(lowerCaseQuery) ||
               detailedSale.customerLastName.toLowerCase().contains(lowerCaseQuery) ||
               detailedSale.sale.paymentMethod!.toLowerCase().contains(lowerCaseQuery) ||
               detailedSale.items.any((item) => item.productName.toLowerCase().contains(lowerCaseQuery));
      }).toList();
    }
    notifyListeners();
  }
}