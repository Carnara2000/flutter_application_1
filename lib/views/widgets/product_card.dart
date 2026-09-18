import 'package:flutter/material.dart';

import '../../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({required this.product, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.network(
                    product.image,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
