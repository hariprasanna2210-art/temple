import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/all_bookings.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/booking_details_card.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/debouncer.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';
import '../../../../utils/locator.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../models/all_bookings_filter.model.dart';

class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key, required this.filter});

  final AllBookingsFilters filter;

  static MaterialPageRoute<dynamic> route(AllBookingsFilters filters) => MaterialPageRoute(
    builder:
        (_) => BlocProvider(
          create: (context) => AllBookingsCubit(repository: locator<BookingsRepository>(), filters: filters),
          child: AllBookingsScreen(filter: filters),
        ),
  );

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  late final AllBookingsCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final Debouncer searchDebouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AllBookingsCubit>();
    _cubit.fetchInitialBookings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _cubit.fetchMoreBookings();
    }
  }

  Future<void> _onRefresh() => _cubit.refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'All Bookings', description: 'All Bookings'),
      body: BlocConsumer<AllBookingsCubit, AllBookingsState>(
        listener: (context, state) {
          if (state.status is AllBookingsStateError) {
            context.showSnackBar((state.status as AllBookingsStateError).message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Main content
              Expanded(
                child: state.status.when(
                  initial: () => const Center(child: CircularProgressIndicator()),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  loaded: () {
                    if (state.bookings.isEmpty) return EmptyStateMessage(message: 'No bookings found');
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: state.bookings.length + (_cubit.hasMore ? 1 : 0),
                        padding: const EdgeInsets.all(20),
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          if (index < state.bookings.length) {
                            return RepaintBoundary(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: BookingDetailsCard(
                                  key: ValueKey(state.bookings[index].id),
                                  booking: state.bookings[index],
                                ),
                              ),
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                        },
                      ),
                    );
                  },
                  error: (error) => Center(child: Text(error)),
                ),
              ),

              // Performance indicator
              if (state.status is AllBookingsStateLoaded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: Colors.grey.shade100,
                  child: Text(
                    'Loaded ${state.bookings.length} bookings${_cubit.hasMore ? ' (more available)' : ' (all loaded)'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
