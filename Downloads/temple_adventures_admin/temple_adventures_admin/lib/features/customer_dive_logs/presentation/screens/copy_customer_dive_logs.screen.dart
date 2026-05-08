import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/bloc/copy_customer_dive_logs.cubit.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/models/customer_dive_log.model.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/date_range_form_field.dart';
import '../../repository/customer_dive_logs.repository.dart';

class CopyCustomerDiveLogsScreen extends StatefulWidget {
  const CopyCustomerDiveLogsScreen({
    super.key,
    required this.customers,
    required this.diveLogs,
  });

  final List<Customer> customers;
  final List<CustomerDiveLog> diveLogs;

  static MaterialPageRoute<dynamic> route({
    required List<Customer> customers,
    required List<CustomerDiveLog> diveLogs,
  }) => MaterialPageRoute(
    builder:
        (_) => BlocProvider(
          create:
              (context) => CopyCustomerDiveLogsCubit(
                repository: locator<CustomerDiveLogsRepository>(),
              ),
          child: CopyCustomerDiveLogsScreen(
            customers: customers,
            diveLogs: diveLogs,
          ),
        ),
  );

  @override
  State<CopyCustomerDiveLogsScreen> createState() => _CopyCustomerDiveLogsScreenState();
}

class _CopyCustomerDiveLogsScreenState extends State<CopyCustomerDiveLogsScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Customer> allCustomers = [];
  DateTime? _startDate;
  DateTime? _endDate;
  TextEditingController copyFromTED = TextEditingController();
  TextEditingController copyToTED = TextEditingController();

  @override
  void initState() {
    super.initState();
    allCustomers = widget.customers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Copy Dive Logs', description: 'Copy customer dive logs'),
      body: BlocConsumer<CopyCustomerDiveLogsCubit, CopyCustomerDiveLogsState>(
        listener: (context, state) {
          if (state.status is CopyCustomerDiveLogsSuccess) {
            context.showSnackBar('Successfully copied dive logs');
            Navigator.pop(context);
          } else if (state.status is CopyCustomerDiveLogsError) {
            final errorMessage = (state.status as CopyCustomerDiveLogsError).message;
            context.showSnackBar(errorMessage, backgroundColor: Colors.red);
          }
        },
        builder: (context, state) {
          final isLoading = state.status is CopyCustomerDiveLogsLoading;

          return SafeArea(
            child: Container(
              width: Screen.width,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  topLeft: Radius.circular(16),
                ),
                color: lightBlueColor,
              ),
              child: Form(
                key: _formKey,
                child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacing.h30,
                        DateRangeFormField(
                          title: 'Select Dates *',
                          startDate: _startDate,
                          endDate: _endDate,
                          onDateSelected: (picked) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                            });
                          },
                        ),
                        Spacing.h20,
                        ...allCustomers.map((customer) {
                          return KeyValuePair(
                            title: customer.email ?? '',
                            widget:
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  tooltip: 'Copy email',
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: customer.email!));
                                  },
                                ).right,
                          );
                        }),
                        Spacing.h20,
                        AppTextField(
                          controller: copyFromTED,
                          labelText: 'Copy from email *',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                        ),
                        Spacing.h20,
                        AppTextField(
                          controller: copyToTED,
                          labelText: 'Copy to email *',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                        ),
                        Spacing.h100,
                        AppButton.flat(
                          width: Screen.width,
                          text: 'Copy Logs',
                          showLoading: isLoading,
                          onTap: _copyLogs,
                        ),
                      ],
                    ).paddingSymmetric(horizontal: 20).scrollable,
              ),
            ),
          );
        },
      ),
    );
  }

  void _copyLogs() {
    if (!_formKey.currentState!.validate()) return;

    // Call cubit to copy logs
    context.read<CopyCustomerDiveLogsCubit>().copyLogs(
      context,
      allCustomers: allCustomers,
      allDiveLogs: widget.diveLogs,
      copyFromEmail: copyFromTED.text.toLowerCase().trim(),
      copyToEmail: copyToTED.text.toLowerCase().trim(),
      startDate: _startDate!,
      endDate: _endDate!,
    );
  }
}
