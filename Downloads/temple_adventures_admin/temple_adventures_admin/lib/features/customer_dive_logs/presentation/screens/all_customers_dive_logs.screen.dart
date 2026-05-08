import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/presentation/screens/copy_customer_dive_logs.screen.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../../../widgets/loading_overlay.dart';
import '../../../bookings/models/booking.model.dart';
import '../../../bookings/models/customer.model.dart';
import '../../../bookings/presentation/widgets/custom_title.dart';
import '../../bloc/all_customers_dive_logs.cubit.dart';
import '../../models/customer_dive_log.model.dart';
import 'add_edit_customer_dive_log.screen.dart';

class AllCustomersDiveLogsScreen extends StatefulWidget {
  const AllCustomersDiveLogsScreen({
    super.key,
    required this.customers,
    required this.booking,
  });

  final List<Customer> customers;
  final Booking booking;

  static MaterialPageRoute<dynamic> route({
    required List<Customer> customers,
    required Booking booking,
  }) => MaterialPageRoute(
    builder:
        (_) => AllCustomersDiveLogsScreen(
          customers: customers,
          booking: booking,
        ),
  );

  @override
  State<AllCustomersDiveLogsScreen> createState() => _AllCustomersDiveLogsScreenState();
}

class _AllCustomersDiveLogsScreenState extends State<AllCustomersDiveLogsScreen> {
  late final List<Customer> allCustomers = widget.customers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogs();
    });
  }

  void _fetchLogs() {
    context.read<AllCustomersDiveLogsCubit>().fetchAllCustomersDiveLogs(
      customers: allCustomers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Customer Dive Logs',
        description: 'All customer dive logs',
      ),
      body: SafeArea(
        child: BlocBuilder<AllCustomersDiveLogsCubit, AllCustomersDiveLogsState>(
          builder: (context, state) {
            final status = state.status;

            if (status is AllCustomersDiveLogsLoading || status is AllCustomersDiveLogsInitial) {
              return const LoadingOverlay();
            }

            if (status is AllCustomersDiveLogsError) {
              return EmptyStateMessage(message: status.message);
            }

            if (status is AllCustomersDiveLogsSuccess) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CustomerDiveLogsList(
                    customers: allCustomers,
                    diveLogs: state.allDivLogs,
                    booking: widget.booking,
                  ),
                  Spacing.h30,
                  AppButton.miniFlat(
                    text: 'Copy Logs',
                    onTap: () {
                      Navigator.push(
                        context,
                        CopyCustomerDiveLogsScreen.route(
                          customers: allCustomers,
                          diveLogs: state.allDivLogs,
                        ),
                      );
                    },
                  ),
                  Spacing.h30,
                ],
              ).paddingAll(20).scrollable;
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _CustomerDiveLogsList extends StatelessWidget {
  const _CustomerDiveLogsList({
    required this.customers,
    required this.diveLogs,
    required this.booking,
  });

  final List<Customer> customers;
  final List<CustomerDiveLog> diveLogs;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...[
          ...customers.map((customer) {
            final logs =
                (diveLogs.where((log) => log.customer.id == customer.id).toList()
                  ..sort((a, b) => b.diveDate.compareTo(a.diveDate)));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomerHeaderRow(
                  customer: customer,
                  booking: booking,
                ),
                Spacing.h10,
                logs.isEmpty
                    ? CustomTitle(
                      title: 'No logs found',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ).center
                    : _CustomerLogsTable(
                      logs: logs,
                      customer: customer,
                      booking: booking,
                    ),
              ],
            ).paddingOnly(bottom: 25);
          }),
        ],
      ],
    );
  }
}

class _CustomerHeaderRow extends StatelessWidget {
  const _CustomerHeaderRow({
    required this.customer,
    required this.booking,
  });

  final Customer customer;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTitle(
            title: customer.fullName,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (customer.email != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy email',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: customer.email!));
            },
          ),
        AppButton.miniFlat(
          text: 'Add Log',
          onTap: () {
            Navigator.push(
              context,
              AddEditCustomerDiveLogScreen.route(
                customer: customer,
                booking: booking,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CustomerLogsTable extends StatelessWidget {
  const _CustomerLogsTable({
    required this.logs,
    required this.customer,
    required this.booking,
  });

  final List<CustomerDiveLog> logs;
  final Customer customer;
  final Booking booking;

  TextStyle get _headerStyle => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  TextStyle get _cellStyle => const TextStyle(
    fontSize: 11,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 0,
        headingRowHeight: 40,
        dataRowMinHeight: 35,
        dataRowMaxHeight: 35,
        dividerThickness: 0.5,
        columns: [
          DataColumn(label: Text('Date', style: _headerStyle)),
          DataColumn(label: Text('Instructor', style: _headerStyle)),
          DataColumn(label: Text('Course', style: _headerStyle)),
          DataColumn(label: Text('Dive Site', style: _headerStyle)),
          DataColumn(label: Text('Tank\nNo', style: _headerStyle)),
          DataColumn(label: Text('Bottom\nTime', style: _headerStyle)),
          DataColumn(label: Text('Max\nDepth', style: _headerStyle)),
          DataColumn(label: Text('Time\nIn', style: _headerStyle)),
          DataColumn(label: Text('Pressure', style: _headerStyle)),
          const DataColumn(label: Text('')), // edit icon
        ],
        rows:
            logs.map((log) {
              return DataRow(
                cells: [
                  DataCell(Text(log.diveDate.formatDDMMYYYY, style: _cellStyle)),
                  DataCell(Text(log.instructor.fullName, style: _cellStyle)),
                  DataCell(Text(booking.activity.shortName, style: _cellStyle)),
                  DataCell(Text(log.diveSite, style: _cellStyle)),
                  DataCell(Text('${log.tankType[0]}-${log.tankNo}', style: _cellStyle)),
                  DataCell(Text('${log.bottomTime} mins', style: _cellStyle)),
                  DataCell(Text('${log.maxDepth} m', style: _cellStyle)),
                  DataCell(Text(log.diveDate.formatHHMM, style: _cellStyle)),
                  DataCell(Text('${log.pressure} bar', style: _cellStyle)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Edit Log',
                      onPressed: () {
                        Navigator.push(
                          context,
                          AddEditCustomerDiveLogScreen.route(
                            customer: customer,
                            customerDiveLog: log,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
