import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/modal_wrapper.dart';

class PaperworkQrModal extends StatelessWidget {
  const PaperworkQrModal({
    super.key,
    required this.paperWorkLink,
  });

  final String paperWorkLink;

  static Future<List<Customer>?> show(BuildContext context, {required String paperWorkLink}) async {
    return await showModalBottomSheet<List<Customer>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return PaperworkQrModal(
          paperWorkLink: paperWorkLink,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: SafeArea(
        child: Container(
          width: Screen.width,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              topLeft: Radius.circular(16),
            ),
            color: lightBlueColor,
          ),
          child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(context),
                  Spacing.h30,
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: lightSkyBlue,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Spacing.w15,
                        Expanded(
                          child: Text(
                            paperWorkLink,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: paperWorkLink),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Spacing.h50,
                  BarcodeWidget(
                    barcode: Barcode.qrCode(
                      errorCorrectLevel: BarcodeQRCorrectionLevel.high,
                    ),
                    data: paperWorkLink,
                    height: 250,
                    width: 250,
                  ).center,
                  Spacing.h30,
                ],
              ).paddingSymmetric(horizontal: 20).scrollable,
        ).paddingOnly(bottom: MediaQuery.of(context).viewInsets.bottom),
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          'QR code',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ).paddingOnly(top: 8),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
