import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/user/bloc/user.cubit.dart';

import '../../../services/logging.dart';
import '../../../widgets/custom_date_range_picker.dart';
import '../models/user.model.dart';
import '../repository/user.repository.dart';

part 'user_profile.cubit.freezed.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit({required this.repository}) : super(UserProfileState.initial());

  final UserRepository repository;

  Future<void> updateLeaves(BuildContext context) async {
    UserCubit userCubit = context.read<UserCubit>();
    User? user = userCubit.state.currentUser;

    if (user == null) {
      Log.e('Invalid usage: user is null');
      return;
    }

    final pickedDateRange = await DateRangePickerHelper.pickDateRange(context);
    if (pickedDateRange == null) {
      Log.i('User cancelled leave selection');
      return;
    }

    emit(UserProfileState.loading());

    final updatedUser = user.copyWith(leaveStartDate: pickedDateRange.start, leaveEndDate: pickedDateRange.end);
    await userCubit.updateUser(updatedUser);

    emit(UserProfileState.success());
  }
}

@freezed
class UserProfileState with _$UserProfileState {
  const factory UserProfileState.initial() = UserProfileInitial;
  const factory UserProfileState.loading() = UserProfileLoading;
  const factory UserProfileState.success() = UserProfileSuccess;
  const factory UserProfileState.error(String message) = UserProfileErrorStatus;
}
