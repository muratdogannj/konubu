import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/utils/date_helper.dart';

class LiveTimeAgoText extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const LiveTimeAgoText({
    super.key,
    required this.dateTime,
    this.style,
  });

  @override
  State<LiveTimeAgoText> createState() => _LiveTimeAgoTextState();
}

class _LiveTimeAgoTextState extends State<LiveTimeAgoText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every minute (60 seconds)
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateHelper.getTimeAgo(widget.dateTime),
      style: widget.style,
    );
  }
}
