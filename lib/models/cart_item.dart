import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: ProductModel.fromJson(
          Map<String, dynamic>.from(json['product'] as Map),
        ),
        quantity: json['quantity'] as int,
      );
}
