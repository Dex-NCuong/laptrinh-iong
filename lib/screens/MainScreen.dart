import 'package:flutter/material.dart';
import 'TemperatureConverterScreen.dart';
import 'UnitConverterScreen.dart';
import 'YouTubePlayerScreen.dart';
import 'StopwatchScreen.dart';
import 'AlarmScreen.dart';
import 'HomeScreen.dart';
import 'ProfileScreen.dart';
import 'TranslateScreen.dart';
import 'GroupInfoScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // Danh sách các màn hình
  final List<Widget> _screens = [
    const HomeScreen(),
    const TemperatureConverterScreen(),
    const UnitConverterScreen(),
    const YouTubePlayerScreen(),
    const StopwatchScreen(),
    const AlarmScreen(),
    const TranslateScreen(),
    const GroupInfoScreen(),
    const ProfileScreen(),
  ];

  // Danh sách các tiêu đề cho AppBar
  final List<String> _titles = [
    'Trang chủ',
    'Chuyển đổi nhiệt độ',
    'Chuyển đổi đơn vị đo',
    'Xem video YouTube',
    'Đồng hồ bấm giờ',
    'Đồng hồ báo thức',
    'Dịch thuật',
    'Thông tin nhóm',
    'Cá nhân',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat),
            label: 'Nhiệt độ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.straighten),
            label: 'Đơn vị đo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: 'YouTube',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Bấm giờ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Báo thức',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: 'Dịch thuật',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Nhóm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

