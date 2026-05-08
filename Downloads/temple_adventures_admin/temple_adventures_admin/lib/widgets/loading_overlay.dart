import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';

import '../utils/styling/app_measurements.dart';
import '../utils/styling/spacing_widgets.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Screen.height,
      color: Colors.black38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white).center,
          Spacing.h30,
          const Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
