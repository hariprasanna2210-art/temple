import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../theme.dart';

class TagChip extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool fullTap;
  final Color? color;
  const TagChip({
    super.key,
    required this.title,
    required this.onTap,
    this.onLongPress,
    this.fullTap = false,
    this.color = lightSkyBlue,
  });

  @override
  Widget build(BuildContext context) {
    final chipContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        if (!fullTap) ...[
          const SizedBox(width: 7),
          InkWell(
            onTap: onTap,
            child: const Icon(Icons.close, size: 20, color: Colors.black87),
          ),
        ],
      ],
    ).paddingAll(7);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          fullTap
              ? InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onTap,
                onLongPress: onLongPress,
                child: chipContent,
              )
              : chipContent,
    );
  }
}
