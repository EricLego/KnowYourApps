import 'package:flutter/material.dart';

class MoodSlider extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onChangeEnd;

  const MoodSlider({
    Key? key,
    this.initialValue = 0,
    this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

  @override
  _MoodSliderState createState() => _MoodSliderState();
}

class _MoodSliderState extends State<MoodSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.toDouble();
  }

  @override
  void didUpdateWidget(MoodSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _currentValue = widget.initialValue.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Very Bad'),
            Text('Neutral'),
            const Text('Excellent'),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getSliderColor(_currentValue),
            inactiveTrackColor: _getSliderColor(_currentValue).withOpacity(0.3),
            thumbColor: _getSliderColor(_currentValue),
            overlayColor: _getSliderColor(_currentValue).withOpacity(0.3),
            valueIndicatorColor: _getSliderColor(_currentValue),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: Slider(
            min: -10,
            max: 10,
            divisions: 20,
            value: _currentValue,
            label: _currentValue.round().toString(),
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(value.round());
              }
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd!(value.round());
              }
            },
          ),
        ),
      ],
    );
  }

  Color _getSliderColor(double value) {
    if (value >= 5) {
      return Colors.green;
    } else if (value >= 0) {
      return Colors.lightGreen;
    } else if (value >= -5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}