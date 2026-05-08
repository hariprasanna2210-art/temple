import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/helpers/board_plan.helper.dart';
import 'package:temple_adventures_admin/features/events/bloc/all_events.cubit.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';

import '../../../services/logging.dart';
import '../../logs/enums/action_type.enum.dart';
import '../models/event.model.dart';
import '../repository/events.repository.dart';

part 'add_edit_event.cubit.freezed.dart';
part 'add_edit_event.cubit.mapper.dart';

class AddEditEventCubit extends Cubit<AddEditEventState> {
  final EventsRepository eventRepository;
  final LogsRepository logRepository;

  AddEditEventCubit({
    required this.eventRepository,
    required this.logRepository,
  }) : super(const AddEditEventState(status: AddEditEventStatus.initial()));

  Future<void> onSubmit(BuildContext context, EventModel event) async {
    try {
      emit(state.copyWith(status: const AddEditEventStatus.loading()));

      EventModel? updatedEvent = event;
      if (updatedEvent.id == null) {
        updatedEvent = await eventRepository.addEvent(updatedEvent);

        if (updatedEvent != null) {
          await logRepository.addLog(
            actionType: ActionType.eventCreated,
            name: updatedEvent.sessionName,
            referenceId: updatedEvent.id,
          );
        }
      } else {
        updatedEvent = await eventRepository.editEvent(updatedEvent);
        await logRepository.addLog(
          actionType: ActionType.eventEdited,
          name: updatedEvent.sessionName,
          referenceId: updatedEvent.id,
        );
      }

      // Check if the operation failed
      if (updatedEvent == null) {
        emit(state.copyWith(status: const AddEditEventStatus.error("Failed to save event")));
        return;
      }

      // Update board plan with event date
      BoardPlanHelper.updateBoardPlan(updatedEvent.eventDateTime);

      if (context.mounted) {
        /// Update the list of events in AllEventsScreen
        /// addOrEditEvent will update the exiting list in state and don't perform any new api call to refresh events.
        context.read<AllEventsCubit>().addOrEditEvent(updatedEvent);
      }
      emit(state.copyWith(status: AddEditEventStatus.success(updatedEvent)));
    } catch (e, stack) {
      Log.e('Error in addEditEventsCubit', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditEventStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditEventState with AddEditEventStateMappable {
  final AddEditEventStatus status;

  const AddEditEventState({required this.status});
}

@freezed
class AddEditEventStatus with _$AddEditEventStatus {
  const factory AddEditEventStatus.initial() = AddEditEventInitial;
  const factory AddEditEventStatus.success(EventModel? updatedEvent) = AddEditEventSuccess;
  const factory AddEditEventStatus.loading() = AddEditEventLoading;
  const factory AddEditEventStatus.error(String message) = AddEditEventError;
}
