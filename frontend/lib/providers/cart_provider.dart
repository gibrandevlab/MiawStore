import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  // Keyed by productId (string)
  final Map<String, Map<String, dynamic>> _items = {};

  Map<String, Map<String, dynamic>> get items => _items;

  List<Map<String, dynamic>> get itemsList => _items.entries
      .map((e) => {
            'productId': e.key,
            'product': e.value['product'],
            'quantity': e.value['quantity']
          })
      .toList();

  void addToCart(Map<String, dynamic> product) {
    final id = product['id'].toString();
    if (_items.containsKey(id)) {
      _items[id]!['quantity'] = (_items[id]!['quantity'] as int) + 1;
    } else {
      _items[id] = {'product': product, 'quantity': 1};
    }
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> product) {
    final id = product['id'].toString();
    if (_items.containsKey(id)) {
      _items.remove(id);
      notifyListeners();
    }
  }

  void increaseQty(String productId) {
    final id = productId.toString();
    if (_items.containsKey(id)) {
      _items[id]!['quantity'] = (_items[id]!['quantity'] as int) + 1;
      notifyListeners();
    }
  }

  void decreaseQty(String productId) {
    final id = productId.toString();
    if (!_items.containsKey(id)) return;
    final current = (_items[id]!['quantity'] as int);
    if (current <= 1) {
      _items.remove(id);
    } else {
      _items[id]!['quantity'] = current - 1;
    }
    notifyListeners();
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, val) {
      final price = (val['product']?['price'] ?? 0).toDouble();
      final qty = val['quantity'] as int;
      total += price * qty;
    });
    return total;
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
