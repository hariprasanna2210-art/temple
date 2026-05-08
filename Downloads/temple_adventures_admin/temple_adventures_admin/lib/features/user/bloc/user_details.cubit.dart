import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/logs/enums/action_type.enum.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/features/user/models/user.model.dart';

import '../../../services/logging.dart';
import '../repository/user.repository.dart';
import 'all_users.cubit.dart';

part 'user_details.cubit.freezed.dart';

class UserDetailsCubit extends Cubit<UserDetailsState> {
  final UserRepository repository;
  final LogsRepository logRepository;

  UserDetailsCubit({required this.repository, required this.logRepository}) : super(const UserDetailsState.initial());

  Future<void> deleteUser(BuildContext context, User userModel) async {
    try {
      emit(const UserDetailsState.loading());

      final user = userModel.copyWith(isDeleted: true);
      await repository.editUser(user);
      await logRepository.addLog(actionType: ActionType.deleteEmployee, name: user.fullName, referenceId: user.id);
      if (context.mounted) {
        // Refresh the users list from server to get the latest data
        await context.read<AllUsersCubit>().fetchAllUsers();
      }

      emit(const UserDetailsState.success());
    } catch (e, stack) {
      Log.e('Error handling user edit pressed', error: e, stackTrace: stack);
      emit(UserDetailsState.error(e.toString()));
    }
  }
}

@freezed
class UserDetailsState with _$UserDetailsState {
  const factory UserDetailsState.initial() = UserDetailsInitial;
  const factory UserDetailsState.loading() = UserDetailsLoading;
  const factory UserDetailsState.success() = UserDetailsSuccess;
  const factory UserDetailsState.error(String message) = UserDetailsError;
}
