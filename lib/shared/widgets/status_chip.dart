import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
  });

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFa502);
      case 'confirmed':
        return const Color(0xFF3498db);
      case 'processing':
        return const Color(0xFF9b59b6);
      case 'shipped':
        return const Color(0xFF1abc9c);
      case 'delivered':
        return const Color(0xFF2ED573);
      case 'cancelled':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? getStatusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
