import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';

import '../../../services/logging.dart';
import '../../logs/enums/action_type.enum.dart';
import '../models/event.model.dart';
import '../repository/events.repository.dart';

part 'all_events.cubit.freezed.dart';
part 'all_events.cubit.mapper.dart';

class AllEventsCubit extends Cubit<AllEventsState> {
  final EventsRepository eventRepository;
  final LogsRepository logRepository;

  AllEventsCubit({required this.eventRepository, required this.logRepository})
    : super(const AllEventsState(status: AllEventsStatus.initial(), events: []));

  Future<void> fetchAllEvents() async {
    try {
      emit(state.copyWith(status: const AllEventsStatus.loading()));

      final events = await eventRepository.fetchAllEvents();

      emit(state.copyWith(status: const AllEventsStatus.loaded(), events: events));
    } catch (e, stack) {
      emit(state.copyWith(status: AllEventsStatus.error('No Events found: ${e.toString()}')));
      Log.e('Error fetching events', error: e, stackTrace: stack);
    }
  }

  /// updates the list of events in state
  void addOrEditEvent(EventModel updatedEvent) {
    List<EventModel> events = List.of(state.events);
    final index = events.indexWhere((event) => event.id == updatedEvent.id);

    // -1 means item not found
    if (index != -1) {
      events[index] = updatedEvent;
    } else {
      events.add(updatedEvent);
    }
    emit(state.copyWith(events: events, status: AllEventsStatus.success('Event updated successfully')));
  }

  Future<void> deleteEvent(int eventId) async {
    try {
      await eventRepository.deleteEvent(eventId);
      final updatedEvents = state.events.where((event) => event.id != eventId).toList();
      await logRepository.addLog(actionType: ActionType.eventDeleted, referenceId: eventId);
      emit(state.copyWith(events: updatedEvents, status: AllEventsStatus.success('Event deleted successfully')));
    } catch (e, stack) {
      emit(state.copyWith(status: AllEventsStatus.error('Error occurred in delete: ${e.toString()}')));
      Log.e('Error deleting event', error: e, stackTrace: stack);
    }
  }
}

@immutable
@MappableClass()
class AllEventsState with AllEventsStateMappable {
  final AllEventsStatus status;
  final List<EventModel> events;

  const AllEventsState({required this.status, required this.events});
}

@freezed
class AllEventsStatus with _$AllEventsStatus {
  const factory AllEventsStatus.initial() = AllEventsInitial;
  const factory AllEventsStatus.loading() = AllEventsLoading;
  const factory AllEventsStatus.loaded() = AllEventsLoaded;
  const factory AllEventsStatus.success(String message) = AllEventsSuccess;
  const factory AllEventsStatus.error(String message) = AllEventsError;
}
