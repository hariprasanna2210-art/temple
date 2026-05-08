import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_emoji_feedback/flutter_emoji_feedback.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/modal_wrapper.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../bloc/roster.cubit.dart';
import '../../models/customer_feedback.model.dart';

class CustomerFeedbackModal extends StatefulWidget {
  const CustomerFeedbackModal({
    super.key,
    required this.customerFeedback,
    required this.bookingId,
    required this.customerId,
    required this.isFeedbackAlreadySubmitted,
  });

  final CustomerFeedback? customerFeedback;
  final int bookingId;
  final int customerId;
  final bool isFeedbackAlreadySubmitted;

  static Future<void> show(
    BuildContext context, {
    required CustomerFeedback? customerFeedback,
    required int bookingId,
    required int customerId,
    bool isFeedbackAlreadySubmitted = false,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return CustomerFeedbackModal(
          customerFeedback: customerFeedback,
          bookingId: bookingId,
          customerId: customerId,
          isFeedbackAlreadySubmitted: isFeedbackAlreadySubmitted,
        );
      },
    );
  }

  @override
  State<CustomerFeedbackModal> createState() => _CustomerFeedbackModalState();
}

class _CustomerFeedbackModalState extends State<CustomerFeedbackModal> {
  final TextEditingController _feedbackTED = TextEditingController();
  bool knowsSwimming = false;
  bool interestedOwc = false;
  int instructorRating = 3;
  int equipmentRating = 3;
  int experienceRating = 3;
  CustomerFeedback? customerFeedback;
  bool isFeedbackAlreadySubmitted = false;

  @override
  void initState() {
    super.initState();

    customerFeedback = widget.customerFeedback;
    if (customerFeedback != null) {
      isFeedbackAlreadySubmitted = true;
      knowsSwimming = customerFeedback!.knowsSwimming!;
      interestedOwc = customerFeedback!.interestedOwc!;
      instructorRating = customerFeedback!.instructorFeedback!;
      equipmentRating = customerFeedback!.equipmentFeedback!;
      experienceRating = customerFeedback!.experienceFeedback!;
      _feedbackTED.text = customerFeedback!.feedback ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: SafeArea(
        child: BlocListener<RosterCubit, RosterState>(
          listener: (context, state) {
            final status = state.status;
            if (status is RosterError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text((state.status as RosterError).message)),
              );
            }
            if (status is RosterLoaded) {
              context.read<RosterCubit>().refreshData();
            }
          },
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
                  children: [
                    Spacing.h20,
                    _Header(),
                    Spacing.h15,
                    _Switch(
                      text: 'Knows Swimming',
                      switchValue: knowsSwimming,
                      onChanged: (value) {
                        knowsSwimming = value;
                        setState(() {});
                      },
                    ),
                    Spacing.h15,
                    _Switch(
                      text: 'Interested in OWC',
                      switchValue: interestedOwc,
                      onChanged: (value) {
                        interestedOwc = value;
                        setState(() {});
                      },
                    ),
                    Spacing.h20,
                    _EmojiFeedback(
                      title: 'Instructor Feedback',
                      rating: instructorRating,
                      onChanged: (value) {
                        if (value == null) return;

                        instructorRating = value;
                        setState(() {});
                      },
                    ),
                    Spacing.h20,
                    _EmojiFeedback(
                      title: 'Equipment Feedback',
                      rating: equipmentRating,
                      onChanged: (value) {
                        if (value == null) return;

                        equipmentRating = value;
                        setState(() {});
                      },
                    ),
                    Spacing.h20,
                    _EmojiFeedback(
                      title: 'Experience Feedback',
                      rating: experienceRating,
                      onChanged: (value) {
                        if (value == null) return;

                        experienceRating = value;
                        setState(() {});
                      },
                    ),
                    AppTextField(
                      controller: _feedbackTED,
                      labelText: 'Feedback',
                      maxLines: 3,
                    ),
                    Spacing.h50,
                    BlocBuilder<RosterCubit, RosterState>(
                      builder: (context, state) {
                        final isLoading = state.status is RosterLoading;
                        return AppButton.flat(
                          width: Screen.width,
                          text: (widget.customerFeedback == null) ? 'Submit' : 'Update',
                          showLoading: isLoading,
                          onTap: () async {
                            final feedback = CustomerFeedback(
                              id: widget.customerFeedback?.id,
                              bookingId: widget.bookingId,
                              customerId: widget.customerId,
                              knowsSwimming: knowsSwimming,
                              interestedOwc: interestedOwc,
                              instructorFeedback: instructorRating,
                              equipmentFeedback: equipmentRating,
                              experienceFeedback: experienceRating,
                              feedback: _feedbackTED.text.trim().isEmpty ? null : _feedbackTED.text.trim(),
                            );

                            await context.read<RosterCubit>().submitCustomerFeedback(
                              customerFeedback: feedback,
                            );

                            if (context.mounted) {
                              if (widget.isFeedbackAlreadySubmitted) {
                                Navigator.pop(context);
                              }
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
                    Spacing.h50,
                  ],
                ).paddingSymmetric(horizontal: 20).scrollable,
          ).paddingOnly(bottom: MediaQuery.of(context).viewInsets.bottom),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          "How's is your dive",
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

class _EmojiFeedback extends StatelessWidget {
  final String title;
  final int? rating;
  final Function(int?)? onChanged;

  const _EmojiFeedback({required this.title, this.rating, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
        Spacing.h15,
        EmojiFeedback(
          animDuration: const Duration(milliseconds: 300),
          emojiPreset: StaticEmojiPreset([
            classicEmojiPreset.emojis.first,
            classicEmojiPreset.emojis[2],
            classicEmojiPreset.emojis.last,
          ]),
          curve: Curves.bounceIn,
          inactiveElementScale: .5,
          elementSize: 70,
          showLabel: false,
          initialRating: rating,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Switch extends StatelessWidget {
  final String text;
  final bool switchValue;
  final Function(bool)? onChanged;

  const _Switch({required this.text, required this.switchValue, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
        Switch(
          value: switchValue,
          onChanged: onChanged as void Function(bool)?,
          activeThumbColor: skyBlueColor,
          inactiveThumbColor: Colors.grey,
        ),
      ],
    );
  }
}
