import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/checklists/models/template.model.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../../bookings/presentation/widgets/custom_title.dart';
import '../../bloc/all_templates.cubit.dart';
import 'add_edit_template.screen.dart';

class AllTemplatesScreen extends StatefulWidget {
  const AllTemplatesScreen({super.key});

  static Route route() => MaterialPageRoute(
    builder: (context) => const AllTemplatesScreen(),
  );

  @override
  State<AllTemplatesScreen> createState() => _AllTemplatesScreenState();
}

class _AllTemplatesScreenState extends State<AllTemplatesScreen> {
  List<Template> templates = [];

  @override
  void initState() {
    super.initState();
    context.read<AllTemplatesCubit>().fetchTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AllTemplatesCubit, AllTemplatesState>(
      listener: (context, state) {
        final status = state.status;

        if (status is AllTemplatesLoaded) {
          templates = status.templates;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'All Templates',
            description: 'All templates / Create custom templates',
            action: IconButton(
              onPressed: () {
                Navigator.push(context, AddEditTemplateScreen.route());
              },
              icon: Icon(Icons.add_circle_outline_rounded),
            ).paddingOnly(right: 5),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (templates.isEmpty && state.status is! AllTemplatesLoading)
                      EmptyStateMessage(
                        message: 'No Templates found',
                      ).center,
                    ...templates.map((template) {
                      final isSelected = state.selectedTemplates.contains(template);

                      return _TitleWithArrow(
                        title: template.title,
                        buttonText: isSelected ? 'On Home' : 'Home',
                        buttonColor: isSelected ? Colors.green : lightSkyBlue,
                        isSelected: isSelected,
                        onPressed: () {
                          Navigator.push(context, AddEditTemplateScreen.route(template: template));
                        },
                        onSelectPressed: () {
                          final cubit = context.read<AllTemplatesCubit>();

                          if (isSelected) {
                            cubit.deleteCheckListFromHome(template.id!);
                          } else {
                            cubit.addCheckListToHome(template.id!);
                          }
                        },
                      );
                    }),
                  ],
                ).paddingAll(20),
                if (state.status is AllTemplatesLoading) LoadingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TitleWithArrow extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final VoidCallback onSelectPressed;
  final String buttonText;
  final Color buttonColor;
  final bool isSelected;

  const _TitleWithArrow({
    required this.title,
    required this.onPressed,
    required this.onSelectPressed,
    required this.buttonText,
    required this.buttonColor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onPressed,
            child: CustomTitle(
              title: title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        InkWell(
          onTap: onSelectPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: buttonColor,
            ),
            child: Row(
              children: [
                if (!isSelected) Icon(Icons.add, size: 14),
                Spacing.w5,
                CustomTitle(
                  title: buttonText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                Spacing.w5,
              ],
            ).paddingAll(5),
          ),
        ),
      ],
    ).paddingOnly(bottom: 15);
  }
}
