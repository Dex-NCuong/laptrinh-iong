import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';


class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({super.key});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  final TextEditingController _controller = TextEditingController();
  YoutubePlayerController? _ytController;

  void _loadVideo() {
    final url = _controller.text.trim();
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link Youtube không hợp lệ')),
      );
      return;
    }
    final newController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
    setState(() {
      _ytController?.dispose();
      _ytController = newController;
    });
  }

  @override
  void dispose() {
    _ytController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nhập link YouTube:'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'https://www.youtube.com/watch?v=...'
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadVideo,
                  child: const Text('Xem'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ytController != null)
              Expanded(
                child: YoutubePlayer(
                  controller: _ytController!,
                  showVideoProgressIndicator: true,
                ),
              )
            else
              const Expanded(
                child: Center(child: Text('Video sẽ hiển thị ở đây')),
              ),
          ],
        ),
      ),
    );
  }
}


