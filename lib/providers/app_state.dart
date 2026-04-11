import 'package:flutter/material.dart';
import 'package:milk_delivery_assist/models/auth/user_session.dart';
import 'package:milk_delivery_assist/models/product.dart';

class AppState extends ChangeNotifier {
  final List<CartItem> _cart = [];
  final double _walletBalance = 1500.0;

  // ---------------- Cart ----------------
  List<CartItem> get cart => _cart;
  double get walletBalance => _walletBalance;
  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  void addToCart(Product product, int quantity, bool isSub, String freq) {
    final index = _cart.indexWhere((item) =>
        item.product.id == product.id &&
        item.isSubscription == isSub &&
        item.frequency == freq);

    if (index >= 0) {
      _cart[index].quantity += quantity;
    } 
    else {
      _cart.add(CartItem(
        product: product,
        quantity: quantity,
        isSubscription: isSub,
        frequency: freq,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ---------------- User ----------------
  UserSession? _user; // private field to store the user

  UserSession? get user => _user; // public getter

  void setUser(UserSession user) {
    _user = user; // assign to private field
    notifyListeners();
  }

  void logout() {
    _user = null; // clear user
    clearCart(); // also clear cart
    notifyListeners();
  }

  void refreshUser() {
    notifyListeners(); // just refresh UI
  }
}
