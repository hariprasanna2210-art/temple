import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';

import '../../../services/logging.dart';
import '../models/all_bookings_filter.model.dart';
import '../models/booking.model.dart';

part 'all_bookings.cubit.freezed.dart';
part 'all_bookings.cubit.mapper.dart';

class AllBookingsCubit extends Cubit<AllBookingsState> {
  final BookingsRepository repository;
  final AllBookingsFilters filters;

  AllBookingsCubit({required this.repository, required this.filters})
      : super(AllBookingsState(status: AllBookingsStateStatus.initial(), bookings: [], filters: filters));

  static const int pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Future<void> fetchInitialBookings() async {
    emit(state.copyWith(status: AllBookingsStateStatus.loading()));
    try {
      final bookings = await repository.fetchPaginatedBookings(
        limit: pageSize,
        offset: 0,
        filters: state.filters,
      );
      _page = 1;
      _hasMore = bookings.length == pageSize;
      emit(state.copyWith(bookings: bookings, status: AllBookingsStateStatus.loaded()));
    } catch (e, stack) {
      Log.e('Error loading bookings', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllBookingsStateStatus.error(e.toString())));
    }
  }

  Future<void> fetchMoreBookings() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;

    try {
      final newBookings = await repository.fetchPaginatedBookings(
        limit: pageSize,
        offset: _page * pageSize,
        filters: state.filters,
      );
      _page++;
      _hasMore = newBookings.length == pageSize;
      emit(state.copyWith(bookings: [...state.bookings, ...newBookings]));
    } catch (e, stack) {
      Log.e('Error loading more bookings', error: e, stackTrace: stack);
    }

    _isLoadingMore = false;
  }

  Future<void> refresh() async {
    _page = 0;
    _hasMore = true;
    await fetchInitialBookings();
  }

  bool get hasMore => _hasMore;
}

@immutable
@MappableClass()
class AllBookingsState with AllBookingsStateMappable {
  final AllBookingsStateStatus status;
  final List<Booking> bookings;
  final AllBookingsFilters filters;

  const AllBookingsState({
    required this.status,
    required this.bookings,
    required this.filters,
  });
}

@freezed
abstract class AllBookingsStateStatus with _$AllBookingsStateStatus {
  const factory AllBookingsStateStatus.initial() = AllBookingsStateInitial;
  const factory AllBookingsStateStatus.loading() = AllBookingsStateLoading;
  const factory AllBookingsStateStatus.loaded() = AllBookingsStateLoaded;
  const factory AllBookingsStateStatus.error(String message) = AllBookingsStateError;
}
