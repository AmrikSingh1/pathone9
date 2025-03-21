import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class TestVideoPlayerPage extends StatefulWidget {
  const TestVideoPlayerPage({super.key});

  @override
  State<TestVideoPlayerPage> createState() => _TestVideoPlayerPageState();
}

class _TestVideoPlayerPageState extends State<TestVideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isBuffering = false;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      // Dispose existing controllers if they exist
      _chewieController?.dispose();
      _videoPlayerController.dispose();
    });
    
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
    );
    
    // Add listener for buffering state
    _videoPlayerController.addListener(_checkBuffering);
    
    try {
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        showOptions: false,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.cyan,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade500,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
      
      setState(() {
        _isLoading = false;
      });
      
      // Start playback to trigger buffering states
      _videoPlayerController.play();
    } catch (e) {
      debugPrint('Error initializing video: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _checkBuffering() {
    final newBufferingState = _videoPlayerController.value.isBuffering;
    if (_isBuffering != newBufferingState) {
      setState(() {
        _isBuffering = newBufferingState;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_checkBuffering);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player Test'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isLoading 
                  ? const CircularProgressIndicator()
                  : _chewieController != null && _videoPlayerController.value.isInitialized
                      ? _buildVideoPlayer()
                      : const Text('Failed to load video'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Status: ${_videoPlayerController.value.isPlaying ? "Playing" : "Paused"}',
                ),
                Text(
                  'Buffering: ${_videoPlayerController.value.isBuffering ? "Yes" : "No"}',
                ),
                Text(
                  'Position: ${_videoPlayerController.value.position.inSeconds}s / ${_videoPlayerController.value.duration.inSeconds}s',
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _initializePlayer,
            child: const Text('Reload Video'),
          ),
          const SizedBox(height: 16),
          if (_videoPlayerController.value.hasError)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${_videoPlayerController.value.errorDescription}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildVideoPlayer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Chewie(controller: _chewieController!),
        ),
        
        // Overlay a buffering indicator only when the video is actually buffering
        if (_isBuffering)
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
      ],
    );
  }
} 