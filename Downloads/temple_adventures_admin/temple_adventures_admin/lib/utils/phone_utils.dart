import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneUtils {
  static Future<void> makingPhoneCall({
    required String phoneNumber,
    required String code,
  }) async {
    final fullNumber = (code + phoneNumber).replaceAll(' ', '');
    final Uri uri = Uri(scheme: 'tel', path: fullNumber);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      debugPrint('Error while launching phone call: $e');
      rethrow;
    }
  }
}
