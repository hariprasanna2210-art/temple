import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

class BookingStatus extends StatefulWidget {
  static List<String> get courseStatuses => const [
    'Booked In',
    'Pw ongoing',
    'Pw done',
    'Dive center',
    'Harbour',
  ];

  static List<String> get dsdStatuses => const [
    'Booked In',
    'Pw ongoing',
    'Pw done',
    'Pool ongoing',
    'Pool completed',
    'Dive center',
    'Harbour',
  ];

  static Color getStatusColor(bool isDSD, int index) {
    if (isDSD) {
      return switch (index) {
        0 => Colors.blueAccent.withAlpha(600),
        1 => Colors.yellow,
        2 => Colors.blue,
        3 => Colors.greenAccent,
        4 => Colors.green,
        5 => Colors.grey,
        6 => Colors.black.withAlpha(400),
        _ => Colors.grey,
      };
    } else {
      return switch (index) {
        0 => Colors.blueAccent.withAlpha(600),
        1 => Colors.yellow,
        2 => Colors.blue,
        3 => Colors.grey,
        4 => Colors.black.withAlpha(400),
        _ => Colors.grey,
      };
    }
  }

  final int initialStatus;
  final bool isDSD;
  final ValueChanged<int> onChanged;

  const BookingStatus({
    super.key,
    required this.initialStatus,
    required this.onChanged,
    required this.isDSD,
  });

  @override
  State<BookingStatus> createState() => _BookingStatusState();
}

class _BookingStatusState extends State<BookingStatus> {
  late int status;

  List<String> get _statuses => widget.isDSD ? BookingStatus.dsdStatuses : BookingStatus.courseStatuses;

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
  }

  void _updateStatus(bool increment) {
    final maxIndex = _statuses.length - 1;
    setState(() {
      if (increment && status < maxIndex) {
        status++;
        widget.onChanged(status);
      } else if (!increment && status > 0) {
        status--;
        widget.onChanged(status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = BookingStatus.getStatusColor(widget.isDSD, status);

    return Row(
      children: [
        _ArrowButton(
          icon: Icons.arrow_left,
          color: color,
          onPressed: () => _updateStatus(false),
        ),
        const SizedBox(width: 2),
        Container(
          height: 33,
          width: 100,
          color: color,
          child:
              Text(
                _statuses[status],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ).paddingSymmetric(horizontal: 15).center,
        ),
        const SizedBox(width: 2),
        _ArrowButton(
          icon: Icons.arrow_right,
          color: color,
          onPressed: () => _updateStatus(true),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 33,
        width: 27,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.horizontal(left: const Radius.circular(4), right: const Radius.circular(4)),
        ),
        child: Icon(
          icon,
          size: 16,
        ),
      ),
    );
  }
}
