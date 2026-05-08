import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/app_measurements.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/screenshot_capture_fab.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../models/template.model.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key, required this.template});

  final Template template;

  static Route route({required Template template}) => MaterialPageRoute(
    builder: (context) => ChecklistScreen(template: template),
  );

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  Template get template => widget.template;
  List<ItemModel> selectedItems = [];
  final GlobalKey widgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Checklist',
        description: 'Checklist screen',
        action: IconButton(
          onPressed: () {
            setState(() {
              selectedItems = [];
            });
          },
          icon: Icon(Icons.refresh),
        ).paddingOnly(right: 5),
      ),
      floatingActionButton: ScreenshotCaptureFAB.singleWidget(
        captureKey: widgetKey,
        heroTag: "checklist_screenshot_fab",
        icon: Icons.share,
      ),
      body: SafeArea(
        child:
            Column(
              children: [
                RepaintBoundary(
                  key: widgetKey,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacing.h10,
                        CustomTitle(
                          title: template.title,
                          fontWeight: FontWeight.w600,
                        ),
                        Spacing.h20,
                        ...template.items.map((item) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (selectedItems.contains(item)) {
                                  selectedItems.remove(item);
                                } else {
                                  selectedItems.add(item);
                                }
                              });
                            },
                            child: Container(
                              width: Screen.width,
                              decoration: BoxDecoration(
                                color: (selectedItems.contains(item)) ? lightSkyBlue : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                children: [
                                  Text(item.name).paddingOnly(left: 15, top: 8, bottom: 8),
                                  const Spacer(),
                                  Icon(
                                    (selectedItems.contains(item))
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank_rounded,
                                    size: 16,
                                  ),
                                  Spacing.w8,
                                ],
                              ),
                            ),
                          ).paddingVertical(8);
                        }),
                        Spacing.h50,
                      ],
                    ).paddingAll(20),
                  ),
                ),
              ],
            ).scrollable,
      ),
    );
  }
}
