import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String description;
  final Widget? action;
  final bool hideBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.description,
    this.action,
    this.hideBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'nunito',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'nunito',
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ).paddingOnly(top: 10),
      actions: [if (action != null) action!.paddingOnly(top: 16)],
      titleSpacing: 0,
      elevation: 0,
      leadingWidth: hideBackButton ? 40 : 50,
      leading: hideBackButton ? const SizedBox() : null,
    );
  }
}
