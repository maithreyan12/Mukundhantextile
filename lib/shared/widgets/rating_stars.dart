import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.color = const Color(0xFFFFa502),
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        IconData icon;
        if (rating >= starIndex) {
          icon = Icons.star_rounded;
        } else if (rating >= starIndex - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return GestureDetector(
          onTap: interactive ? () => onRatingChanged?.call(starIndex) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(icon, size: size, color: color),
          ),
        );
      }),
    );
  }
}
