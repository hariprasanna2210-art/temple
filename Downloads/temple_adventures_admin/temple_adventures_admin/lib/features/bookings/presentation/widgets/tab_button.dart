import 'package:flutter/material.dart';

import '../../../../theme.dart';

class TabButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool enable;
  final Color? color;
  final int? count;

  const TabButton({super.key, required this.title, required this.onTap, this.enable = false, this.color, this.count});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: enable ? skyBlueColor : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: enable ? Colors.white : Colors.black,
                ),
              ),
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: FittedBox(
                  child: Center(
                    child: Text(
                      '${count ?? 0}',
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
