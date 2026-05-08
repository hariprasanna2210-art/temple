import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/checklists/presentation/screens/checklist.screen.dart';
import 'package:temple_adventures_admin/utils/app_strings.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';

import '../../../../theme.dart';
import '../../../../utils/access_levels.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../checklists/bloc/all_templates.cubit.dart';
import '../../../checklists/presentation/screens/all_templates.screen.dart';
import '../../../user/enums/access_levels.enum.dart';
import '../../../user/presentation/screens/all_users.screen.dart';

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});

  static Route route() => MaterialPageRoute(
    builder: (context) => const OperationsScreen(),
    settings: const RouteSettings(name: 'OperationsScreen'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueColor,
      appBar: AppBar(
        title: const Text(AppStrings.operations),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccessLevelWidget(
                accessLevel: AccessLevels.viewUsers,
                child: _OperationCard(
                  title: AppStrings.addUsers,
                  subtitle: AppStrings.adminOnly,
                  icon: Icons.person_add_rounded,
                  onTap: () => Navigator.push(context, AllUsersScreen.route()),
                  buttonText: AppStrings.view,
                ),
              ),
              Spacing.h20,
              _ChecklistSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String buttonText;

  const _OperationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: aquaBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: softAqua.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: aquaBlue, size: 28),
          ),
          Spacing.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: black)),
                Text(subtitle, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: black.withOpacity(0.5))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllTemplatesCubit>().fetchTemplatesFromPrefs();
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: aquaBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: softAqua.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.checklist_rounded, color: aquaBlue, size: 20),
              ),
              Spacing.w12,
              const Text(AppStrings.checklists, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: black)),
            ],
          ),
          Spacing.h20,
          BlocBuilder<AllTemplatesCubit, AllTemplatesState>(
            builder: (context, state) {
              if (state.status is AllTemplatesLoading) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2)).paddingVertical(20);
              }

              if (state.selectedTemplates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No templates selected',
                    style: TextStyle(color: black.withOpacity(0.4), fontSize: 14),
                  ),
                );
              }

              return Column(
                children: state.selectedTemplates.map((template) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightBlueColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: black),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(context, ChecklistScreen.route(template: template)),
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: aquaBlue),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Spacing.h10,
          const Divider(),
          Spacing.h10,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.manageTemplates,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: black),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, AllTemplatesScreen.route()),
                child: const Text(AppStrings.manage, style: TextStyle(fontWeight: FontWeight.bold, color: aquaBlue)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
