class RatingModel {
  final double rate;
  final int count;

  const RatingModel({required this.rate, required this.count});

  /// Crea la calificación desde JSON; ProductModel.fromJson la utiliza.
  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convierte la calificación a JSON; ProductModel.toJson la utiliza.
  Map<String, dynamic> toJson() => {'rate': rate, 'count': count};
}

class ProductModel {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final RatingModel? rating;

  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    this.rating,
  });

  /// Convierte datos de Fake Store API; product_service.dart lo usa.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      image: json['image'] as String? ?? '',
      rating: json['rating'] is Map<String, dynamic>
          ? RatingModel.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Serializa el producto para cambios remotos; product_service.dart lo usa.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'image': image,
        if (rating != null) 'rating': rating!.toJson(),
      };

  /// Copia el producto con cambios parciales; product_detail_view.dart lo usa al editar.
  ProductModel copyWith({
    int? id,
    String? title,
    double? price,
    String? description,
    String? category,
    String? image,
    RatingModel? rating,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      rating: rating ?? this.rating,
    );
  }
}
