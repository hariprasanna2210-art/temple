import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/coast_guard_slip/bloc/coast_guard_slip.cubit.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/widgets/date_selector.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';

class CoastGuardSlipScreen extends StatelessWidget {
  const CoastGuardSlipScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const CoastGuardSlipScreen());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => CoastGuardSlipCubit(
            bookingsRepository: locator<BookingsRepository>(),
            boatsRepository: locator<BoatsRepository>(),
          )..selectDate(DateTime.now()),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Coast Guard Slip',
          description: '',
        ),
        body: SafeArea(
          child: BlocConsumer<CoastGuardSlipCubit, CoastGuardSlipState>(
            listener: (context, state) {
              final status = state.status;
              if (status is CoastGuardSlipSuccess) {
                context.showSnackBar('PDF generated successfully!');
              } else if (status is CoastGuardSlipError) {
                context.showSnackBar(status.message, backgroundColor: Colors.red);
              }
            },
            builder: (context, state) {
              if (state.status is CoastGuardSlipLoading) {
                return const LoadingOverlay();
              }

              return Column(
                children: [
                  DateSelector(
                    selectedDate: state.selectedDate ?? DateTime.now(),
                    onDateChange: (date) => context.read<CoastGuardSlipCubit>().selectDate(date),
                  ),
                  Spacing.h20,
                  (state.boats.isEmpty || state.bookingsByBoat.isEmpty)
                      ? EmptyStateMessage(
                        message: "No boats found for the selected date",
                      )
                      : const _GenerateActions(),
                ],
              ).paddingAll(20);
            },
          ),
        ),
      ),
    );
  }
}

/// Generate Buttons
class _GenerateActions extends StatelessWidget {
  const _GenerateActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoastGuardSlipCubit, CoastGuardSlipState>(
      builder: (context, state) {
        final cubit = context.read<CoastGuardSlipCubit>();
        final isWorking = state.status is CoastGuardSlipGenerating;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton.flat(
              width: 200,
              text: isWorking ? 'Generating Slip...' : 'Generate Slip',
              showLoading: isWorking,
              onTap: isWorking ? () {} : () => cubit.generateAndSharePdf(),
            ),
            Spacing.h20,
            AppButton.flat(
              width: 200,
              text: isWorking ? 'Generating Proofs...' : 'Generate ID Proofs',
              showLoading: isWorking,
              onTap: isWorking ? () {} : () => cubit.generateAndShareIdProofsPdf(),
            ),
          ],
        );
      },
    );
  }
}
