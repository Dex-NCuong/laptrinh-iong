import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _savedPhone = '';

  @override
  void initState() {
    super.initState();
    // Có thể load số điện thoại đã lưu từ SharedPreferences ở đây
    _phoneController.text = _savedPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Hàm gọi điện trực tiếp
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Fallback: mở dialer với số điện thoại
        await _openDialer(phoneNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e. Thử mở dialer thay thế.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Mở Dialer',
              onPressed: () => _openDialer(phoneNumber),
            ),
          ),
        );
      }
    }
  }

  // Hàm mở dialer (không gọi trực tiếp)
  Future<void> _openDialer(String phoneNumber) async {
    final Uri dialerUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      await launchUrl(
        dialerUri,
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở dialer. Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm gửi SMS
  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở ứng dụng tin nhắn.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm mở YouTube app
  Future<void> _openYouTubeApp() async {
    const String youtubeUrl = 'https://www.youtube.com';
    final Uri youtubeUri = Uri.parse(youtubeUrl);
    
    if (await canLaunchUrl(youtubeUri)) {
      await launchUrl(
        youtubeUri,
        mode: LaunchMode.externalApplication, // Mở trong app YouTube nếu có
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở YouTube. Vui lòng kiểm tra lại kết nối mạng.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm lưu số điện thoại
  void _savePhoneNumber() {
    setState(() {
      _savedPhone = _phoneController.text.trim();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu số điện thoại: $_savedPhone'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Hàm copy số điện thoại vào clipboard
  void _copyToClipboard(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã copy số điện thoại: $phoneNumber'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Avatar và thông tin cá nhân
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.deepOrange,
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Phần cài đặt số điện thoại
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số điện thoại',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '💡 Lưu ý: Nếu không gọi được, hãy thử "Dialer" hoặc test trên thiết bị thật',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Nhập số điện thoại',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nút Lưu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _savePhoneNumber,
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu số điện thoại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Các nút hành động
                    if (_savedPhone.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(_savedPhone),
                              icon: const Icon(Icons.call),
                              label: const Text('Gọi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openDialer(_savedPhone),
                              icon: const Icon(Icons.dialpad),
                              label: const Text('Dialer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _sendSMS(_savedPhone),
                              icon: const Icon(Icons.message),
                              label: const Text('SMS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _copyToClipboard(_savedPhone),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Vui lòng nhập và lưu số điện thoại trước',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Phần mở YouTube
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YouTube',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Mở ứng dụng YouTube để xem video',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openYouTubeApp,
                        icon: const Icon(Icons.play_circle_filled),
                        label: const Text('Mở YouTube'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Thông tin bổ sung
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin ứng dụng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const ListTile(
                      leading: Icon(Icons.info, color: Colors.blue),
                      title: Text('Phiên bản'),
                      subtitle: Text('1.0.0'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.developer_mode, color: Colors.green),
                      title: Text('Nhà phát triển'),
                      subtitle: Text('Đào Nhật Cường'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.email, color: Colors.orange),
                      title: Text('Email'),
                      subtitle: Text('daonhatcuong@example.com'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Thêm khoảng cách cuối
          ],
        ),
      ),
    );
  }
}
