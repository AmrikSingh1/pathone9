import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:lottie/lottie.dart';

class TestVideoPlayerPage extends StatefulWidget {
  const TestVideoPlayerPage({super.key});

  @override
  State<TestVideoPlayerPage> createState() => _TestVideoPlayerPageState();
}

class _TestVideoPlayerPageState extends State<TestVideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMsg = '';
      _chewieController = null;
    });

    try {
      // Sample video URL - replace with your own
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
      );

      await _videoPlayerController!.initialize();
      
      // Add listener for buffering state
      _videoPlayerController!.addListener(_checkBuffering);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
        showControls: true,
        showOptions: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializePlayer,
                  child: const Text('Reload Video'),
                ),
              ],
            ),
          );
        },
      );
      
      _chewieController!.play();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMsg = e.toString();
      });
      print('Error initializing video player: $e');
    }
  }

  void _checkBuffering() {
    if (_videoPlayerController != null) {
      final isBuffering = _videoPlayerController!.value.isBuffering;
      
      // Only update state if there's a change in buffering state
      if (isBuffering != _isBuffering) {
        setState(() {
          _isBuffering = isBuffering;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_checkBuffering);
      _videoPlayerController!.dispose();
    }
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Video Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializePlayer,
          )
        ],
      ),
      body: Column(
        children: [
          // Animation test section
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Lottie.asset(
              'assets/animations/start.json',
              fit: BoxFit.contain,
              animate: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Video player section
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Show error message if there's an error
                if (_hasError)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'Error: $_errorMsg',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializePlayer,
                          child: const Text('Reload Video'),
                        ),
                      ],
                    ),
                  )
                // Show the video player if initialized
                else if (_chewieController != null)
                  Chewie(controller: _chewieController!),
                
                // Show loading indicator while loading
                if (_isLoading)
                  const CircularProgressIndicator(),
                
                // Show buffering indicator when buffering
                if (_isBuffering && !_isLoading)
                  const CircularProgressIndicator(),
              ],
            ),
          ),
          
          // Debugging info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Video state: ${_isLoading ? "Loading" : _isBuffering ? "Buffering" : "Playing"}'),
                if (_videoPlayerController != null)
                  Text('Position: ${_videoPlayerController!.value.position.toString().split('.').first}'),
                if (_videoPlayerController != null)
                  Text('Duration: ${_videoPlayerController!.value.duration.toString().split('.').first}'),
                Text('Buffering: $_isBuffering'),
                Text('Has error: $_hasError'),
                
                // Display buttons to test other animations
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _AnimationTestPage(
                                animationPath: 'assets/animations/ai_tests.json',
                                title: 'AI Tests',
                              ),
                            ),
                          );
                        },
                        child: const Text('AI Tests'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _AnimationTestPage(
                                animationPath: 'assets/animations/searching_career.json',
                                title: 'Career Search',
                              ),
                            ),
                          );
                        },
                        child: const Text('Career Search'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _AnimationTestPage(
                                animationPath: 'assets/animations/thinking_about_career.json',
                                title: 'Career Thinking',
                              ),
                            ),
                          );
                        },
                        child: const Text('Career Thinking'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimationTestPage extends StatelessWidget {
  final String animationPath;
  final String title;

  const _AnimationTestPage({
    required this.animationPath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animation: $title'),
      ),
      body: Center(
        child: Lottie.asset(
          animationPath,
          fit: BoxFit.contain,
          animate: true,
        ),
      ),
    );
  }
} 