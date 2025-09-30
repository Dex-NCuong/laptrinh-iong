import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({Key? key}) : super(key: key);

  @override
  _UnitConverterScreenState createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  double? _convertedValue;
  bool _isMetersToFeet = true;

  void _convertUnits() {
    setState(() {
      final input = double.tryParse(_controller.text);
      if (input != null) {
        if (_isMetersToFeet) {
          _convertedValue = input * 3.28084; // M -> Ft
        } else {
          _convertedValue = input / 3.28084; // Ft -> M
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
              'Nhập giá trị:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Nhập giá trị',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mét → Feet'),
                Switch(
                  value: _isMetersToFeet,
                  onChanged: (v) {
                    setState(() {
                      _isMetersToFeet = v;
                    });
                  },
                ),
                const Text('Feet → Mét'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _convertedValue == null
                  ? 'Kết quả sẽ hiển thị ở đây'
                  : _isMetersToFeet
                  ? 'Kết quả: ${_convertedValue!.toStringAsFixed(2)} ft'
                  : 'Kết quả: ${_convertedValue!.toStringAsFixed(2)} m',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _convertUnits,
              child: const Text('Chuyển đổi'),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }
}