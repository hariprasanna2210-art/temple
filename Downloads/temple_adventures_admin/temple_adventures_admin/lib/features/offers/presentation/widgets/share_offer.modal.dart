import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/modal_wrapper.dart';
import 'package:temple_adventures_admin/widgets/app_image.dart';
import 'package:temple_adventures_admin/services/logging.dart';
import 'package:temple_adventures_admin/services/share.service.dart';
import '../../../../theme.dart';
import '../../models/offer.model.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../utils/styling/padding_extensions.dart';
import '../../../../utils/styling/alignment_extensions.dart';
import '../../../../utils/styling/app_measurements.dart';

class ShareOfferModal extends StatefulWidget {
  final Offer offer;

  const ShareOfferModal({super.key, required this.offer});

  static Future<void> show(BuildContext context, {required Offer offer}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareOfferModal(offer: offer),
    );
  }

  @override
  State<ShareOfferModal> createState() => _ShareOfferModalState();
}

class _ShareOfferModalState extends State<ShareOfferModal> {
  bool _isSharing = false;

  Offer get offer => widget.offer;

  Future<void> _shareImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      await ShareService.shareImageFromUrl(
        imageUrl: offer.photo,
        subject: offer.description ?? 'Check out this amazing offer!',
        text: offer.name,
      );
    } catch (e, stack) {
      Log.e('Error sharing image: $e', error: e, stackTrace: stack);
      if (mounted) context.showSnackBar('Failed to share image: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: SafeArea(
        child: Container(
          width: Screen.width,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: lightBlueColor,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child:
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Spacing.h20,
                    AppImage(
                      offer.photo,
                      fit: BoxFit.cover,
                    ),
                    Spacing.h40,
                    AppButton.flat(
                      width: Screen.width,
                      text: 'Share',
                      showLoading: _isSharing,
                      onTap: () {
                        _isSharing ? null : _shareImage();
                      },
                    ),
                    Spacing.h20,
                  ],
                ).scrollable,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Share Offer',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ).paddingOnly(top: 8),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
