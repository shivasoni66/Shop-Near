class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String shopName;
  final double price;
  final int quantity;
  final String? imagePlaceholder;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.shopName,
    required this.price,
    required this.quantity,
    this.imagePlaceholder,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['_id'] ?? map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      shopName: map['shopName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imagePlaceholder: map['imagePlaceholder'],
    );
  }
}
