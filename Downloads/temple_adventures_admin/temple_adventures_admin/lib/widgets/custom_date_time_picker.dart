import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Defines the type of picker to display: date only, time only, or combined date-time
enum DateTimePickerType {
  date,
  time,
  dateTime,
}

/// A comprehensive date and time picker widget
///
/// This widget provides a unified interface for selecting dates, times, or both,
/// using Flutter's native picker dialogs with locale-aware formatting and
/// customizable appearance. Supports both standalone and form-integrated usage.
class CustomDateTimePicker extends StatefulWidget {
  /// The type of picker to display (date, time, or dateTime)
  final DateTimePickerType type;

  /// The locale to use for the picker
  final Locale? locale;

  /// The earliest date that can be selected
  final DateTime? firstDate;

  /// The latest date that can be selected
  final DateTime? lastDate;

  /// Label text for the date picker dialog
  final String? dateLabelText;

  /// Initial value as a string
  final String? initialValue;

  /// Callback when the value changes
  final ValueChanged<String>? onChanged;

  /// Input decoration for the text field
  final InputDecoration? decoration;

  /// Text editing controller
  final TextEditingController? controller;

  /// Whether to use root navigator for dialogs
  final bool useRootNavigator;

  /// To change fontSize
  final TextStyle? textStyle;

  const CustomDateTimePicker({
    super.key,
    this.type = DateTimePickerType.dateTime,
    this.locale,
    this.firstDate,
    this.lastDate,
    this.dateLabelText,
    this.initialValue,
    this.onChanged,
    this.decoration,
    this.controller,
    this.useRootNavigator = false,
    this.textStyle,
  });

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  late TextEditingController _controller;
  DateTime? _selectedDateTime;
  DateFormat? _dateFormatter;
  DateFormat? _timeFormatter;
  DateFormat? _dateTimeFormatter;
  bool _isUpdatingFromListener = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _parseInitialValue();
    _parseControllerText();
    // Listen for external controller changes and reformat them
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CustomDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _parseInitialValue();
    }
    if (oldWidget.locale != widget.locale) {
      _initializeFormatters();
      _updateDisplayText();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeFormatters();
    _updateDisplayText();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _initializeFormatters() {
    // Extract locale string, fallback to system default if null
    final String? localeString = widget.locale?.toString() ?? Localizations.maybeLocaleOf(context)?.toString();

    if (localeString != null) {
      _dateFormatter = DateFormat.yMMMd(localeString);
      _timeFormatter = DateFormat.jm(localeString);
      _dateTimeFormatter = DateFormat.yMMMd(localeString).add_jm();
    } else {
      _dateFormatter = DateFormat.yMMMd();
      _timeFormatter = DateFormat.jm();

      _dateTimeFormatter = DateFormat.yMMMd().add_jm();
    }
  }

  void _parseInitialValue() {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _parseAndFormatDateTime(widget.initialValue!);
    } else {
      _selectedDateTime = null;
    }
  }

  void _parseControllerText() {
    // If controller already has text (like in signature fields), parse and reformat it
    if (widget.controller != null && _controller.text.isNotEmpty && _selectedDateTime == null) {
      _parseAndFormatDateTime(_controller.text);
    }
  }

  void _onControllerChanged() {
    // Avoid infinite loops when we update the controller ourselves
    if (_isUpdatingFromListener) return;

    // If the controller text looks like an unformatted date, reformat it
    if (_controller.text.isNotEmpty && !_isFormattedText(_controller.text)) {
      try {
        final DateTime dateTime = DateTime.parse(_controller.text);
        _selectedDateTime = dateTime;
        _isUpdatingFromListener = true;
        _updateDisplayText();
        _isUpdatingFromListener = false;
      } catch (e) {
        // If parsing fails, leave the text as is
      }
    }
  }

  // Check if the text already looks like our formatted output
  // This prevents reformatting already-formatted text
  bool _isFormattedText(String text) {
    try {
      final DateTime parsed = DateTime.parse(text);
      final String? formatted = _dateTimeFormatter?.format(parsed);
      return text == formatted;
    } catch (_) {
      return false;
    }
  }

  void _parseAndFormatDateTime(String dateTimeString) {
    try {
      _selectedDateTime = DateTime.parse(dateTimeString);
      _updateDisplayText();
    } catch (e) {
      // Try parsing with different formats
      try {
        _selectedDateTime =
            _dateTimeFormatter?.parse(dateTimeString) ??
            _dateFormatter?.parse(dateTimeString) ??
            DateTime.parse(dateTimeString);
        _updateDisplayText();
      } catch (e) {
        // If all parsing fails, keep the original text
        if (widget.controller == null) {
          _controller.text = dateTimeString;
        }
      }
    }
  }

  void _updateDisplayText() {
    if (_selectedDateTime == null || _dateFormatter == null) {
      // Invalid case
      return;
    }

    _controller.text = switch (widget.type) {
      DateTimePickerType.date => _dateFormatter!.format(_selectedDateTime!),
      DateTimePickerType.time => _timeFormatter!.format(_selectedDateTime!),
      DateTimePickerType.dateTime => _dateTimeFormatter!.format(_selectedDateTime!),
    };
  }

  Future<void> _showPicker() async {
    final DateTime initialDate = _selectedDateTime ?? DateTime.now();
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);

    switch (widget.type) {
      case DateTimePickerType.date:
        await _showDatePicker(initialDate);
      case DateTimePickerType.time:
        await _showTimePicker(initialTime);
      case DateTimePickerType.dateTime:
        await _showDateTimePicker(initialDate, initialTime);
    }
  }

  Future<void> _showDatePicker(DateTime initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      helpText: widget.dateLabelText,
      useRootNavigator: widget.useRootNavigator,
      locale: widget.locale,
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime?.hour ?? 0,
          _selectedDateTime?.minute ?? 0,
        );
        _updateDisplayText();
      });
      _notifyChange();
    }
  }

  Future<void> _showTimePicker(TimeOfDay initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      useRootNavigator: widget.useRootNavigator,
      builder:
          (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
    );

    if (picked != null) {
      final DateTime now = DateTime.now();
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime?.year ?? now.year,
          _selectedDateTime?.month ?? now.month,
          _selectedDateTime?.day ?? now.day,
          picked.hour,
          picked.minute,
        );
        _updateDisplayText();
      });
      _notifyChange();
    }
  }

  Future<void> _showDateTimePicker(DateTime initialDate, TimeOfDay initialTime) async {
    // First show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      helpText: widget.dateLabelText,
      useRootNavigator: widget.useRootNavigator,
      locale: widget.locale,
    );

    if (pickedDate != null && mounted) {
      // Then show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        useRootNavigator: widget.useRootNavigator,
        builder:
            (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _updateDisplayText();
        });
        _notifyChange();
      }
    }
  }

  void _notifyChange() {
    if (widget.onChanged != null && _selectedDateTime != null) {
      // Return ISO string format for consistent datetime serialization
      widget.onChanged!(_selectedDateTime!.toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    readOnly: true,
    style: widget.textStyle ?? const TextStyle(fontSize: 14),
    decoration: widget.decoration ?? const InputDecoration(),
    onTap: _showPicker,
  );
}
