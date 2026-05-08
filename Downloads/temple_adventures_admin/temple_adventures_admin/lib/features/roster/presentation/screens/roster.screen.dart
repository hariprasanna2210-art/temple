import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/roster/models/dsd_customer.model.dart';
import 'package:temple_adventures_admin/features/roster/presentation/screens/roster_chart.screen.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../theme.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/date_selector.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../../../widgets/loading_overlay.dart';
import '../../../boats/models/boats.model.dart';
import '../../bloc/roster.cubit.dart';
import '../widgets/customer_list_tile.dart';
import 'add_edit_roster.screen.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  static MaterialPageRoute<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const RosterScreen());
  }

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  late final RosterCubit _rosterCubit;

  @override
  void initState() {
    super.initState();
    // Save a reference to the cubit while the context is still active
    _rosterCubit = context.read<RosterCubit>();
    
    // Fetch data when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentDate = _rosterCubit.state.selectedDate ?? DateTime.now();
      _rosterCubit.selectDate(currentDate);
    });
  }

  @override
  void dispose() {
    // Safe to call because we stored it before
    _rosterCubit.selectDate(DateTime.now());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Roster',
        description: 'Fill roster for the selected date',
      ),
      body: SafeArea(
        child: BlocBuilder<RosterCubit, RosterState>(
          buildWhen: (prev, curr) => prev.status != curr.status,
          builder: (context, state) {
            final isLoading = state.status is RosterLoading;
            return Stack(
              children: [
                Column(
                  children: [
                    Spacing.h20,
                    DateSelector(
                      selectedDate: state.selectedDate ?? DateTime.now(),
                      onDateChange: (newDate) => context.read<RosterCubit>().selectDate(newDate),
                    ).paddingOnly(right: 10),
                    Spacing.h30,
                    _BoatSection(state: state),
                  ],
                ).scrollable,
                if (isLoading) const LoadingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BoatSection extends StatelessWidget {
  final RosterState state;

  const _BoatSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.boats.isEmpty) {
      return const EmptyStateMessage(
        message: 'No boats are available for the selected date',
      );
    }

    return Column(
      children: [
        BlocSelector<RosterCubit, RosterState, (Boat?, List<Boat>)>(
          selector: (state) => (state.selectedBoat, state.boats),
          builder: (context, boatState) {
            final boats = boatState.$2;
            final selectedBoat = boatState.$1;

            return Wrap(
              runSpacing: 15,
              spacing: 15,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () async {
                      // Navigate to chart screen with roster data
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          RosterChartScreen.route(
                            selectedDate: state.selectedDate!,
                            rosterData: state.customers,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.insert_chart),
                  ),
                ),
                ...boats.map(
                  (boat) {
                    final isSelected = boat.id == selectedBoat?.id;
                    return GestureDetector(
                      onTap: () => context.read<RosterCubit>().selectBoat(boat),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? lightSkyBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          boat.name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ).paddingAll(10),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        Spacing.h30,
        _BookingsSection(
          selectedDate: state.selectedDate!,
          customers: state.customers,
        ),
      ],
    );
  }
}

class _BookingsSection extends StatelessWidget {
  final List<DSDCustomer> customers;
  final DateTime selectedDate;

  const _BookingsSection({
    required this.customers,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RosterCubit, RosterState, Boat?>(
      selector: (state) => state.selectedBoat,
      builder: (context, selectedBoat) {
        if (selectedBoat == null) return const SizedBox.shrink();

        //  Filter customers by selected boat
        final filteredCustomers = customers.where((customer) => customer.boatId == selectedBoat.id).toList();

        //  Show empty message if none match
        if (filteredCustomers.isEmpty) {
          return const EmptyStateMessage(
            message: 'No DSD bookings found for the selected boat',
          ).paddingSymmetric(horizontal: 20);
        }

        // Show list of customers
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              filteredCustomers
                  .map(
                    (roster) => CustomerListTile(
                      customer: roster,
                      onTap: () {
                        Navigator.push(
                          context,
                          AddEditRosterScreen.route(
                            instructors: selectedBoat.dsdInstructors ?? [],
                            customer: roster,
                            selectedDate: selectedDate,
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
        ).paddingSymmetric(horizontal: 20);
      },
    );
  }
}
