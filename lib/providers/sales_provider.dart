import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';

class SalesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SaleModel> _sales = [];
  List<SaleItem> _currentCart = [];
  bool _isLoading = false;
  String? _error;

  List<SaleModel> get sales => _sales;
  List<SaleItem> get currentCart => _currentCart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get cartTotal => _currentCart.fold(0, (sum, item) => sum + item.subtotal);
  double get cartProfit => _currentCart.fold(0, (sum, item) => sum + item.itemProfit);

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .get();
      _sales = snapshot.docs
          .map((doc) => SaleModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToCart(ProductModel product, int quantity) {
    int existingIndex = _currentCart.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex != -1) {
      _currentCart[existingIndex] = SaleItem(
        productId: product.id,
        productName: product.name,
        quantity: _currentCart[existingIndex].quantity + quantity,
        price: product.price,
        cost: product.cost,
      );
    } else {
      _currentCart.add(SaleItem(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        price: product.price,
        cost: product.cost,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _currentCart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    int index = _currentCart.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity > 0) {
        _currentCart[index] = SaleItem(
          productId: _currentCart[index].productId,
          productName: _currentCart[index].productName,
          quantity: quantity,
          price: _currentCart[index].price,
          cost: _currentCart[index].cost,
        );
      } else {
        _currentCart.removeAt(index);
      }
      notifyListeners();
    }
  }

  Future<bool> processSale(String userId, String paymentMethod) async {
    if (_currentCart.isEmpty) return false;

    try {
      String saleId = DateTime.now().millisecondsSinceEpoch.toString();
      
      SaleModel sale = SaleModel(
        id: saleId,
        userId: userId,
        items: List.from(_currentCart),
        total: cartTotal,
        profit: cartProfit,
        createdAt: DateTime.now(),
        paymentMethod: paymentMethod,
      );

      await _firestore.collection('sales').doc(saleId).set(sale.toJson());
      
      // Update stock for each product
      for (SaleItem item in _currentCart) {
        await _firestore.collection('products').doc(item.productId).update({
          'stock': FieldValue.increment(-item.quantity),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      _sales.insert(0, sale);
      _currentCart.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearCart() {
    _currentCart.clear();
    notifyListeners();
  }

  List<SaleModel> getDailySales(DateTime date) {
    return _sales.where((sale) {
      return sale.createdAt.year == date.year &&
          sale.createdAt.month == date.month &&
          sale.createdAt.day == date.day;
    }).toList();
  }

  double getDailyRevenue(DateTime date) {
    return getDailySales(date).fold(0, (sum, sale) => sum + sale.total);
  }

  double getDailyProfit(DateTime date) {
    return getDailySales(date).fold(0, (sum, sale) => sum + sale.profit);
  }
}
