import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/checklists/presentation/screens/checklist.screen.dart';
import 'package:temple_adventures_admin/utils/access_levels.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';

import '../../../../theme.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/nav_drawer.dart';
import '../../../checklists/bloc/all_templates.cubit.dart';
import '../../../checklists/presentation/screens/all_templates.screen.dart';
import '../../../user/enums/access_levels.enum.dart';
import '../../../user/presentation/screens/all_users.screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Route route() => MaterialPageRoute(builder: (context) => const HomeScreen());

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const NavDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacing.h20,
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu_rounded),
            ),
            Spacing.h20,
            AccessLevelWidget(accessLevel: AccessLevels.viewUsers, child: _AddUserWidget()),
            Spacing.h20,
            _ChecklistWidget(),
          ],
        ).paddingSymmetric(horizontal: 20).scrollable,
      ),
    );
  }
}

class _AddUserWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: Screen.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Users',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'Only admins can modify',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          AppButton.miniFlat(onTap: () => Navigator.push(context, AllUsersScreen.route()), text: 'View'),
        ],
      ).paddingAll(20),
    );
  }
}

class _ChecklistWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllTemplatesCubit>().fetchTemplatesFromPrefs();
    });

    return Container(
      width: Screen.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checklists',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Spacing.h15,
            BlocBuilder<AllTemplatesCubit, AllTemplatesState>(
              builder: (context, state) {
                if (state.status is AllTemplatesLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ).size(20, 20),
                  ).paddingVertical(10);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: state.selectedTemplates.map((template) {
                    return KeyValuePair(
                      title: template.title,
                      widget: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            ChecklistScreen.route(template: template),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: skyBlueColor,
                        ),
                      ).right,
                    );
                  }).toList(),
                );
              },
            ),
            Spacing.h10,
            KeyValuePair(
              title: 'Manage Templates',
              widget: AppButton.miniFlat(
                text: 'Manage',
                onTap: () {
                  Navigator.push(context, AllTemplatesScreen.route());
                },
              ).right,
            ),
          ],
        ),
      ),
    );
  }
}
