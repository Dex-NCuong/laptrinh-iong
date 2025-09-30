import 'package:flutter/material.dart';

class TemperatureConverterScreen extends StatefulWidget {
  const TemperatureConverterScreen({super.key});
  
  @override
  _TemperatureConverterScreenState createState() =>
      _TemperatureConverterScreenState();
}

class _TemperatureConverterScreenState
    extends State<TemperatureConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  double? _convertedTemperature;
  bool _isCelsiusToFahrenheit = true;

  void _convertTemperature() {
    setState(() {
      final input = double.tryParse(_controller.text);
      if (input != null) {
        if (_isCelsiusToFahrenheit) {
          _convertedTemperature = input * 9 / 5 + 32; // C -> F
        } else {
          _convertedTemperature = (input - 32) * 5 / 9; // F -> C
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nhập nhiệt độ:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Nhập nhiệt độ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Celsius → Fahrenheit'),
                Switch(
                  value: _isCelsiusToFahrenheit,
                  onChanged: (v) {
                    setState(() {
                      _isCelsiusToFahrenheit = v;
                    });
                  },
                ),
                const Text('Fahrenheit → Celsius'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _convertedTemperature == null
                  ? 'Kết quả sẽ hiển thị ở đây'
                  : _isCelsiusToFahrenheit
                  ? 'Kết quả: ${_convertedTemperature!.toStringAsFixed(1)} °F'
                  : 'Kết quả: ${_convertedTemperature!.toStringAsFixed(1)} °C',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _convertTemperature,
              child: const Text('Chuyển đổi'),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }
}