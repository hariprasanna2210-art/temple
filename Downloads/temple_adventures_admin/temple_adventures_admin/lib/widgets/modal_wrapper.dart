import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:temple_adventures_admin/theme.dart';

import '../utils/styling/spacing_widgets.dart';

ValueNotifier<double> activeModalHeight = ValueNotifier(0);

class ModalWrapper extends StatelessWidget {
  final Widget child;

  const ModalWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    double defaultModalHeight = 600;

    double initialChildSize = defaultModalHeight / MediaQuery.of(context).size.height;
    if (initialChildSize > 1.0) {
      initialChildSize = 1.0;
    }

    return CustomDraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: initialChildSize < 0.3 ? initialChildSize : 0.3,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, controller) {
        return LayoutBuilder(
          builder: (context, constraints) {
            activeModalHeight = ValueNotifier(constraints.maxHeight);

            return BaseModal(
              scrollable: true,
              controller: controller,
              child: child,
            );
          },
        );
      },
    );
  }
}

class BaseModal extends StatelessWidget {
  const BaseModal({super.key, required this.child, this.controller, this.scrollable = true});

  final bool scrollable;
  final ScrollController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: lightBlueColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        physics: scrollable ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
        controller: scrollable ? controller : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Spacing.h12,
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.grey,
              ),
              width: 38,
              height: 4,
            ),
            Spacing.h16,
            child,
          ],
        ),
      ),
    );
  }
}

class CustomDraggableScrollableSheet extends StatefulWidget {
  /// The initial fractional value of the parent container's height to use when
  /// displaying the widget.
  ///
  /// Rebuilding the sheet with a new [initialChildSize] will only move
  /// the sheet to the new value if the sheet has not yet been dragged since it
  /// was first built or since the last call to [DraggableScrollableActuator.reset].
  ///
  /// The default value is `0.5`.
  final double initialChildSize;

  /// The minimum fractional value of the parent container's height to use when
  /// displaying the widget.
  ///
  /// The default value is `0.25`.
  final double minChildSize;

  /// The maximum fractional value of the parent container's height to use when
  /// displaying the widget.
  ///
  /// The default value is `1.0`.
  final double maxChildSize;

  /// Whether the widget should expand to fill the available space in its parent
  /// or not.
  ///
  /// In most cases, this should be true. However, in the case of a parent
  /// widget that will position this one based on its desired size (such as a
  /// [Center]), this should be set to false.
  ///
  /// The default value is true.
  final bool expand;

  /// Whether the widget should snap between [snapSizes] when the user lifts
  /// their finger during a drag.
  ///
  /// If the user's finger was still moving when they lifted it, the widget will
  /// snap to the next snap size (see [snapSizes]) in the direction of the drag.
  /// If their finger was still, the widget will snap to the nearest snap size.
  ///
  /// Snapping is not applied when the sheet is programmatically moved by
  /// calling [DraggableScrollableController.animateTo] or [DraggableScrollableController.jumpTo].
  ///
  /// Rebuilding the sheet with snap newly enabled will immediately trigger a
  /// snap unless the sheet has not yet been dragged away from
  /// [initialChildSize] since first being built or since the last call to
  /// [DraggableScrollableActuator.reset].
  final bool snap;

  /// A list of target sizes that the widget should snap to.
  ///
  /// Snap sizes are fractional values of the parent container's height. They
  /// must be listed in increasing order and be between [minChildSize] and
  /// [maxChildSize].
  ///
  /// The [minChildSize] and [maxChildSize] are implicitly included in snap
  /// sizes and do not need to be specified here. For example, `snapSizes = [.5]`
  /// will result in a sheet that snaps between [minChildSize], `.5`, and
  /// [maxChildSize].
  ///
  /// Any modifications to the [snapSizes] list will not take effect until the
  /// `build` function containing this widget is run again.
  ///
  /// Rebuilding with a modified or new list will trigger a snap unless the
  /// sheet has not yet been dragged away from [initialChildSize] since first
  /// being built or since the last call to [DraggableScrollableActuator.reset].
  final List<double>? snapSizes;

  /// Defines a duration for the snap animations.
  ///
  /// If it's not set, then the animation duration is the distance to the snap
  /// target divided by the velocity of the widget.
  final Duration? snapAnimationDuration;

  /// A controller that can be used to programmatically control this sheet.
  final DraggableScrollableController? controller;

  /// Whether the sheet, when dragged (or flung) to its minimum size, should
  /// cause its parent sheet to close.
  ///
  /// Set on emitted [DraggableScrollableNotification]s. It is up to parent
  /// classes to properly read and handle this value.
  final bool shouldCloseOnMinExtent;

  /// The builder that creates a child to display in this widget, which will
  /// use the provided [ScrollController] to enable dragging and scrolling
  /// of the contents.
  final ScrollableWidgetBuilder builder;

  final bool expandOnKeyboardOpen;

  const CustomDraggableScrollableSheet({
    super.key,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 1.0,
    this.expand = true,
    this.snap = false,
    this.snapSizes,
    this.snapAnimationDuration,
    this.controller,
    this.shouldCloseOnMinExtent = true,
    this.expandOnKeyboardOpen = false,
    required this.builder,
  });

  @override
  State<CustomDraggableScrollableSheet> createState() => _CustomDraggableScrollableSheetState();
}

class _CustomDraggableScrollableSheetState extends State<CustomDraggableScrollableSheet> {
  late StreamSubscription<bool>? keyboardSubscription;
  late DraggableScrollableController controller;

  @override
  void initState() {
    controller = widget.controller ?? DraggableScrollableController();

    keyboardSubscription =
        !widget.expandOnKeyboardOpen
            ? null
            : KeyboardVisibilityController().onChange.listen((isVisible) {
              if (!isVisible) return;
              controller.animateTo(1.0, duration: const Duration(milliseconds: 250), curve: Curves.linear);
            });

    super.initState();
  }

  @override
  void dispose() {
    keyboardSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      builder: (context, child) {
        if (widget.expandOnKeyboardOpen) {
          return child;
        }

        return ViewInsetsPadding(child: child);
      },
      child: DraggableScrollableSheet(
        key: widget.key,
        initialChildSize: widget.initialChildSize,
        minChildSize: widget.minChildSize,
        maxChildSize: widget.maxChildSize,
        expand: widget.expand,
        snap: widget.snap,
        snapSizes: widget.snapSizes,
        snapAnimationDuration: widget.snapAnimationDuration,
        controller: controller,
        shouldCloseOnMinExtent: widget.shouldCloseOnMinExtent,
        builder: widget.builder,
      ),
    );
  }
}

class ConditionalParent extends StatelessWidget {
  final Widget child;
  final Widget Function(BuildContext context, Widget child) builder;

  const ConditionalParent({
    super.key,
    required this.builder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

class ViewInsetsPadding extends StatelessWidget {
  const ViewInsetsPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom == 0 ? 0 : viewInsets.bottom),
      child: child,
    );
  }
}
