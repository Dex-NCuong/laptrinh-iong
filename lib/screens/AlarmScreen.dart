import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  TimeOfDay _time = TimeOfDay.now();
  final AudioPlayer _player = AudioPlayer();
  bool _isRinging = false;
  
  // Speech-to-text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _initSpeech();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('ic_notification');
    const InitializationSettings initSettings = InitializationSettings(android: initAndroid);
    await _notifications.initialize(initSettings);
    tz.initializeTimeZones();
    // Đặt mặc định múi giờ Việt Nam để tránh phụ thuộc plugin
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> _initSpeech() async {
    try {
      _speech = stt.SpeechToText();
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            // Chỉ hiển thị lỗi quan trọng
            if (error.errorMsg != 'error_no_match') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${error.errorMsg}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      _speechAvailable = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể khởi tạo nhận diện giọng nói: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhận diện giọng nói không khả dụng. Sử dụng nút "Chọn giờ" thay thế.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _recognizedText = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          
          // Xử lý ngay khi có kết quả
          if (result.recognizedWords.isNotEmpty) {
            _processVoiceCommand(result.recognizedWords);
          }
        },
        localeId: 'vi_VN',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi bắt đầu nghe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _processVoiceCommand(String text) {
    final lowerText = text.toLowerCase().trim();
    
    if (lowerText.isEmpty) return;
    
    // Hiển thị văn bản nhận diện được (không spam thông báo)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã nghe: "$text"'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
    }
    
    // Pattern đơn giản để nhận diện thời gian
    final timePattern = RegExp(r'(\d{1,2})\s*(giờ|h|:|\.)\s*(\d{0,2})');
    final match = timePattern.firstMatch(lowerText);
    
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minute = int.tryParse(match.group(3) ?? '0') ?? 0;
      
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        setState(() {
          _time = TimeOfDay(hour: hour, minute: minute);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã đặt: ${_time.format(context)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }
    
    // Xử lý lệnh đặt báo thức
    if (lowerText.contains('đặt báo thức') || lowerText.contains('báo thức')) {
      _scheduleAlarm();
    } else if (lowerText.contains('dừng') || lowerText.contains('tắt')) {
      _stopListening();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _scheduleAlarm() async {
    final nowTz = tz.TZDateTime.now(tz.local);
    var tzScheduled = tz.TZDateTime(tz.local, nowTz.year, nowTz.month, nowTz.day, _time.hour, _time.minute);
    if (!tzScheduled.isAfter(nowTz)) {
      tzScheduled = tzScheduled.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_loud',
      'Báo thức',
      channelDescription: 'Thông báo báo thức có âm thanh',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      icon: 'ic_notification',
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.zonedSchedule(
      0,
      'Báo thức',
      'Đến giờ rồi!',
      tzScheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // Một lần duy nhất vào đúng thời điểm
    );
    // Dự phòng: phát âm thanh trong app vào đúng thời điểm
    final duration = tzScheduled.difference(DateTime.now());
    Future.delayed(duration.isNegative ? Duration.zero : duration, () async {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/alarm.mp3'));
      if (mounted) {
        setState(() {
          _isRinging = true;
        });
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã đặt báo thức: ${_time.format(context)}')),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Giờ đã chọn: ${_time.format(context)}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            
            // Hiển thị văn bản nhận diện được
            if (_recognizedText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Văn bản nhận diện:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recognizedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
            
            // Nút nhận diện giọng nói
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'Dừng nghe' : 'Nói thời gian'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: const Text('Chọn giờ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Trạng thái nhận diện
            if (_isListening) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Đang nghe... Nói "7 giờ 30"',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Hướng dẫn đơn giản
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎤 Giọng nói: ${_speechAvailable ? "Sẵn sàng" : "Không khả dụng"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _speechAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('• Nói "7 giờ 30" hoặc "8 giờ"'),
                  const Text('• Nói "đặt báo thức" để kích hoạt'),
                  if (!_speechAvailable) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '💡 Sử dụng nút "Chọn giờ" thay thế',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _scheduleAlarm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Đặt báo thức', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            if (_isRinging)
              ElevatedButton(
                onPressed: () async {
                  await _player.stop();
                  if (mounted) {
                    setState(() {
                      _isRinging = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Dừng chuông'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _player.play(AssetSource('sounds/alarm.mp3')),
              child: const Text('Test phát âm thanh ngay'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await _player.stop();
                if (mounted) setState(() => _isRinging = false);
              },
              child: const Text('Dừng tiếng (test)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                const android = AndroidNotificationDetails(
                  'alarm_channel_loud',
                  'Báo thức',
                  channelDescription: 'Test sau 5 giây (show) ',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  sound: RawResourceAndroidNotificationSound('alarm'),
                  category: AndroidNotificationCategory.alarm,
                  audioAttributesUsage: AudioAttributesUsage.alarm,
                  icon: 'ic_notification',
                );
                const details = NotificationDetails(android: android);
                await Future.delayed(const Duration(seconds: 5));
                await _notifications.show(
                  100,
                  'Test báo thức',
                  'Hiển thị sau 5 giây',
                  details,
                );
              },
              child: const Text('Test thông báo sau 5 giây'),
            ),
            const SizedBox(height: 16),
            const Text('Lưu ý: thêm file âm thanh assets/android/app/src/main/res/raw/alarm.mp3 hoặc raw/alarm.wav'),
          ],
        ),
      ),
    );
  }
}


