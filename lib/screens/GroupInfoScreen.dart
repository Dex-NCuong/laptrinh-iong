import 'package:flutter/material.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Thông tin các thành viên trong nhóm
  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Nguyễn Văn A',
      'role': 'Leader',
      'studentId': '21110001',
      'class': '21CTT1',
      'email': 'nguyenvana@student.hcmus.edu.vn',
      'phone': '0123456789',
      'avatar': 'assets/images/member1.png',
      'description': 'Chuyên về phát triển ứng dụng di động và quản lý dự án. Có kinh nghiệm với Flutter, React Native và các công nghệ web hiện đại.',
      'skills': ['Flutter', 'Dart', 'React Native', 'JavaScript', 'Project Management'],
      'hobbies': ['Đọc sách', 'Chơi game', 'Du lịch', 'Nấu ăn'],
    },
    {
      'name': 'Trần Thị B',
      'role': 'Developer',
      'studentId': '21110002',
      'class': '21CTT1',
      'email': 'tranthib@student.hcmus.edu.vn',
      'phone': '0123456790',
      'avatar': 'assets/images/member2.png',
      'description': 'Chuyên về UI/UX Design và Frontend Development. Yêu thích tạo ra những giao diện đẹp mắt và trải nghiệm người dùng tốt.',
      'skills': ['UI/UX Design', 'Figma', 'HTML/CSS', 'JavaScript', 'React'],
      'hobbies': ['Vẽ tranh', 'Thiết kế', 'Xem phim', 'Nghe nhạc'],
    },
    {
      'name': 'Lê Văn C',
      'role': 'Developer',
      'studentId': '21110003',
      'class': '21CTT1',
      'email': 'levanc@student.hcmus.edu.vn',
      'phone': '0123456791',
      'avatar': 'assets/images/member3.png',
      'description': 'Chuyên về Backend Development và Database Management. Có kinh nghiệm với các hệ thống phân tán và microservices.',
      'skills': ['Java', 'Spring Boot', 'MySQL', 'MongoDB', 'Docker'],
      'hobbies': ['Lập trình', 'Đọc tech blogs', 'Chơi cờ', 'Chạy bộ'],
    },
    {
      'name': 'Phạm Thị D',
      'role': 'Tester',
      'studentId': '21110004',
      'class': '21CTT1',
      'email': 'phamthid@student.hcmus.edu.vn',
      'phone': '0123456792',
      'avatar': 'assets/images/member4.png',
      'description': 'Chuyên về Software Testing và Quality Assurance. Đảm bảo chất lượng sản phẩm và trải nghiệm người dùng tốt nhất.',
      'skills': ['Manual Testing', 'Automated Testing', 'Selenium', 'Jest', 'Postman'],
      'hobbies': ['Đọc sách', 'Xem anime', 'Nấu ăn', 'Chụp ảnh'],
    },
    {
      'name': 'Hoàng Văn E',
      'role': 'Designer',
      'studentId': '21110005',
      'class': '21CTT1',
      'email': 'hoangvane@student.hcmus.edu.vn',
      'phone': '0123456793',
      'avatar': 'assets/images/member5.png',
      'description': 'Chuyên về Graphic Design và Branding. Tạo ra những thiết kế sáng tạo và phù hợp với từng dự án.',
      'skills': ['Photoshop', 'Illustrator', 'After Effects', 'Branding', 'Logo Design'],
      'hobbies': ['Thiết kế', 'Vẽ tranh', 'Chụp ảnh', 'Du lịch'],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin nhóm'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header với thông tin nhóm
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.group,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nhóm phát triển ứng dụng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_members.length} thành viên',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // PageView để hiển thị thông tin từng thành viên
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _members.length,
              itemBuilder: (context, index) {
                return _buildMemberCard(_members[index]);
              },
            ),
          ),
          
          // Dots indicator
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _members.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 12 : 8,
                  height: _currentIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index 
                        ? Colors.blue.shade600 
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0 ? _previousMember : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Trước'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentIndex < _members.length - 1 ? _nextMember : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar và thông tin cơ bản
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              member['name'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member['role'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Thông tin chi tiết
            _buildInfoSection('Thông tin cá nhân', [
              _buildInfoRow(Icons.badge, 'MSSV', member['studentId']),
              _buildInfoRow(Icons.class_, 'Lớp', member['class']),
              _buildInfoRow(Icons.email, 'Email', member['email']),
              _buildInfoRow(Icons.phone, 'SĐT', member['phone']),
            ]),
            
            const SizedBox(height: 20),
            
            // Mô tả
            _buildInfoSection('Giới thiệu', [
              Text(
                member['description'],
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ]),
            
            const SizedBox(height: 20),
            
            // Kỹ năng
            _buildInfoSection('Kỹ năng', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (member['skills'] as List<String>).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
            
            const SizedBox(height: 20),
            
            // Sở thích
            _buildInfoSection('Sở thích', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (member['hobbies'] as List<String>).map((hobby) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      hobby,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousMember() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextMember() {
    if (_currentIndex < _members.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
