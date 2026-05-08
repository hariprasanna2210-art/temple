import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/bloc/generate_customer_dive_logs.cubit.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/repository/customer_dive_logs.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/date_range_form_field.dart';

class GenerateCustomerDiveLogs extends StatefulWidget {
  const GenerateCustomerDiveLogs({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(
    builder:
        (_) => BlocProvider(
          create:
              (context) => GenerateCustomerDiveLogsCubit(
                repository: locator<CustomerDiveLogsRepository>(),
              ),
          child: const GenerateCustomerDiveLogs(),
        ),
  );

  @override
  State<GenerateCustomerDiveLogs> createState() => _GenerateCustomerDiveLogsState();
}

class _GenerateCustomerDiveLogsState extends State<GenerateCustomerDiveLogs> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _emailTED = TextEditingController();

  @override
  void dispose() {
    _emailTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Customer Dive Logs',
        description: 'Generate pdf for customer dive logs',
      ),
      body: BlocConsumer<GenerateCustomerDiveLogsCubit, GenerateCustomerDiveLogsState>(
        listener: (context, state) {
          if (state.status is GenerateCustomerDiveLogsSuccess) {
            context.showSnackBar('Successfully generated PDF');

            // Clear form after successful generation
            setState(() {
              _emailTED.clear();
              _startDate = null;
              _endDate = null;
            });
          } else if (state.status is GenerateCustomerDiveLogsError) {
            final errorMessage = (state.status as GenerateCustomerDiveLogsError).message;

            context.showSnackBar(errorMessage, backgroundColor: Colors.red);
          }
        },
        builder: (context, state) {
          final isLoading = state.status is GenerateCustomerDiveLogsLoading;

          return SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Spacing.h20,
                  DateRangeFormField(
                    title: 'Date Range (Optional)',
                    startDate: _startDate,
                    endDate: _endDate,
                    isRequired: false,
                    onDateSelected: (picked) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    },
                  ),
                  Spacing.h20,
                  AppTextField(
                    controller: _emailTED,
                    keyboardType: TextInputType.emailAddress,
                    labelText: 'Customer email *',
                    validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                  ),
                  const Spacer(),
                  AppButton.flat(
                    width: Screen.width,
                    text: 'Generate & Share PDF',
                    showLoading: isLoading,
                    onTap: _generatePdf,
                  ),
                ],
              ).paddingAll(20),
            ),
          );
        },
      ),
    );
  }

  void _generatePdf() {
    if (!_formKey.currentState!.validate()) return;

    context.closeKeyboard();

    // Call cubit to generate and share PDF
    context.read<GenerateCustomerDiveLogsCubit>().generateAndSharePdf(
      email: _emailTED.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );
  }
}
