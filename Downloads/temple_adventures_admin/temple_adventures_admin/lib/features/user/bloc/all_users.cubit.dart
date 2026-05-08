import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/logging.dart';
import '../models/user.model.dart';
import '../repository/user.repository.dart';

part 'all_users.cubit.freezed.dart';
part 'all_users.cubit.mapper.dart';

/// Cubit for managing the list of all users.
/// 
/// This cubit maintains the state of all users in the system and provides
/// methods to fetch and update the user list.
class AllUsersCubit extends Cubit<AllUsersState> {
  final UserRepository repository;

  AllUsersCubit({required this.repository}) : super(const AllUsersState(status: AllUsersStatus.initial(), users: []));

  /// Fetches all active users from the repository.
  /// 
  /// **State Management:**
  /// - While loading: Keeps existing users in state to prevent UI flicker
  /// - On success: Updates state with fetched users
  /// - On error: Keeps existing users and shows error status
  /// 
  /// **Note**: This method always fetches fresh data from the server to ensure
  /// multi-user sync (when one user adds/edits, others see the update).
  Future<void> fetchAllUsers() async {
    try {
      // Keep existing users while loading to prevent UI flicker
      emit(AllUsersState(status: AllUsersStatus.loading(), users: state.users));
      final users = await repository.fetchAllUsers();
      emit(AllUsersState(status: AllUsersStatus.loaded(), users: users));
    } catch (e, stack) {
      Log.e('Failed to fetch users: $e', stackTrace: stack);
      // Keep existing users on error so UI doesn't go blank
      emit(AllUsersState(status: AllUsersStatus.error('No users found'), users: state.users));
    }
  }
}

@immutable
@MappableClass()
class AllUsersState with AllUsersStateMappable {
  final AllUsersStatus status;
  final List<User> users;

  const AllUsersState({required this.status, required this.users});
}

@freezed
class AllUsersStatus with _$AllUsersStatus {
  const factory AllUsersStatus.initial() = AllUsersInitial;
  const factory AllUsersStatus.loading() = AllUsersLoading;
  const factory AllUsersStatus.loaded() = AllUsersLoaded;
  const factory AllUsersStatus.error(String message) = AllUsersStateError;
}
