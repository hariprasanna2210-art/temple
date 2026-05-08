import 'dart:io';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../services/logging.dart';
import '../models/offer.model.dart';
import '../repository/offers.repository.dart';

part 'add_edit_offer.cubit.freezed.dart';
part 'add_edit_offer.cubit.mapper.dart';

class AddEditOfferCubit extends Cubit<AddEditOfferState> {
  final OffersRepository repository;

  AddEditOfferCubit({required this.repository}) : super(const AddEditOfferState(status: AddEditOfferStatus.initial()));

  Future<void> onSubmit({
    required Offer offer,
  }) async {
    try {
      emit(state.copyWith(status: AddEditOfferStatus.submitLoading()));
      await repository.addUpdateOffer(offer: offer);
      emit(state.copyWith(status: AddEditOfferStatus.success(true)));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditOfferStatus.error(e.toString())));
    }
  }

  Future<String?> uploadImage(File? imageFile) async {
    try {
      if (imageFile == null) {
        throw Exception('The image file is not found ');
      }
      emit(state.copyWith(status: AddEditOfferStatus.uploadLoading()));

      final url = await repository.uploadImage(imageFile);
      if (url == null) throw Exception('Upload failed');
      emit(state.copyWith(status: AddEditOfferStatus.success(false)));
      return url;
    } catch (e, stack) {
      emit(state.copyWith(status: AddEditOfferStatus.error('Error occurred in uploading the image ${e.toString()}')));
      Log.e('Error deleting category', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> deleteOffer(int offerId) async {
    try {
      emit(state.copyWith(status: AddEditOfferStatus.deleteLoading()));
      await repository.deleteOffer(offerId);
      emit(state.copyWith(status: AddEditOfferStatus.success(true)));
    } catch (e, stack) {
      emit(state.copyWith(status: AddEditOfferStatus.error('Error occurred in delete: ${e.toString()}')));
      Log.e('Error deleting offer', error: e, stackTrace: stack);
    }
  }
}

@immutable
@MappableClass()
class AddEditOfferState with AddEditOfferStateMappable {
  final AddEditOfferStatus status;

  const AddEditOfferState({required this.status});
}

@freezed
class AddEditOfferStatus with _$AddEditOfferStatus {
  const factory AddEditOfferStatus.initial() = AddEditOfferInitial;
  const factory AddEditOfferStatus.success(bool shouldPop) = AddEditOfferSuccess;
  const factory AddEditOfferStatus.submitLoading() = AddEditOfferSubmitLoading;
  const factory AddEditOfferStatus.deleteLoading() = AddEditOfferDeleteLoading;
  const factory AddEditOfferStatus.uploadLoading() = AddEditOfferUploadLoading;
  const factory AddEditOfferStatus.error(String message) = AddEditOfferError;
}
