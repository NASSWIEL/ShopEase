import 'package:flutter/foundation.dart';
import 'package:shopease/models/cart_item.dart';

class Cart with ChangeNotifier {
  // Map of product id to cart item
  Map<String, CartItem> _items = {};

  // Map to store stock information for products
  Map<String, int> _stockLimits = {};

  // Getter for the items
  Map<String, CartItem> get items {
    return {..._items};
  }

  // Get the total number of items in cart
  int get itemCount {
    return _items.length;
  }

  // Get the total quantity of all items
  int get totalQuantity {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  // Get the total price of all items
  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // Update stock limit for a product
  void setStockLimit(String productId, int stockLimit) {
    _stockLimits[productId] = stockLimit;
  }

  // Get current stock limit for a product
  int? getStockLimit(String productId) {
    return _stockLimits[productId];
  }

  // Check if we can add more of this product
  bool canAddMore(String productId) {
    if (!_stockLimits.containsKey(productId)) {
      return true; // If we don't have stock info, allow adding
    }

    final stockLimit = _stockLimits[productId]!;
    final currentQuantity = _items[productId]?.quantity ?? 0;

    return currentQuantity < stockLimit;
  }

  // Add item to cart - supporting multiple method signatures to fix compatibility issues
  void addItem({
    required String productId,
    required double price,
    required String name,
    String? imageUrl,
    int? stockLimit,
  }) {
    // If stock limit is provided, update our record
    if (stockLimit != null) {
      setStockLimit(productId, stockLimit);
    }

    if (_items.containsKey(productId)) {
      // Check if we can add more before increasing quantity
      if (canAddMore(productId)) {
        // If item already exists, just increase quantity
        _items.update(
          productId,
          (existingCartItem) => existingCartItem.copyWith(
            quantity: existingCartItem.quantity + 1,
          ),
        );
      }
    } else {
      // Otherwise add a new item
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  // Alternate signature for addItem - used in product_detail_page.dart
  void addItems(String id, String name, double price, String imageUrl,
      {int? stockLimit}) {
    addItem(
      productId: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      stockLimit: stockLimit,
    );
  }

  // Remove a single item - used in product_detail_page.dart
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  // Increment quantity of an item
  bool incrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      // Check if we can add more based on stock limit
      if (canAddMore(productId)) {
        _items.update(
          productId,
          (existingCartItem) => existingCartItem.copyWith(
            quantity: existingCartItem.quantity + 1,
          ),
        );
        notifyListeners();
        return true; // Successfully incremented
      }
      return false; // Couldn't increment due to stock limit
    }
    return false; // Item not in cart
  }

  // Decrement quantity of an item
  void decrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items.update(
          productId,
          (existingCartItem) => existingCartItem.copyWith(
            quantity: existingCartItem.quantity - 1,
          ),
        );
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  // Remove item from cart
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Clear cart
  void clear() {
    _items = {};
    notifyListeners();
  }
}
