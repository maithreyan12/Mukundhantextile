import 'package:flutter/material.dart';
import '../../core/utils/extensions.dart';

class PriceText extends StatelessWidget {
  final double price;
  final double? discountPrice;
  final TextStyle? priceStyle;
  final TextStyle? originalStyle;

  const PriceText({
    super.key,
    required this.price,
    this.discountPrice,
    this.priceStyle,
    this.originalStyle,
  });

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  @override
  Widget build(BuildContext context) {
    final effectivePrice = discountPrice ?? price;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          effectivePrice.toCurrency,
          style: priceStyle ??
              context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            price.toCurrency,
            style: originalStyle ??
                context.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
          ),
        ],
      ],
    );
  }
}
