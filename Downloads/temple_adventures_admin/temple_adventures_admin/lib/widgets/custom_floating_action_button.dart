import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    super.key,
    required this.onTap,
    this.child,
    this.heroTag,
  });

  final VoidCallback onTap;
  final Widget? child;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onTap,
      elevation: 0,
      backgroundColor: Colors.black,
      child: child ?? Icon(Icons.add),
    );
  }
}
