import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:temple_adventures_admin/theme.dart';
import '../../../../utils/styling/spacing_widgets.dart';

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key, required this.onChanged, this.label, required this.initialValue});

  final ValueChanged<int> onChanged;
  final String? label;
  final int initialValue;

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late int counter;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    counter = widget.initialValue.clamp(0, 99);
    controller = TextEditingController(text: counter.toString());
  }

  @override
  void didUpdateWidget(covariant CounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      counter = widget.initialValue.clamp(0, 99);
      controller.text = counter.toString();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _updateCounter(int newValue) {
    if (newValue != counter && newValue >= 0 && newValue <= 99) {
      setState(() {
        counter = newValue;
        controller.text = counter.toString();
        widget.onChanged(counter);
      });
    }
  }

  void _onTextChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= 99) {
      _updateCounter(parsed);
    }
  }

  Widget _buildButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(color: lightSkyBlue, borderRadius: BorderRadius.circular(3)),
        child: Icon(icon, size: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.label != null)
          SizedBox(
            width: 40,
            child: Center(
              child: Text(widget.label!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        Spacing.h15,
        Row(
          children: [
            _buildButton(icon: Icons.remove, onPressed: () => _updateCounter(counter - 1)),
            Spacing.w15,
            SizedBox(
              width: 35,
              height: 20,
              child: TextField(
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                onChanged: _onTextChanged,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
              ),
            ),
            Spacing.w15,
            _buildButton(icon: Icons.add, onPressed: () => _updateCounter(counter + 1)),
          ],
        ),
      ],
    );
  }
}
