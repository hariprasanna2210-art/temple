import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/main.dart';

import '../../../services/logging.dart';
import '../../user/bloc/user.cubit.dart';
import '../model/otp_validation.model.dart';
import 'all_equipment.cubit.dart';

part 'otp.cubit.freezed.dart';
part 'otp.cubit.mapper.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit() : super(const OtpState(status: OtpStatus.initial()));

  void onOtpChange(String otp) {
    emit(state.copyWith(otp: otp, status: const OtpStatus.initial()));
  }

  Future<void> generateOtp() async {
    try {
      emit(state.copyWith(firebaseTrackingId: null, status: const OtpStatus.loading()));
      final query =
          await FirebaseFirestore.instance.collection('otpValidation').where('approve', isEqualTo: false).get();
      final existingCodes = query.docs.map((doc) => doc.data()['otp'] as String).toList();

      final code = _generateUniqueOtp(existingCodes);

      BuildContext? context = navigatorKey.currentContext;

      final currentUser = context?.read<UserCubit>().state.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated');
      }

      final validation = OtpValidation(
        approverID: currentUser.id.toString(),
        renterID: null,
        otp: code,
        approve: false,
        equipmentItem: const [],
      );

      final doc = await FirebaseFirestore.instance.collection('otpValidation').add(validation.toMap());

      emit(
        state.copyWith(
          firebaseTrackingId: doc.id,
          otp: code,
          status: const OtpStatus.loaded(),
        ),
      );
    } catch (e, stack) {
      emit(state.copyWith(status: OtpStatus.error(e.toString())));
      Log.e('Error generating OTP', error: e, stackTrace: stack);
    }
  }

  void clearFirebaseTrackingId() {
    emit(
      state.copyWith(firebaseTrackingId: null, otp: null, status: const OtpStatus.initial()),
    );
  }

  Future<void> _updateFirebaseValidation(OtpValidation validation, String firebaseTrackingId) async {
    await FirebaseFirestore.instance.collection('otpValidation').doc(firebaseTrackingId).set(validation.toMap());
  }

  Future<void> verifyOTP(String otp) async {
    try {
      emit(state.copyWith(status: const OtpStatus.loading()));
      final query =
          await FirebaseFirestore.instance
              .collection('otpValidation')
              .where('otp', isEqualTo: otp)
              .where('approve', isEqualTo: false)
              .limit(1)
              .get();

      if (query.docs.isEmpty) throw Exception('OTP not found');
      BuildContext? context = navigatorKey.currentContext;

      final currentUser = context?.read<UserCubit>().state.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated');
      }
      final selectedItems = context?.read<AllEquipmentCubit>().state.selectedItems ?? [];

      final validation = OtpValidationMapper.fromMap(query.docs.first.data()).copyWith(
        equipmentItem: selectedItems,
        renterID: currentUser.id.toString(),
      );

      final firebaseTrackingId = query.docs.first.id;
      emit(state.copyWith(firebaseTrackingId: firebaseTrackingId));
      await _updateFirebaseValidation(validation, firebaseTrackingId);
      emit(state.copyWith(status: const OtpStatus.loaded()));
    } catch (e, stack) {
      emit(state.copyWith(firebaseTrackingId: null, status: OtpStatus.error(e.toString())));
      Log.e('Error verifying OTP', error: e, stackTrace: stack);
    }
  }

  String _generateUniqueOtp(List<String> existingCodes) {
    final random = math.Random();
    String code;
    do {
      code = (random.nextInt(9000) + 1000).toString();
    } while (existingCodes.contains(code));
    return code;
  }
}

@immutable
@MappableClass()
class OtpState with OtpStateMappable {
  final OtpStatus status;
  final String? otp;
  final String? firebaseTrackingId;

  const OtpState({
    required this.status,
    this.otp,
    this.firebaseTrackingId,
  });
}

@freezed
class OtpStatus with _$OtpStatus {
  const factory OtpStatus.initial() = OtpInitial;
  const factory OtpStatus.loading() = OtpLoading;
  const factory OtpStatus.loaded() = OtpLoaded;
  const factory OtpStatus.success(String message) = OtpSuccess;
  const factory OtpStatus.error(String message) = OtpError;
}
