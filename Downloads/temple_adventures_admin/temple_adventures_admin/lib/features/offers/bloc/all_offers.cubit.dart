import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../services/logging.dart';
import '../models/offer.model.dart';
import '../repository/offers.repository.dart';

part 'all_offers.cubit.freezed.dart';
part 'all_offers.cubit.mapper.dart';

class AllOffersCubit extends Cubit<AllOffersState> {
  final OffersRepository repository;

  AllOffersCubit({required this.repository}) : super(const AllOffersState(status: AllOffersStatus.initial()));

  Future<void> fetchOffers() async {
    try {
      emit(state.copyWith(status: AllOffersStatus.loading()));
      final offers = await repository.fetchAllOffers();
      emit(state.copyWith(status: AllOffersStatus.success(offers)));
    } catch (e, stack) {
      Log.e('Error fetching offers: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllOffersStatus.error(e.toString())));
    }
  }


}

@immutable
@MappableClass()
class AllOffersState with AllOffersStateMappable {
  final AllOffersStatus status;

  const AllOffersState({required this.status});
}

@freezed
class AllOffersStatus with _$AllOffersStatus {
  const factory AllOffersStatus.initial() = AllOffersInitial;
  const factory AllOffersStatus.loading() = AllOffersLoading;
  const factory AllOffersStatus.success(List<Offer> offers) = AllOffersSuccess;
  const factory AllOffersStatus.error(String message) = AllOffersError;
}
