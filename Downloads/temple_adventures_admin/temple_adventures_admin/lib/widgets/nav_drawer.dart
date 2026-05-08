import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:temple_adventures_admin/features/coast_guard_slip/presentation/screens/coast_guard_slip.screen.dart';
import 'package:temple_adventures_admin/features/equipment/presentation/screens/all_equiment.screen.dart';
import 'package:temple_adventures_admin/features/equipment/presentation/screens/equipment_log.screen.dart';
import 'package:temple_adventures_admin/features/events/presentation/screens/all_events.screen.dart';
import 'package:temple_adventures_admin/features/general_info/presentation/screens/general_info.screen.dart';
import 'package:temple_adventures_admin/features/logs/presentation/all_logs.screen.dart';
import 'package:temple_adventures_admin/features/user/models/user.model.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../features/activities/presentation/screens/all_activities.screen.dart';
import '../features/boats/presentation/screens/board_plan.screen.dart';
import '../features/bookings/presentation/screens/all_bookings_filters.screen.dart';
import '../features/customer_dive_logs/presentation/screens/generate_customer_dive_logs.screen.dart';
import '../features/dive_sites/presentation/screens/map.screen.dart';
import '../features/login/presentation/screens/login.screen.dart';
import '../features/offers/presentation/screens/all_offers.screen.dart';
import '../features/roster/presentation/screens/roster.screen.dart';
import '../features/user/bloc/user.cubit.dart';
import '../features/user/enums/access_levels.enum.dart';
import '../features/user/presentation/screens/user_profile.screen.dart';
import '../services/ota_service.dart';
import '../services/shared_preference_service.dart';
import '../utils/access_levels.dart';
import '../utils/constants.dart';
import '../utils/styling/app_measurements.dart';
import '../utils/styling/spacing_widgets.dart';
import 'app_image.dart';
import 'custom_alert_dialog.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({super.key});

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final version = await OTAService(ShorebirdUpdater()).getAppCombinedVersion();
    if (mounted) {
      setState(() {
        _appVersion = version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child:
          Column(
            children: [
              Spacing.h100,
              AppImage(appLogo, height: 100, width: 100),
              Spacing.h20,
              _UserInfo(),
              Spacing.h30,
              const _DividerLine(),
              Spacing.h10,
              ...[
                _MenuListTile(
                  icon: Icons.account_circle,
                  text: "Profile",
                  onTap: () => Navigator.push(context, UserProfileScreen.route()),
                ),
                _MenuListTile(
                  icon: Icons.navigation_rounded,
                  text: "Dive Site Navigation",
                  onTap: () => Navigator.push(context, MapScreen.route()),
                ),
                _MenuListTile(
                  icon: Icons.content_paste,
                  text: "Board Plan",
                  onTap: () {
                    Navigator.push(context, BoardPlanScreen.route());
                  },
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.generalInfo,
                  child: _MenuListTile(
                    icon: Icons.scuba_diving_rounded,
                    text: "General Info",
                    onTap: () => Navigator.push(context, GeneralInfoScreen.route()),
                  ),
                ),
                _MenuListTile(
                  icon: Icons.dataset_rounded,
                  text: "Equipment",
                  onTap: () => Navigator.push(context, AllEquipmentScreen.route()),
                ),
                _MenuListTile(
                  icon: Icons.list_alt_outlined,
                  text: "Equipment Logs",
                  onTap: () => Navigator.push(context, EquipmentLogScreen.route()),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.roster,
                  child: _MenuListTile(
                    icon: Icons.add_card_rounded,
                    text: "Roster",
                    onTap: () {
                      Navigator.push(context, RosterScreen.route());
                    },
                  ),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.coastGuardSlip,
                  child: _MenuListTile(
                    icon: Icons.directions_boat,
                    text: "Coast Guard Slip",
                    onTap: () {
                      Navigator.push(context, CoastGuardSlipScreen.route());
                    },
                  ),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.customerDiveLogs,
                  child: _MenuListTile(
                    icon: Icons.collections_bookmark_rounded,
                    text: "Customer Dive Logs",
                    onTap: () {
                      Navigator.push(context, GenerateCustomerDiveLogs.route());
                    },
                  ),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.offers,
                  child: _MenuListTile(
                    icon: Icons.percent,
                    text: "Offers",
                    onTap: () => Navigator.push(context, AllOfferScreen.route()),
                  ),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.upcomingEvents,
                  child: _MenuListTile(
                    icon: Icons.event_rounded,
                    text: "Upcoming Events",
                    onTap: () => Navigator.push(context, AllEventsScreen.route()),
                  ),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.viewActivities,
                  child: _MenuListTile(
                    icon: Icons.edit,
                    text: "Programs List",
                    onTap: () => Navigator.push(context, AllActivitiesScreen.route()),
                  ),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.viewAllBookings,
                  child: _MenuListTile(
                    icon: Icons.add_to_photos_sharp,
                    text: "All Bookings",
                    onTap: () => Navigator.push(context, AllBookingsFiltersScreen.route()),
                  ),
                ),
                AccessLevelWidget(
                  accessLevel: AccessLevels.logs,
                  child: _MenuListTile(
                    icon: Icons.book_rounded,
                    text: "Logs",
                    onTap: () => Navigator.push(context, AllLogsScreen.route()),
                  ),
                ),
                _MenuListTile(
                  icon: Icons.logout,
                  text: "Logout",
                  onTap: () async {
                    final shouldLogout = await CustomAlertDialog.show(
                      context,
                      title: 'Are you sure?',
                      content: 'Do you want to log out?',
                    );
                    if (shouldLogout == true) {
                      await SharedPrefKeys.userId.clearDatabase();
                      await FirebaseAuth.instance.signOut();
                      // Small delay to ensure signOut completes
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(LoginScreen.route(), (route) {
                          return false;
                        });
                      }
                    }
                  },
                ),
              ],
              const _DividerLine(),
              _FooterText(text: "Version : ${_appVersion.isEmpty ? 'Loading...' : _appVersion}"),
              const _FooterText(text: "https://templeadventures.com/"),
              Spacing.h20,
            ],
          ).scrollable,
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserCubit, UserState, User?>(
      selector: (state) => state.currentUser,
      builder: (context, user) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Hello,',
              style: TextStyle(color: Colors.black45, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.2),
            ),
            Spacing.h10,
            Text(
              user?.firstName ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.2),
            ),
          ],
        );
      },
    );
  }
}

class _MenuListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _MenuListTile({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Screen.width,
      alignment: Alignment.centerLeft,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 30),
        title: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Color(0xff605B5B), fontWeight: FontWeight.w500),
        ),
        leading: Icon(icon, color: Colors.black87),
        onTap: onTap,
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  final String text;

  const _FooterText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(color: Colors.black45, fontSize: 12)),
    ).paddingOnly(left: 30, top: 15);
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(width: Screen.width, height: 1, color: Colors.grey[300]).paddingSymmetric(horizontal: 20);
  }
}
