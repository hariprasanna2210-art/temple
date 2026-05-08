import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../services/logging.dart';
import '../models/activity_color.model.dart';
import '../repository/activity.repository.dart';

part 'all_activity_colors.cubit.freezed.dart';
part 'all_activity_colors.cubit.mapper.dart';

class AllActivityColorsCubit extends Cubit<AllActivityColorsState> {
  final ActivityRepository repository;

  AllActivityColorsCubit({required this.repository})
    : super(const AllActivityColorsState(status: AllActivityColorsStatus.initial(), colors: []));

  Future<void> fetchAllActivityColors() async {
    // Don't fetch if already fetched
    if (state.colors.isNotEmpty) return;

    try {
      emit(state.copyWith(status: AllActivityColorsStatus.loading()));
      final colors = await repository.fetchAllActivityColors();
      emit(state.copyWith(status: AllActivityColorsStatus.success(false), colors: colors));
    } catch (e, stack) {
      Log.e('Error fetching activity colors', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllActivityColorsStatus.error(e.toString())));
    }
  }

  void replaceActivityColor(ActivityColor updatedColor) {
    final List<ActivityColor> colors = List.of(state.colors);
    final index = colors.indexWhere((color) => color.id == updatedColor.id);

    // if item already exists, update it at exact index else append to list
    if (index != -1) {
      colors[index] = updatedColor;
    } else {
      colors.add(updatedColor);
    }

    emit(state.copyWith(colors: colors));
  }
}

@immutable
@MappableClass()
class AllActivityColorsState with AllActivityColorsStateMappable {
  final AllActivityColorsStatus status;
  final List<ActivityColor> colors;

  const AllActivityColorsState({required this.status, required this.colors});
}

@freezed
class AllActivityColorsStatus with _$AllActivityColorsStatus {
  const factory AllActivityColorsStatus.initial() = AllActivityColorsInitial;
  const factory AllActivityColorsStatus.success(bool shouldPop) = AllActivityColorsSuccess;
  const factory AllActivityColorsStatus.loading() = AllActivityColorsLoading;
  const factory AllActivityColorsStatus.error(String message) = AllActivityColorsError;
}
