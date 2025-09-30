import 'dart:async';
import 'package:flutter/material.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  Timer? _timer;
  int _elapsedMs = 0;
  bool _isRunning = false;

  void _start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() {
        _elapsedMs += 100;
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    _isRunning = false;
  }

  void _reset() {
    _timer?.cancel();
    _isRunning = false;
    setState(() {
      _elapsedMs = 0;
    });
  }

  String _format(int ms) {
    final seconds = (ms / 1000).floor();
    final minutes = (seconds / 60).floor();
    final hours = (minutes / 60).floor();
    final s = seconds % 60;
    final m = minutes % 60;
    final h = hours;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}.${((ms % 1000) / 100).floor()}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _format(_elapsedMs),
              style: const TextStyle(fontSize: 48, fontFeatures: []),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _start, child: const Text('Bắt đầu')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _pause, child: const Text('Tạm dừng')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _reset, child: const Text('Đặt lại')),
              ],
            )
          ],
        ),
      ),
    );
  }
}


