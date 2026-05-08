import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';

import '../model/otp_validation.model.dart';

class OtpValidationStream extends StatelessWidget {
  final String firebaseTrackingId;
  final Widget Function(OtpValidation validation) builder;

  const OtpValidationStream({
    super.key,
    required this.firebaseTrackingId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('otpValidation').doc(firebaseTrackingId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator().center;
        }
        if (snapshot.hasError) {
          return const EmptyStateMessage(message: 'Error loading OTP');
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const EmptyStateMessage(message: 'No data was found');
        }

        final data = snapshot.data!.data()!;
        final validation = OtpValidationMapper.fromMap(data);
        return builder(validation);
      },
    );
  }
}
