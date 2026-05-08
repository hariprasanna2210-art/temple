import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/logging.dart';
import '../models/log.model.dart';
import '../repository/logs.repository.dart';

part 'all_logs.cubit.freezed.dart';
part 'all_logs.cubit.mapper.dart';

class AllLogsCubit extends Cubit<AllLogsState> {
  final LogsRepository repository;

  AllLogsCubit({required this.repository}) : super(const AllLogsState(status: AllLogsStatus.initial(), logs: []));
  static const int pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// Loads the first page of logs and resets pagination state.
  Future<void> fetchInitialLogs() async {
    try {
      emit(state.copyWith(status: const AllLogsStatus.loading()));

      final logs = await repository.fetchPaginatedLogs(
        limit: pageSize,
        offset: 0,
      );
      _page = 1;
      _hasMore = logs.length == pageSize;

      emit(state.copyWith(status: const AllLogsStatus.loaded(), logs: logs));
    } catch (e, stack) {
      emit(state.copyWith(status: AllLogsStatus.error('No Logs found: ${e.toString()}')));
      Log.e('Error fetching logs', error: e, stackTrace: stack);
    }
  }

  /// Loads the next page of logs and appends them to the current list.
  Future<void> fetchMoreLogs() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    try {
      final newLogs = await repository.fetchPaginatedLogs(limit: pageSize, offset: _page * pageSize);
      _page++;
      _hasMore = newLogs.length == pageSize;
      emit(state.copyWith(logs: [...state.logs, ...newLogs]));
    } catch (e, stack) {
      Log.e('Error loading more logs', error: e, stackTrace: stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Refreshes the logs list by resetting pagination and fetching again.
  Future<void> refresh() async {
    _page = 0;
    _hasMore = true;
    await fetchInitialLogs();
  }

  bool get hasMore => _hasMore;
}

@immutable
@MappableClass()
class AllLogsState with AllLogsStateMappable {
  final AllLogsStatus status;
  final List<LogModel> logs;

  const AllLogsState({required this.status, required this.logs});
}

@freezed
class AllLogsStatus with _$AllLogsStatus {
  const factory AllLogsStatus.initial() = AllLogsInitial;
  const factory AllLogsStatus.loading() = AllLogsLoading;
  const factory AllLogsStatus.loaded() = AllLogsLoaded;
  const factory AllLogsStatus.success(String message) = AllLogsSuccess;
  const factory AllLogsStatus.error(String message) = AllLogsError;
}
