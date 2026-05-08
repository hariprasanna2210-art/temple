import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/features/user/enums/gender.enum.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/screenshot_capture_fab.dart';

import '../../models/dsd_customer.model.dart';

class RosterChartScreen extends StatefulWidget {
  const RosterChartScreen({
    super.key,
    required this.selectedDate,
    required this.rosterData,
  });

  final DateTime selectedDate;
  final List<DSDCustomer> rosterData;

  // Original route for backward compatibility
  static MaterialPageRoute<dynamic> route({
    required DateTime selectedDate,
    required List<DSDCustomer> rosterData,
  }) {
    return MaterialPageRoute(
      builder:
          (_) => RosterChartScreen(
            selectedDate: selectedDate,
            rosterData: rosterData,
          ),
    );
  }

  @override
  State<RosterChartScreen> createState() => _RosterChartScreenState();
}

class _RosterChartScreenState extends State<RosterChartScreen> {
  final GlobalKey _tableKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Rotate to landscape mode when entering the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore portrait mode when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: ScreenshotCaptureFAB.singleWidget(
        captureKey: _tableKey,
        icon: Icons.share,
        text: 'Roster Chart - ${widget.selectedDate.formatDDMMYYYY}',
        fileName: 'roster_chart_${widget.selectedDate.formatDDMMYYYY}.png',
      ),
      body: SafeArea(
        child:
            (widget.rosterData.isNotEmpty)
                ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        _RosterTable(
                          screenShotKey: _tableKey,
                          selectedDate: widget.selectedDate,
                          rosterData: widget.rosterData,
                        ),
                        Positioned(
                          top: 0,
                          left: 10,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : const Center(
                  child: Text(
                    'No roster data available',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
      ),
    );
  }
}

class _RosterTable extends StatelessWidget {
  final GlobalKey screenShotKey;
  final DateTime selectedDate;
  final List<DSDCustomer> rosterData;

  const _RosterTable({required this.screenShotKey, required this.selectedDate, required this.rosterData});

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'Boat',
      'Booking ID',
      'Diver',
      'Gender',
      'Staff',
      'Time In',
      'Time Out',
      'Is Dive done',
      'Knows\nswimming',
      'Interested\nOWC',
      'Remarks',
    ];

    return RepaintBoundary(
      key: screenShotKey,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with date
            CustomTitle(
              title: selectedDate.formatDDMMYYYY,
              fontSize: 16,
            ),
            Spacing.h20,
            // Data table
            DataTable(
              columnSpacing: 30,
              horizontalMargin: 16,
              dividerThickness: 0,
              columns: titles.map((title) => DataColumn(label: CustomTitle(title: title, fontSize: 12))).toList(),
              rows: _generateRows(),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _generateRows() {
    // Make a list and filter invalid boats
    final sortedCustomers = rosterData.where((c) => c.boatName != null && c.boatName!.isNotEmpty).toList();

    // Sort the list
    sortedCustomers.sort((a, b) => (a.boatName ?? '').compareTo(b.boatName ?? ''));

    // Map to DataRow
    return sortedCustomers
        .map(
          (dsdCustomer) => DataRow(
            cells: [
              DataCell(Center(child: CustomTitle(title: dsdCustomer.boatName ?? '-', fontSize: 12))),
              DataCell(Center(child: CustomTitle(title: dsdCustomer.bookingId?.toString() ?? '-', fontSize: 12))),
              DataCell(Center(child: CustomTitle(title: dsdCustomer.fullName, fontSize: 12))),
              DataCell(Center(child: CustomTitle(title: dsdCustomer.gender?.label ?? '-', fontSize: 12))),
              DataCell(
                Center(child: CustomTitle(title: dsdCustomer.roster?.instructor?.fullName ?? '-', fontSize: 12)),
              ),
              DataCell(
                Center(child: CustomTitle(title: dsdCustomer.roster?.timeIn?.formatTimeOfDay ?? '-', fontSize: 12)),
              ),
              DataCell(
                Center(child: CustomTitle(title: dsdCustomer.roster?.timeOut?.formatTimeOfDay ?? '-', fontSize: 12)),
              ),
              DataCell(Center(child: CustomTitle(title: dsdCustomer.roster?.isDived.yesOrNo ?? '-', fontSize: 12))),
              DataCell(
                Center(
                  child: CustomTitle(
                    title: dsdCustomer.customerFeedback?.knowsSwimming.yesOrNo ?? '-',
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: CustomTitle(
                    title: dsdCustomer.customerFeedback?.interestedOwc.yesOrNo ?? '-',
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: CustomTitle(
                      title: dsdCustomer.customerFeedback?.feedback ?? '-',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .toList();
  }
}

extension _BoolX on bool? {
  String get yesOrNo {
    if (this == null) return '-';
    return this! ? 'Yes' : 'No';
  }
}
