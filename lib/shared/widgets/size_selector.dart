import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/extensions.dart';

class SizeSelector extends StatefulWidget {
  final List<String> sizes;
  final String? initialSize;
  final ValueChanged<String> onSizeSelected;

  const SizeSelector({
    super.key,
    required this.sizes,
    required this.onSizeSelected,
    this.initialSize,
  });

  @override
  State<SizeSelector> createState() => _SizeSelectorState();
}

class _SizeSelectorState extends State<SizeSelector> {
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.sizes.map((size) {
          final isSelected = _selectedSize == size;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SizeItem(
              size: size,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedSize = size);
                widget.onSizeSelected(size);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SizeItem extends StatefulWidget {
  final String size;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeItem({required this.size, required this.isSelected, required this.onTap});

  @override
  State<_SizeItem> createState() => _SizeItemState();
}

class _SizeItemState extends State<_SizeItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFFEAEAEA) : Colors.transparent,
            border: Border.all(
              color: widget.isSelected ? const Color(0xFFEAEAEA) : (context.isDarkMode ? const Color(0xFF333333) : Colors.grey.shade300),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.isSelected ? [
              BoxShadow(
                color: const Color(0xFFEAEAEA).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Text(
            widget.size,
            style: TextStyle(
              color: widget.isSelected ? Colors.black : (context.isDarkMode ? Colors.white : Colors.black),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
