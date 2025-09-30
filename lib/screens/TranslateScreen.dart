import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Translation
  bool _isTranslatorReady = true;
  
  // Text translation
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  String _sourceLanguage = 'vi';
  String _targetLanguage = 'en';
  bool _isTranslating = false;
  Timer? _debounceTimer;
  String _currentText = '';
  
  // Voice translation
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  int _retryCount = 0;
  Timer? _speechTimeoutTimer;
  
  // Image translation
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _extractedText = '';
  String _translatedImageText = '';
  bool _isProcessingImage = false;
  
  // Language options
  final Map<String, String> _languages = {
    'vi': 'Tiếng Việt',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'ru': 'Русский',
    'ar': 'العربية',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initTranslation();
    _initSpeech();
    _setupAutoTranslation();
  }

  void _setupAutoTranslation() {
    _textController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (_textController.text.isNotEmpty) {
          _translateText();
        } else {
          setState(() {
            _translatedText = '';
          });
        }
      });
    });
  }

  Future<void> _initTranslation() async {
    // Không cần khởi tạo gì cho demo
    setState(() {
      _isTranslatorReady = true;
    });
  }

  Future<void> _initSpeech() async {
    try {
      _speech = stt.SpeechToText();
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: ${error.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            
            // Xử lý các lỗi cụ thể
            String errorMessage = 'Lỗi nhận diện giọng nói';
            if (error.errorMsg.contains('timeout') || error.errorMsg.contains('Error 7')) {
              errorMessage = 'Hết thời gian chờ hoặc không có âm thanh. Vui lòng nói rõ hơn và thử lại.';
              _retryCount++;
            } else if (error.errorMsg.contains('permission')) {
              errorMessage = 'Cần cấp quyền microphone để sử dụng tính năng này.';
            } else if (error.errorMsg.contains('network')) {
              errorMessage = 'Lỗi kết nối mạng. Kiểm tra internet.';
            } else if (error.errorMsg.contains('no_match')) {
              errorMessage = 'Không nhận diện được giọng nói. Hãy nói rõ hơn.';
            } else {
              errorMessage = 'Lỗi: ${error.errorMsg}';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: _retryCount < 3 ? 'Thử lại' : 'Khởi tạo lại',
                  textColor: Colors.white,
                  onPressed: () {
                    if (_retryCount < 3) {
                      _retrySpeechRecognition();
                    } else {
                      _retryCount = 0;
                      _initSpeech();
                    }
                  },
                ),
              ),
            );
          }
        },
        onStatus: (status) {
          print('Speech status: $status');
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
            });
          }
        },
        debugLogging: true,
      );
      
      print('Speech available: $_speechAvailable');
      if (!_speechAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể khởi tạo nhận diện giọng nói. Kiểm tra quyền microphone.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Init speech error: $e');
      _speechAvailable = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _translateText() async {
    if (_textController.text.isEmpty) return;
    
    setState(() {
      _isTranslating = true;
    });

    try {
      // Sử dụng package translator
      final result = await _translateWithTranslatorPackage(
        _textController.text, 
        _sourceLanguage, 
        _targetLanguage
      );
      
      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi dịch thuật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _translateWithTranslatorPackage(String text, String from, String to) async {
    try {
      // Sử dụng Google Translate qua package translator
      final translator = GoogleTranslator();
      
      // Chuyển đổi mã ngôn ngữ
      final fromLang = _convertLanguageCode(from);
      final toLang = _convertLanguageCode(to);
      
      final translation = await translator.translate(text, from: fromLang, to: toLang);
      return translation.text;
    } catch (e) {
      // Fallback: sử dụng từ điển đơn giản
      return _getSimpleTranslation(text, from, to);
    }
  }

  String _convertLanguageCode(String code) {
    // Chuyển đổi mã ngôn ngữ từ format của app sang format của translator
    switch (code) {
      case 'vi': return 'vi';
      case 'en': return 'en';
      case 'ja': return 'ja';
      case 'ko': return 'ko';
      case 'zh': return 'zh';
      case 'fr': return 'fr';
      case 'de': return 'de';
      case 'es': return 'es';
      case 'ru': return 'ru';
      case 'ar': return 'ar';
      default: return 'en';
    }
  }

  String _getSimpleTranslation(String text, String from, String to) {
    // Từ điển dịch đơn giản cho một số từ phổ biến
    final Map<String, Map<String, String>> dictionary = {
      // Tiếng Việt -> Các ngôn ngữ khác
      'chào': {
        'vi': 'chào',
        'en': 'hello',
        'ja': 'こんにちは',
        'ko': '안녕하세요',
        'zh': '你好',
        'fr': 'bonjour',
        'de': 'hallo',
        'es': 'hola',
        'ru': 'привет',
        'ar': 'مرحبا',
      },
      'xin chào': {
        'vi': 'xin chào',
        'en': 'hello',
        'ja': 'こんにちは',
        'ko': '안녕하세요',
        'zh': '你好',
        'fr': 'bonjour',
        'de': 'hallo',
        'es': 'hola',
        'ru': 'привет',
        'ar': 'مرحبا',
      },
      'cảm ơn': {
        'vi': 'cảm ơn',
        'en': 'thank you',
        'ja': 'ありがとう',
        'ko': '감사합니다',
        'zh': '谢谢',
        'fr': 'merci',
        'de': 'danke',
        'es': 'gracias',
        'ru': 'спасибо',
        'ar': 'شكرا',
      },
      'tạm biệt': {
        'vi': 'tạm biệt',
        'en': 'goodbye',
        'ja': 'さようなら',
        'ko': '안녕히 가세요',
        'zh': '再见',
        'fr': 'au revoir',
        'de': 'auf wiedersehen',
        'es': 'adiós',
        'ru': 'до свидания',
        'ar': 'وداعا',
      },
      'tôi': {
        'vi': 'tôi',
        'en': 'I',
        'ja': '私',
        'ko': '나',
        'zh': '我',
        'fr': 'je',
        'de': 'ich',
        'es': 'yo',
        'ru': 'я',
        'ar': 'أنا',
      },
      'bạn': {
        'vi': 'bạn',
        'en': 'you',
        'ja': 'あなた',
        'ko': '당신',
        'zh': '你',
        'fr': 'vous',
        'de': 'sie',
        'es': 'tú',
        'ru': 'ты',
        'ar': 'أنت',
      },
      'tên': {
        'vi': 'tên',
        'en': 'name',
        'ja': '名前',
        'ko': '이름',
        'zh': '名字',
        'fr': 'nom',
        'de': 'name',
        'es': 'nombre',
        'ru': 'имя',
        'ar': 'اسم',
      },
      'tuổi': {
        'vi': 'tuổi',
        'en': 'age',
        'ja': '年齢',
        'ko': '나이',
        'zh': '年龄',
        'fr': 'âge',
        'de': 'alter',
        'es': 'edad',
        'ru': 'возраст',
        'ar': 'عمر',
      },
      'nhà': {
        'vi': 'nhà',
        'en': 'house',
        'ja': '家',
        'ko': '집',
        'zh': '房子',
        'fr': 'maison',
        'de': 'haus',
        'es': 'casa',
        'ru': 'дом',
        'ar': 'منزل',
      },
      'gia đình': {
        'vi': 'gia đình',
        'en': 'family',
        'ja': '家族',
        'ko': '가족',
        'zh': '家庭',
        'fr': 'famille',
        'de': 'familie',
        'es': 'familia',
        'ru': 'семья',
        'ar': 'عائلة',
      },
      
      // Tiếng Anh -> Các ngôn ngữ khác
      'hello': {
        'vi': 'xin chào',
        'en': 'hello',
        'ja': 'こんにちは',
        'ko': '안녕하세요',
        'zh': '你好',
        'fr': 'bonjour',
        'de': 'hallo',
        'es': 'hola',
        'ru': 'привет',
        'ar': 'مرحبا',
      },
      'thank you': {
        'vi': 'cảm ơn',
        'en': 'thank you',
        'ja': 'ありがとう',
        'ko': '감사합니다',
        'zh': '谢谢',
        'fr': 'merci',
        'de': 'danke',
        'es': 'gracias',
        'ru': 'спасибо',
        'ar': 'شكرا',
      },
      'goodbye': {
        'vi': 'tạm biệt',
        'en': 'goodbye',
        'ja': 'さようなら',
        'ko': '안녕히 가세요',
        'zh': '再见',
        'fr': 'au revoir',
        'de': 'auf wiedersehen',
        'es': 'adiós',
        'ru': 'до свидания',
        'ar': 'وداعا',
      },
      'i': {
        'vi': 'tôi',
        'en': 'I',
        'ja': '私',
        'ko': '나',
        'zh': '我',
        'fr': 'je',
        'de': 'ich',
        'es': 'yo',
        'ru': 'я',
        'ar': 'أنا',
      },
      'you': {
        'vi': 'bạn',
        'en': 'you',
        'ja': 'あなた',
        'ko': '당신',
        'zh': '你',
        'fr': 'vous',
        'de': 'sie',
        'es': 'tú',
        'ru': 'ты',
        'ar': 'أنت',
      },
      'name': {
        'vi': 'tên',
        'en': 'name',
        'ja': '名前',
        'ko': '이름',
        'zh': '名字',
        'fr': 'nom',
        'de': 'name',
        'es': 'nombre',
        'ru': 'имя',
        'ar': 'اسم',
      },
      'age': {
        'vi': 'tuổi',
        'en': 'age',
        'ja': '年齢',
        'ko': '나이',
        'zh': '年龄',
        'fr': 'âge',
        'de': 'alter',
        'es': 'edad',
        'ru': 'возраст',
        'ar': 'عمر',
      },
      'house': {
        'vi': 'nhà',
        'en': 'house',
        'ja': '家',
        'ko': '집',
        'zh': '房子',
        'fr': 'maison',
        'de': 'haus',
        'es': 'casa',
        'ru': 'дом',
        'ar': 'منزل',
      },
      'family': {
        'vi': 'gia đình',
        'en': 'family',
        'ja': '家族',
        'ko': '가족',
        'zh': '家庭',
        'fr': 'famille',
        'de': 'familie',
        'es': 'familia',
        'ru': 'семья',
        'ar': 'عائلة',
      },
      'love': {
        'vi': 'yêu',
        'en': 'love',
        'ja': '愛',
        'ko': '사랑',
        'zh': '爱',
        'fr': 'amour',
        'de': 'liebe',
        'es': 'amor',
        'ru': 'любовь',
        'ar': 'حب',
      },
      'water': {
        'vi': 'nước',
        'en': 'water',
        'ja': '水',
        'ko': '물',
        'zh': '水',
        'fr': 'eau',
        'de': 'wasser',
        'es': 'agua',
        'ru': 'вода',
        'ar': 'ماء',
      },
      'food': {
        'vi': 'thức ăn',
        'en': 'food',
        'ja': '食べ物',
        'ko': '음식',
        'zh': '食物',
        'fr': 'nourriture',
        'de': 'essen',
        'es': 'comida',
        'ru': 'еда',
        'ar': 'طعام',
      },
    };

    final lowerText = text.toLowerCase().trim();
    if (dictionary.containsKey(lowerText) && 
        dictionary[lowerText]!.containsKey(to)) {
      return dictionary[lowerText]![to]!;
    }

    // Nếu không tìm thấy trong từ điển, trả về text gốc với prefix
    if (from == 'vi' && to == 'en') {
      return 'Translated: $text';
    } else if (from == 'en' && to == 'vi') {
      return 'Đã dịch: $text';
    } else {
      return 'Dịch ($from → $to): $text';
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nhận diện giọng nói không khả dụng. Kiểm tra quyền microphone.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _initSpeech();
              },
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _recognizedText = '';
      _isListening = true;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          
          // Tự động dịch khi có kết quả cuối cùng
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _translateRecognizedText(result.recognizedWords);
          }
        },
        localeId: _sourceLanguage == 'vi' ? 'vi_VN' : 'en_US',
        listenFor: const Duration(seconds: 15), // Tăng thời gian nghe
        pauseFor: const Duration(seconds: 2), // Giảm thời gian pause
        partialResults: true,
        cancelOnError: false, // Không tự động hủy khi có lỗi
        listenMode: stt.ListenMode.dictation, // Thay đổi mode để ổn định hơn
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
      );
      
      // Thêm timeout timer để tự động dừng nếu không có âm thanh
      _speechTimeoutTimer?.cancel();
      _speechTimeoutTimer = Timer(const Duration(seconds: 12), () {
        if (_isListening && _recognizedText.isEmpty) {
          print('Auto-stopping due to no speech detected');
          _stopListening();
        }
      });
    } catch (e) {
      print('Start listening error: $e');
      setState(() {
        _isListening = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi bắt đầu nghe: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _startListening();
              },
            ),
          ),
        );
      }
    }
  }

  void _startListeningForText() async {
    print('Starting voice input...');
    print('Speech available: $_speechAvailable');
    
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nhận diện giọng nói không khả dụng. Kiểm tra quyền microphone.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _initSpeech();
              },
            ),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      // Nếu đang nghe thì dừng lại
      print('Stopping voice input...');
      _stopListening();
      return;
    }

    print('Starting speech recognition...');
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          print('Speech result: ${result.recognizedWords}');
          print('Final result: ${result.finalResult}');
          
          // Cập nhật text field realtime với partial results
          if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _currentText = result.recognizedWords;
            });
            
            // Cập nhật TextField trực tiếp
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: result.recognizedWords.length),
            );
            
            print('Updated text field with: ${result.recognizedWords}');
            
            // Chỉ dịch khi có kết quả cuối cùng để tránh spam API
            if (result.finalResult) {
              print('Final result, translating...');
              _translateText();
            }
          }
        },
        localeId: _sourceLanguage == 'vi' ? 'vi_VN' : 'en_US',
        listenFor: const Duration(seconds: 15), // Tăng thời gian nghe
        pauseFor: const Duration(seconds: 2), // Giảm thời gian pause
        partialResults: true,
        cancelOnError: false, // Không tự động hủy khi có lỗi
        listenMode: stt.ListenMode.dictation, // Thay đổi mode để ổn định hơn
        onSoundLevelChange: (level) {
          // Có thể thêm visual feedback cho âm thanh
          print('Sound level: $level');
        },
      );
      
      // Thêm timeout timer để tự động dừng nếu không có âm thanh
      _speechTimeoutTimer?.cancel();
      _speechTimeoutTimer = Timer(const Duration(seconds: 12), () {
        if (_isListening && _recognizedText.isEmpty) {
          print('Auto-stopping due to no speech detected');
          _stopListening();
        }
      });
    } catch (e) {
      print('Speech listen error: $e');
      setState(() {
        _isListening = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi bắt đầu nghe: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _startListeningForText();
              },
            ),
          ),
        );
      }
    }
  }

  void _stopListening() async {
    try {
      // Hủy timeout timer
      _speechTimeoutTimer?.cancel();
      
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      
      // Dịch text cuối cùng nếu có
      if (_textController.text.isNotEmpty) {
        _translateText();
      }
      
      print('Stopped listening successfully');
    } catch (e) {
      print('Stop listening error: $e');
      setState(() {
        _isListening = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi dừng nghe: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _testMicrophone() async {
    print('Testing microphone...');
    try {
      // Thử khởi tạo lại speech recognition
      _speech = stt.SpeechToText();
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          print('Test error: ${error.errorMsg}');
        },
        onStatus: (status) {
          print('Test status: $status');
        },
        debugLogging: true,
      );
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test microphone: ${_speechAvailable ? "Thành công" : "Thất bại"}'),
            backgroundColor: _speechAvailable ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Test microphone error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi test microphone: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _checkMicrophonePermission() async {
    try {
      // Kiểm tra quyền microphone
      final status = await _speech.hasPermission;
      print('Microphone permission status: $status');
      return status;
    } catch (e) {
      print('Check permission error: $e');
      return false;
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cấp quyền microphone trong Settings của thiết bị'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Request permission error: $e');
    }
  }

  void _retrySpeechRecognition() async {
    print('Retrying speech recognition... Attempt: ${_retryCount + 1}');
    
    // Dừng speech hiện tại nếu đang chạy
    if (_isListening) {
      await _speech.stop();
    }
    
    // Đợi một chút trước khi thử lại
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Thử lại với cấu hình khác nhau
    try {
      await _speech.listen(
        onResult: (result) {
          print('Retry speech result: ${result.recognizedWords}');
          if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _currentText = result.recognizedWords;
              _retryCount = 0; // Reset retry count on success
            });
            
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: result.recognizedWords.length),
            );
            
            if (result.finalResult) {
              _translateText();
            }
          }
        },
        localeId: _sourceLanguage == 'vi' ? 'vi_VN' : 'en_US',
        listenFor: const Duration(seconds: 20), // Tăng thời gian cho retry
        pauseFor: const Duration(seconds: 1), // Giảm pause time
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        onSoundLevelChange: (level) {
          print('Retry sound level: $level');
        },
      );
      
      setState(() {
        _isListening = true;
      });
      
      // Thêm timeout timer để tự động dừng nếu không có âm thanh
      _speechTimeoutTimer?.cancel();
      _speechTimeoutTimer = Timer(const Duration(seconds: 10), () {
        if (_isListening && _recognizedText.isEmpty) {
          print('Auto-stopping due to no speech detected');
          _stopListening();
        }
      });
      
    } catch (e) {
      print('Retry speech error: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _translateRecognizedText(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await _translateWithTranslatorPackage(text, _sourceLanguage, _targetLanguage);
      
      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã dịch: "$text" → "$result"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi dịch giọng nói: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isProcessingImage = true;
        });
        await _extractTextFromImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extractTextFromImage() async {
    if (_selectedImage == null) return;

    try {
      // Demo text extraction - thay thế bằng ML Kit thật
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      
      setState(() {
        _extractedText = 'Demo extracted text from image';
      });
      
      // Dịch text đã trích xuất
      if (_extractedText.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate translation
        setState(() {
          _translatedImageText = 'Demo translation: $_extractedText';
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi nhận diện text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _swapLanguages() async {
    final temp = _sourceLanguage;
    setState(() {
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _speech.cancel();
    _debounceTimer?.cancel();
    _speechTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Language selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildLanguageDropdown(_sourceLanguage, (value) {
                    setState(() {
                      _sourceLanguage = value!;
                    });
                    _initTranslation();
                  }),
                ),
                IconButton(
                  onPressed: _swapLanguages,
                  icon: const Icon(Icons.swap_horiz),
                ),
                Expanded(
                  child: _buildLanguageDropdown(_targetLanguage, (value) {
                    setState(() {
                      _targetLanguage = value!;
                    });
                    _initTranslation();
                  }),
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.text_fields), text: 'Text (7đ)'),
              Tab(icon: Icon(Icons.mic), text: 'Voice (9đ)'),
              Tab(icon: Icon(Icons.camera_alt), text: 'Image (10đ)'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTranslationTab(),
                _buildVoiceTranslationTab(),
                _buildImageTranslationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(String value, Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      onChanged: onChanged,
      items: _languages.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildTextTranslationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Text input area
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Source text
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _languages[_sourceLanguage] ?? _sourceLanguage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Nút microphone
                          IconButton(
                            onPressed: _speechAvailable ? _startListeningForText : _testMicrophone,
                            icon: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              size: 20,
                              color: _isListening ? Colors.red : (_speechAvailable ? Colors.blue : Colors.grey),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: _isListening ? 'Dừng nghe' : (_speechAvailable ? 'Nói để nhập text' : 'Test microphone'),
                          ),
                          const SizedBox(width: 8),
                          // Nút xóa
                          if (_textController.text.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _textController.clear();
                                setState(() {
                                  _translatedText = '';
                                });
                              },
                              icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Xóa text',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Nhập văn bản hoặc nhấn mic để nói...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          _currentText = value;
                        },
                      ),
                      // Hiển thị trạng thái voice realtime
                      if (_isListening) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _recognizedText.isNotEmpty ? Colors.green.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _recognizedText.isNotEmpty ? Colors.green.shade200 : Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _recognizedText.isNotEmpty ? Icons.check_circle : Icons.mic,
                                color: _recognizedText.isNotEmpty ? Colors.green : Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _recognizedText.isNotEmpty 
                                    ? 'Đã nhận diện: $_recognizedText'
                                    : 'Đang nghe... Nói vào microphone',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _recognizedText.isNotEmpty ? Colors.green.shade700 : Colors.blue.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                
                // Translation result
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _languages[_targetLanguage] ?? _targetLanguage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (_isTranslating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_translatedText.isNotEmpty)
                        Text(
                          _translatedText,
                          style: const TextStyle(fontSize: 16),
                        )
                      else if (_textController.text.isNotEmpty && !_isTranslating)
                        Text(
                          'Đang dịch...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Text(
                          'Bản dịch sẽ xuất hiện ở đây',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Copy button
          if (_translatedText.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _translatedText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép bản dịch'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Sao chép'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _textController.text = _translatedText;
                      _swapLanguages();
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Hoán đổi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceTranslationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Voice input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Trạng thái: ${_speechAvailable ? "Sẵn sàng" : "Không khả dụng"}',
                  style: TextStyle(
                    color: _speechAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_retryCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đã thử lại: $_retryCount lần',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _speechAvailable && !_isListening ? _startListening : null,
                      icon: const Icon(Icons.mic),
                      label: const Text('Bắt đầu nghe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isListening ? _stopListening : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Dừng nghe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Hiển thị văn bản đã nhận diện
          if (_recognizedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Văn bản đã nhận diện:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Hiển thị kết quả dịch
          if (_translatedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết quả dịch:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _translatedText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
          
          // Hiển thị trạng thái đang dịch
          if (_isTranslating) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Text('Đang dịch...'),
                ],
              ),
            ),
          ],
          
          // Hướng dẫn sử dụng
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Hướng dẫn:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('• Nhấn "Bắt đầu nghe" và nói rõ ràng'),
                const Text('• Ứng dụng sẽ tự động dịch sau khi nhận diện'),
                const Text('• Nhấn "Dừng nghe" để kết thúc'),
                const Text('• Nói chậm và rõ ràng để có kết quả tốt nhất'),
                const Text('• Đảm bảo môi trường yên tĩnh'),
                if (!_speechAvailable) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️ Nhận diện giọng nói không khả dụng',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Kiểm tra quyền microphone',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Đảm bảo kết nối internet ổn định',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Thử khởi động lại ứng dụng',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _testMicrophone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 32),
                          ),
                          child: const Text('Kiểm tra lại', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTranslationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Image picker
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp ảnh'),
          ),
          const SizedBox(height: 16),
          
          // Image display
          if (_selectedImage != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
          ],
          
          // Processing indicator
          if (_isProcessingImage)
            const CircularProgressIndicator(),
          
          // Extracted text
          if (_extractedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text đã trích xuất:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_extractedText),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Translated text
          if (_translatedImageText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text đã dịch:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_translatedImageText),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
