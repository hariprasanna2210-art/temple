import 'dart:io';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/mixins/status_bar_handler_mixin.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_image.dart';
import '../../../boats/presentation/screens/boats.screen.dart';
import '../../../bookings/presentation/screens/bookings.screen.dart';
import '../../../conditions/presentation/screens/conditions.screen.dart';
import '../../../home/presentation/screens/home.screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(
    builder: (_) => const DashboardScreen(),
    settings: const RouteSettings(name: 'DashboardScreen'),
  );

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware, StatusBarHandlerMixin<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(), // disable swipe if needed
          children: [HomeScreen(), BoatsScreen(), BookingsScreen(), ConditionsScreen()],
        ),
        bottomNavigationBar: SafeArea(
          child: ColoredBox(
            color: Colors.black,
            child: TabBar(
              indicatorColor: Colors.transparent,
              tabs: [
                _buildTab(context, 'assets/images/home_white.png', 'assets/images/home_black.png', 0),
                _buildTab(context, 'assets/images/boat_white.png', 'assets/images/boat_black.png', 1),
                _buildTab(context, 'assets/images/booking_white.png', 'assets/images/booking_black.png', 2),
                _buildTab(context, 'assets/images/condition_white.png', 'assets/images/condition_black.png', 3),
              ],
            ).paddingOnly(bottom: Platform.isIOS ? 20 : 0),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String whiteIcon, String blackIcon, int tabIndex) {
    return Builder(
      builder: (context) {
        final TabController controller = DefaultTabController.of(context);
        final bool isSelected = controller.index == tabIndex;

        controller.addListener(() {
          (context as Element).markNeedsBuild();
        });

        return Tab(
          icon: Container(
            height: 30,
            width: 30,
            decoration: isSelected ? const BoxDecoration(shape: BoxShape.circle, color: Colors.white) : null,
            child: AppImage(isSelected ? blackIcon : whiteIcon).center,
          ),
        );
      },
    );
  }
}
