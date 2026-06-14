import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A3A5C) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF3A4A6C) : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // ── Product Grid Shimmer ──────────────────────────────
  static Widget productGrid({int count = 6}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const ShimmerLoading(height: 250),
    );
  }

  // ── Horizontal List Shimmer ───────────────────────────
  static Widget horizontalList({int count = 5, double height = 180}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => ShimmerLoading(width: 140, height: height),
      ),
    );
  }

  // ── Banner Shimmer ────────────────────────────────────
  static Widget banner() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerLoading(height: 160, borderRadius: 16),
    );
  }

  // ── List Tile Shimmer ─────────────────────────────────
  static Widget listTile({int count = 5}) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const ShimmerLoading(width: 56, height: 56, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoading(height: 14, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerLoading(
                        height: 12, width: 100, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
