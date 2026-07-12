import 'package:flutter/material.dart';

class AnimatedChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const AnimatedChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor =
        color ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: chipColor),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: chipColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
