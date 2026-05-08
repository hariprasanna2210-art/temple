import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import '../../../../utils/styling/spacing_widgets.dart';

class OverlayIconWidget extends StatelessWidget {
  const OverlayIconWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildVerticalLine(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacing.w10,
            _buildHorizontalLine(),
            const Icon(Icons.add, size: 20),
            _buildHorizontalLine(),
            Spacing.w10,
          ],
        ),
        _buildVerticalLine(),
      ],
    ).center;
  }

  Widget _buildVerticalLine() {
    return Container(
      width: 3,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
    );
  }

  Widget _buildHorizontalLine() {
    return Container(
      width: 80,
      height: 3,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
    );
  }
}
