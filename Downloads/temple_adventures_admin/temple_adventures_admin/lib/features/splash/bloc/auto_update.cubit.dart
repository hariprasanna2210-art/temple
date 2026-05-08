import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:temple_adventures_admin/features/splash/models/ota_info.model.dart';

import '../../../services/logging.dart';
import '../../../services/ota_service.dart';
import '../../../services/shared_preference_service.dart';
import '../../user/bloc/user.cubit.dart';

part 'auto_update.cubit.freezed.dart';

class AutoUpdateCubit extends Cubit<AutoUpdateState> {
  final OTAService otaService;
  final UserCubit _userCubit;

  AutoUpdateCubit({required this.otaService, required UserCubit userCubit})
    : _userCubit = userCubit,
      super(const AutoUpdateState.loading()) {
    // _checkForPatches();
  }

  Future<void> fetchVersionData() async {
    emit(const AutoUpdateState.loading());
    try {
      final response = await FirebaseFirestore.instance.collection('app_versions').doc('version_data').get();
      if (response.data() != null) {
        OTAInfo info = OTAInfoMapper.fromMap(response.data()!);

        final version = await OTAService(ShorebirdUpdater()).getAppCombinedVersion();

        if (Platform.isAndroid && (info.androidVersionNumber != version)) {
          emit(AutoUpdateState.updateRequired(info));
        } else if (Platform.isIOS && (info.iosVersionNumber != version)) {
          emit(AutoUpdateState.updateRequired(info));
        } else {
          if (SharedPrefKeys.userId.exists) {
            try {
              await _userCubit.getUserData(SharedPrefKeys.userId.getInt!);

              // If user fetch success → navigate to dashboard
              if (_userCubit.state.status is UserSuccess) {
                emit(const AutoUpdateState.navigateToDashboard());
              } else {
                // User fetch failed → go to login
                emit(const AutoUpdateState.navigateToLoginScreen());
              }
            } catch (e, stack) {
              // In case getUserData throws error
              Log.e("Error fetching user data: $e", error: e, stackTrace: stack);
              emit(const AutoUpdateState.navigateToLoginScreen());
            }
          } else {
            emit(const AutoUpdateState.navigateToLoginScreen());
          }
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      emit(AutoUpdateState.error('Error: ${e.toString()}'));
    }
  }
}

@freezed
sealed class AutoUpdateState with _$AutoUpdateState {
  const factory AutoUpdateState.loading() = AutoUpdateLoading;

  const factory AutoUpdateState.updateRequired(OTAInfo info) = AutoUpdateUpdateRequired;

  const factory AutoUpdateState.installingUpdate() = AutoUpdateInstallingUpdate;

  const factory AutoUpdateState.error(String message) = AutoUpdateError;

  const factory AutoUpdateState.navigateToDashboard() = AutoUpdateNavigateToDashboard;

  const factory AutoUpdateState.navigateToLoginScreen() = AutoUpdateNavigateToLoginScreen;

  const factory AutoUpdateState.showRestartStatus() = AutoUpdateShowRestartStatus;
}
