import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/logging.dart';
import '../../user/models/user.model.dart';
import '../model/enriched_equipment_logs.model.dart';
import '../model/equipment_log.model.dart';
import '../model/otp_validation.model.dart';
import '../respository/equipment.repository.dart';

part 'equipment_log.cubit.freezed.dart';
part 'equipment_log.cubit.mapper.dart';

class EquipmentLogCubit extends Cubit<EquipmentLogState> {
  final EquipmentRepository repository;

  EquipmentLogCubit({required this.repository})
    : super(
        const EquipmentLogState(
          status: EquipmentLogStatus.initial(),
          logs: [],
        ),
      );

  /// Fetch enriched equipment logs
  Future<void> fetchEquipmentLogs() async {
    try {
      emit(state.copyWith(status: const EquipmentLogStatus.loading()));
      final logs = await repository.fetchEnrichedEquipmentLogs();
      emit(state.copyWith(status: const EquipmentLogStatus.loaded(), logs: logs));
    } catch (e, stack) {
      emit(state.copyWith(status: EquipmentLogStatus.error('Error fetching enriched logs: $e')));
      Log.e('Error fetching enriched equipment logs', error: e, stackTrace: stack);
    }
  }

  /// Approve rental and add a new log entry
  Future<void> approveRentalAndAddLog({
    required OtpValidation validation,
    required List<User> employees,
    required String approverId,
    required String firebaseTrackingId,
  }) async {
    try {
      emit(state.copyWith(status: const EquipmentLogStatus.loading()));

      final approvedValidation = validation.copyWith(approve: true, approverID: approverId);
      await FirebaseFirestore.instance
          .collection('otpValidation')
          .doc(firebaseTrackingId)
          .set(approvedValidation.toMap());

      final approver = employees.firstWhere(
        (e) => e.id.toString() == approverId,
        orElse: () => throw Exception('Approver not found'),
      );

      final renter = employees.firstWhere(
        (e) => e.id.toString() == approvedValidation.renterID,
        orElse: () => throw Exception('Renter not found'),
      );

      final log = EquipmentLog(
        approverId: approver,
        renterId: renter,
        equipmentItem: approvedValidation.equipmentItem,
        rentedTime: DateTime.now(),
      );

      await repository.addEquipmentLog(log);
      await repository.updateEquipmentItemAvailability(validation.equipmentItem, renter, DateTime.now());
      emit(state.copyWith(status: const EquipmentLogStatus.success('Rental approved and log added')));
    } catch (e, stack) {
      emit(state.copyWith(status: EquipmentLogStatus.error(e.toString())));
      Log.e('Error approving rental', error: e, stackTrace: stack);
    }
  }

  /// Complete submission of equipment and update logs
  Future<void> completeSubmission(EnrichedEquipmentLogs log, User currentUser) async {
    try {
      emit(state.copyWith(status: const EquipmentLogStatus.loading()));
      await repository.completeEquipmentSubmission(log, currentUser);
      await repository.updateEquipmentItemAvailability(log.equipmentItems, null, null);
      final logs = await repository.fetchEnrichedEquipmentLogs();

      emit(
        state.copyWith(logs: logs, status: const EquipmentLogStatus.success('Submission completed successfully')),
      );
    } catch (e, stack) {
      emit(state.copyWith(status: EquipmentLogStatus.error(e.toString())));
      Log.e('Error completing submission', error: e, stackTrace: stack);
    }
  }
}

@immutable
@MappableClass()
class EquipmentLogState with EquipmentLogStateMappable {
  final EquipmentLogStatus status;
  final List<EnrichedEquipmentLogs> logs;

  const EquipmentLogState({
    required this.status,
    required this.logs,
  });
}

@freezed
class EquipmentLogStatus with _$EquipmentLogStatus {
  const factory EquipmentLogStatus.initial() = EquipmentLogInitial;
  const factory EquipmentLogStatus.loading() = EquipmentLogLoading;
  const factory EquipmentLogStatus.loaded() = EquipmentLogLoaded;
  const factory EquipmentLogStatus.success(String message) = EquipmentLogSuccess;
  const factory EquipmentLogStatus.error(String message) = EquipmentLogError;
}
