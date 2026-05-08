import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/logging.dart';
import '../../logs/enums/action_type.enum.dart';
import '../../logs/repository/logs.repository.dart';
import '../models/user.model.dart';
import '../repository/user.repository.dart';

part 'add_edit_user.cubit.freezed.dart';

/// Cubit for managing add/edit user operations.
/// 
/// Handles both creating new users and updating existing users.
/// Also logs the action (add/edit) for audit purposes.
class AddEditUserCubit extends Cubit<AddEditUserState> {
  final UserRepository repository;
  final LogsRepository logRepository;

  AddEditUserCubit({required this.repository, required this.logRepository}) : super(const AddEditUserState.initial());

  /// Handles user submission (both add and edit operations).
  /// 
  /// **Flow:**
  /// 1. If user.id is null → Add new user (may restore deleted user if phone exists)
  /// 2. If user.id is not null → Update existing user
  /// 3. Log the action (add/edit) for audit trail
  /// 4. Emit success state with updated user
  /// 
  /// **Note**: The repository's `addUser` method handles restoring deleted users
  /// automatically if a deleted user with the same phone number exists.
  Future<void> onSubmit(BuildContext context, User user) async {
    try {
      emit(const AddEditUserState.loading());

      User? updatedUser = user;

      // Determine if this is an add or edit operation based on user ID
      if (updatedUser.id == null) {
        // Adding a new user (may restore a deleted user if phone number matches)
        updatedUser = await repository.addUser(updatedUser);
        if (updatedUser != null && updatedUser.id != null) {
          // Log the add action for audit purposes
          await logRepository.addLog(
            actionType: ActionType.addEmployee,
            name: updatedUser.fullName,
            referenceId: updatedUser.id,
          );
        }
      } else {
        // Editing an existing user
        await repository.editUser(updatedUser);
        if (updatedUser.id != null) {
          // Log the edit action for audit purposes
          await logRepository.addLog(
            actionType: ActionType.editEmployee,
            name: updatedUser.fullName,
            referenceId: updatedUser.id,
          );
        }
      }

      emit(AddEditUserState.success(updatedUser));
    } catch (e, stack) {
      Log.e('Error handling user pressed', error: e, stackTrace: stack);
      emit(AddEditUserState.error(e.toString()));
    }
  }
}

@freezed
class AddEditUserState with _$AddEditUserState {
  const factory AddEditUserState.initial() = AddEditUserInitial;
  const factory AddEditUserState.loading() = AddEditUserLoading;
  const factory AddEditUserState.success(User? updatedUser) = AddEditUserSuccess;
  const factory AddEditUserState.error(String message) = AddEditUserError;
}
