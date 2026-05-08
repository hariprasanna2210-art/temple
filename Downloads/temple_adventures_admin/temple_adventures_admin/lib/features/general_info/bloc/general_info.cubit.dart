import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/features/general_info/models/general_info.model.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';

import '../../../services/logging.dart';
import '../../boats/helpers/board_plan.helper.dart';

part 'general_info.cubit.freezed.dart';
part 'general_info.cubit.mapper.dart';

class GeneralInfoCubit extends Cubit<GeneralInfoState> {
  final BoatsRepository repository;

  GeneralInfoCubit({required this.repository}) : super(GeneralInfoState(status: GeneralInfoStateStatus.initial()));

  Future<void> fetchGeneralInfoByDate(DateTime selectedDate) async {
    emit(state.copyWith(status: GeneralInfoStateStatus.loading()));
    try {
      GeneralInfo? generalInfo = await repository.fetchGeneralInfoByDate(selectedDate.formatDDMMYYYY);
      emit(state.copyWith(status: GeneralInfoStateStatus.loaded(generalInfo)));
    } catch (e, stack) {
      Log.e('Error loading general info for date pressed', error: e, stackTrace: stack);
      emit(state.copyWith(status: GeneralInfoStateStatus.error(e.toString())));
    }
  }

  Future<void> onSubmit(GeneralInfo generalInfo) async {
    try {
      emit(state.copyWith(status: GeneralInfoStateStatus.loading()));

      if (generalInfo.id != null) {
        await repository.updateGeneralInfo(generalInfo);
      } else {
        await repository.addGeneralInfo(generalInfo);
      }

      // Update board plan with the generalInfo date
      BoardPlanHelper.updateBoardPlan(generalInfo.date.toDateTime()!);


      emit(state.copyWith(status: GeneralInfoStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: GeneralInfoStateStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class GeneralInfoState with GeneralInfoStateMappable {
  final GeneralInfoStateStatus status;

  const GeneralInfoState({required this.status});
}

@freezed
abstract class GeneralInfoStateStatus with _$GeneralInfoStateStatus {
  const factory GeneralInfoStateStatus.initial() = GeneralInfoInitial;
  const factory GeneralInfoStateStatus.loading() = GeneralInfoLoading;
  const factory GeneralInfoStateStatus.loaded(GeneralInfo? generalInfo) = GeneralInfoLoaded;
  const factory GeneralInfoStateStatus.success() = GeneralInfoSuccess;
  const factory GeneralInfoStateStatus.error(String message) = GeneralInfoError;
}
