import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../services/logging.dart';
import '../../../services/notification.service.dart';
import '../../../utils/supabase_error_helper.dart';
import '../models/user.model.dart';
import '../repository/user.repository.dart';

part 'user.cubit.freezed.dart';
part 'user.cubit.mapper.dart';

/// Used globally to access current user
class UserCubit extends Cubit<UserState> {
  final UserRepository repository;
  final NotificationService _notificationService = NotificationService();

  UserCubit({required this.repository}) : super(const UserState(currentUser: null, status: UserStatusState.initial()));

  Future<void> getUserData(int userId) async {
    emit(state.copyWith(status: const UserStatusState.loading()));
    try {
      final User? currentUser = await repository.fetchCurrentUser(userId: userId);
      if (currentUser == null) {
        emit(state.copyWith(status: const UserStatusState.error('User not found')));
        SentryHelper.clearUser();
        // Unsubscribe from notifications if user not found
        await _notificationService.updateNotificationSubscription(null);
      } else {
        emit(state.copyWith(currentUser: currentUser, status: const UserStatusState.success()));
        // Set user context in Sentry for error tracking
        SentryHelper.setUser(
          userId: currentUser.id?.toString(),
          username: currentUser.fullName,
          data: {
            'phone_number': currentUser.phoneNumber,
            'country_code': currentUser.countryCode,
            'access_levels': currentUser.accessLevels?.map((e) => e.toString()).toList(),
          },
        );
        // Update notification subscription based on access level
        await _notificationService.updateNotificationSubscription(currentUser);
      }
    } catch (e, stack) {
      final errorMessage = SupabaseErrorHelper.getSupabaseErrorMessage(e);
      emit(state.copyWith(status: UserStatusState.error(errorMessage)));
      
      // Log with additional context for Sentry
      Log.e(
        'Error getting user data: $errorMessage',
        error: e,
        stackTrace: stack,
      );
      
      // Add extra context for configuration errors
      if (SupabaseErrorHelper.isConfigurationError(e)) {
        SentryHelper.captureException(
          e,
          stackTrace: stack,
          extra: {
            'error_code': SupabaseErrorHelper.getErrorCode(e),
            'user_id': userId.toString(),
            'error_type': 'supabase_configuration_error',
          },
          tag: 'supabase_auth',
        );
      }
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await repository.editUser(user);
      emit(state.copyWith(currentUser: user));
      // Update notification subscription if access levels changed
      await _notificationService.updateNotificationSubscription(user);
    } catch (e, stack) {
      final errorMessage = SupabaseErrorHelper.getSupabaseErrorMessage(e);
      Log.e('Failed to update user: $errorMessage', error: e, stackTrace: stack);
      
      // Add extra context for configuration errors
      if (SupabaseErrorHelper.isConfigurationError(e)) {
        SentryHelper.captureException(
          e,
          stackTrace: stack,
          extra: {
            'error_code': SupabaseErrorHelper.getErrorCode(e),
            'user_id': user.id?.toString(),
            'error_type': 'supabase_configuration_error',
          },
          tag: 'supabase_update',
        );
      }
    }
  }
}

@immutable
@MappableClass()
class UserState with UserStateMappable {
  final User? currentUser;
  final UserStatusState status;

  const UserState({required this.currentUser, required this.status});
}

@freezed
class UserStatusState with _$UserStatusState {
  const factory UserStatusState.initial() = UserInitial;
  const factory UserStatusState.loading() = UserLoading;
  const factory UserStatusState.success() = UserSuccess;
  const factory UserStatusState.error(String message) = UserError;
}
