import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isFullWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final bool isOutlined;

  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isFullWidth = true,
    this.borderRadius = 28.0,
    this.backgroundColor,
    this.isOutlined = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      setState(() => _isPressed = false);
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            gradient: widget.isOutlined || isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor,
                      Color.lerp(bgColor, Colors.black, 0.15) ?? bgColor,
                    ],
                  ),
            color: widget.isOutlined
                ? (_isPressed ? bgColor.withValues(alpha: 0.08) : Colors.transparent)
                : (isDisabled ? bgColor.withValues(alpha: 0.4) : null),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.isOutlined
                ? Border.all(color: bgColor, width: 1.5)
                : null,
            boxShadow: !isDisabled && !widget.isOutlined
                ? [
                    BoxShadow(
                      color: bgColor.withValues(alpha: _isPressed ? 0.5 : 0.3),
                      blurRadius: _isPressed ? 16 : 10,
                      offset: Offset(0, _isPressed ? 2 : 4),
                      spreadRadius: _isPressed ? 0 : -2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
