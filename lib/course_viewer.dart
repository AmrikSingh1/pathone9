import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class CourseViewer extends StatefulWidget {
  final String courseTitle;
  final int membershipPlan;

  const CourseViewer({
    super.key,
    required this.courseTitle,
    required this.membershipPlan,
  });

  @override
  State<CourseViewer> createState() => _CourseViewerState();
}

class _CourseViewerState extends State<CourseViewer> {
  int _selectedModuleIndex = 0;
  int _selectedLessonIndex = 0;
  bool _isVideoPlaying = false;
  bool _isSidebarExpanded = true;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Sample course data - in a real app, this would come from a backend
  late final List<CourseModule> _modules = [
    CourseModule(
      title: 'Introduction to Civil Engineering',
      lessons: [
        Lesson(
          title: 'Welcome to Civil Engineering Fundamentals',
          duration: '10:00',
          videoUrl: 'https://youtu.be/t_3T0GswzWU?si=nUXxq_Dn2IX_ZSbV',
          // Using a direct MP4 URL for video player demo
          directVideoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          isYoutubeVideo: true,
          resources: [
            Resource(
              title: 'Civil Engineering Basics Guide',
              fileType: 'PDF',
              downloadUrl: 'https://example.com/worksheet1.pdf',
            ),
          ],
        ),
        Lesson(
          title: 'Understanding Structural Principles',
          duration: '15:00',
          videoUrl: 'https://example.com/video2',
          directVideoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          isYoutubeVideo: false,
          resources: [
            Resource(
              title: 'Structural Engineering Guide',
              fileType: 'PDF',
              downloadUrl: 'https://example.com/guide1.pdf',
            ),
          ],
        ),
      ],
    ),
    CourseModule(
      title: 'Advanced Civil Engineering Concepts',
      lessons: [
        Lesson(
          title: 'Materials Science for Civil Engineers',
          duration: '20:00',
          videoUrl: 'https://example.com/video3',
          directVideoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          isYoutubeVideo: false,
          resources: [
            Resource(
              title: 'Construction Materials Guide',
              fileType: 'PDF',
              downloadUrl: 'https://example.com/guide2.pdf',
            ),
          ],
        ),
        Lesson(
          title: 'Environmental Engineering Principles',
          duration: '18:00',
          videoUrl: 'https://example.com/video4',
          directVideoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          isYoutubeVideo: false,
          resources: [
            Resource(
              title: 'Sustainable Engineering Practices',
              fileType: 'PDF',
              downloadUrl: 'https://example.com/guide3.pdf',
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    // Remove listener before disposing
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
    }
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() async {
    final currentLesson = _modules[_selectedModuleIndex].lessons[_selectedLessonIndex];
    
    setState(() {
      // Set loading state
      _chewieController = null;
    });
    
    // Clean up previous controllers
    _videoController?.dispose();
    _chewieController?.dispose();
    
    // Create new video controller
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(currentLesson.directVideoUrl),
    );
    
    try {
      // Show loading indicator during initialization
      setState(() {});
      
      await _videoController!.initialize();
      
      // Create chewie controller only after video is initialized
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        showOptions: false,
        // Remove the placeholder to prevent it from showing during playback
        placeholder: Container(
          color: const Color(0xFF1E293B),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF3B82F6),
          handleColor: const Color(0xFF00E5FF),
          backgroundColor: const Color(0xFFF1F5F9),
          bufferedColor: const Color(0xFFE2E8F0),
        ),
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
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
        // Force update the widget when the player state changes
        customControls: null,
      );
      
      // Add listeners
      _videoController!.addListener(_videoListener);
      
      // Start playback to trigger state changes
      _videoController!.play();
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
    
    // Force update the UI
    if (mounted) {
      setState(() {});
    }
  }
  
  // Separate listener function for cleaner code
  void _videoListener() {
    if (!mounted) return;
    
    final isPlaying = _videoController!.value.isPlaying;
    if (isPlaying != _isVideoPlaying) {
      setState(() {
        _isVideoPlaying = isPlaying;
      });
    }
    
    // Check if video ended
    if (_videoController!.value.position >= _videoController!.value.duration) {
      _showLessonCompletionDialog();
    }
  }

  void _updateSelectedLesson(int moduleIndex, int lessonIndex) {
    setState(() {
      _selectedModuleIndex = moduleIndex;
      _selectedLessonIndex = lessonIndex;
    });
    _initializeVideoPlayer();
  }

  @override
  Widget build(BuildContext context) {
    final currentModule = _modules[_selectedModuleIndex];
    final currentLesson = currentModule.lessons[_selectedLessonIndex];
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 768;

    return Scaffold(
      appBar: isTablet ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.courseTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      drawer: isTablet ? null : _buildMobileDrawer(currentModule),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
            final isLargeScreen = constraints.maxWidth >= 900;
            
            if (isLargeScreen || isMediumScreen) {
              return _buildTabletLayout(currentModule, currentLesson);
            } else {
              return _buildMobileLayout(currentModule, currentLesson);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(CourseModule currentModule) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF00E5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.courseTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Course Content',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ..._modules.asMap().entries.map((moduleEntry) {
            final moduleIndex = moduleEntry.key;
            final module = moduleEntry.value;
            final isModuleSelected = moduleIndex == _selectedModuleIndex;
            
            return ExpansionTile(
              initiallyExpanded: isModuleSelected,
              title: Text(
                module.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: isModuleSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isModuleSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                ),
              ),
              children: module.lessons.asMap().entries.map((lessonEntry) {
                final lessonIndex = lessonEntry.key;
                final lesson = lessonEntry.value;
                final isLessonSelected = moduleIndex == _selectedModuleIndex && lessonIndex == _selectedLessonIndex;
                
                return ListTile(
                  selected: isLessonSelected,
                  leading: Icon(
                    lesson.isYoutubeVideo ? Icons.smart_display : Icons.play_circle_outline,
                    color: isLessonSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                  ),
                  title: Text(
                    lesson.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: isLessonSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isLessonSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
                    ),
                  ),
                  subtitle: Text(
                    lesson.duration,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    _updateSelectedLesson(moduleIndex, lessonIndex);
                    Navigator.pop(context); // Close drawer after selection
                  },
                );
              }).toList(),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(Lesson lesson) {
    // Only show Chewie player when both controller and video are ready
    if (_chewieController != null && 
        _videoController != null && 
        _videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Chewie(controller: _chewieController!),
          ),
          
          // Loading indicator that only shows during buffering
          if (_videoController!.value.isBuffering)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
        ],
      );
    } else {
      // Placeholder or loading state
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFF1E293B),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ),
      );
    }
  }

  void _showLessonCompletionDialog() {
    final nextModuleIndex = _selectedModuleIndex;
    final nextLessonIndex = _selectedLessonIndex + 1;
    final hasNextLesson = nextLessonIndex < _modules[nextModuleIndex].lessons.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Lesson Completed!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congratulations on completing this lesson. Keep up the good work!',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _modules[_selectedModuleIndex].lessons[_selectedLessonIndex].title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
              ),
            ),
          ),
          if (hasNextLesson)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateSelectedLesson(_selectedModuleIndex, nextLessonIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Next Lesson',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(CourseModule currentModule, Lesson currentLesson) {
    return Stack(
      children: [
        Column(
          children: [
            // Video player area
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildVideoPlayer(currentLesson),
            ),
            
            // Lesson info
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLesson.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Duration: ${currentLesson.duration}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (currentLesson.isYoutubeVideo) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000).withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFFF0000).withAlpha(77),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.smart_display,
                                size: 14,
                                color: Color(0xFFFF0000),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'YouTube',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFF0000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Resources section - now fills remaining space above the draggable sheet
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resources',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...currentLesson.resources.map((resource) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource.title,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    resource.fileType,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: Color(0xFF3B82F6),
                              ),
                              onPressed: () {
                                // Implement download functionality
                              },
                            ),
                          ],
                        ),
                      )),
                      // Add extra bottom padding for the draggable sheet
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // YouTube-style draggable sheet for course modules
        _buildDraggableModulesSheet(currentModule),
      ],
    );
  }
  
  // New method to build the YouTube-style draggable sheet
  Widget _buildDraggableModulesSheet(CourseModule currentModule) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1, // Starts collapsed at 10% height
      minChildSize: 0.1, // Minimum size when collapsed (mini-bar)
      maxChildSize: 0.7, // Maximum size when expanded
      builder: (context, scrollController) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {
                    // This allows tapping the handle to toggle between expanded/collapsed
                    double targetSize = scrollController.hasClients && 
                                       scrollController.position.viewportDimension > MediaQuery.of(context).size.height * 0.15 
                                       ? 0.1 // Collapse if expanded
                                       : 0.7; // Expand if collapsed
                           
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent * (targetSize / 0.7),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      // Title bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.video_library,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Course Modules',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            // Video count badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getTotalLessonsCount()} videos',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              // Course modules list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, moduleIndex) {
                    final module = _modules[moduleIndex];
                    final isModuleSelected = moduleIndex == _selectedModuleIndex;
                    
                    return Column(
                      children: [
                        // Module header
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedModuleIndex = isModuleSelected ? -1 : moduleIndex;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isModuleSelected ? const Color(0xFFF1F5F9) : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isModuleSelected ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                  color: const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    module.title,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${module.lessons.length} videos',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Lessons list
                        if (isModuleSelected)
                          ...module.lessons.asMap().entries.map((entry) {
                            final lessonIndex = entry.key;
                            final lesson = entry.value;
                            final isLessonSelected = 
                                moduleIndex == _selectedModuleIndex && 
                                lessonIndex == _selectedLessonIndex;
                              
                            return InkWell(
                              onTap: () {
                                _updateSelectedLesson(moduleIndex, lessonIndex);
                                // Collapse the sheet after selecting a lesson
                                scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isLessonSelected 
                                      ? const Color(0xFFE2E8F0) 
                                      : const Color(0xFFF8FAFC),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail or icon
                                    Container(
                                      width: 60,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          lesson.isYoutubeVideo
                                              ? Icons.smart_display
                                              : Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lesson.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: isLessonSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isLessonSelected
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                lesson.duration,
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              if (lesson.isYoutubeVideo) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFF0000).withAlpha(26),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                  child: const Text(
                                                    'YouTube',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFFFF0000),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Play status indicator
                                    if (isLessonSelected)
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Color(0xFF3B82F6),
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        const Divider(height: 1),
                      ],
                    );
                  },
                  childCount: _modules.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Helper method to get total lesson count
  int _getTotalLessonsCount() {
    int count = 0;
    for (var module in _modules) {
      count += module.lessons.length;
    }
    return count;
  }

  Widget _buildTabletLayout(CourseModule currentModule, Lesson currentLesson) {
    return Row(
      children: [
        // Sidebar with course content
        if (_isSidebarExpanded)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Course title header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.courseTitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back to Membership',
                      ),
                    ],
                  ),
                ),
                // Course modules list
                Expanded(
                  child: ListView.builder(
                    itemCount: _modules.length,
                    itemBuilder: (context, moduleIndex) {
                      final module = _modules[moduleIndex];
                      final isSelected = moduleIndex == _selectedModuleIndex;
                      
                      return Column(
                        children: [
                          // Module header
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  // If already selected, just collapse/expand
                                  _selectedModuleIndex = -1;
                                } else {
                                  _selectedModuleIndex = moduleIndex;
                                  if (module.lessons.isNotEmpty) {
                                    _selectedLessonIndex = 0;
                                    _initializeVideoPlayer();
                                  }
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
                                border: const Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                    color: const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      module.title,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Lessons list
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: isSelected
                              ? Column(
                                  children: module.lessons.asMap().entries.map((entry) {
                                    final lessonIndex = entry.key;
                                    final lesson = entry.value;
                                    final isLessonSelected = 
                                        moduleIndex == _selectedModuleIndex && 
                                        lessonIndex == _selectedLessonIndex;

                                    return InkWell(
                                      onTap: () {
                                        _updateSelectedLesson(moduleIndex, lessonIndex);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isLessonSelected 
                                              ? const Color(0xFFE2E8F0) 
                                              : const Color(0xFFF8FAFC),
                                          border: const Border(
                                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              lesson.isYoutubeVideo
                                                  ? Icons.smart_display
                                                  : Icons.play_circle_outline,
                                              color: isLessonSelected
                                                  ? const Color(0xFF3B82F6)
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    lesson.title,
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 14,
                                                      fontWeight: isLessonSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      color: isLessonSelected
                                                          ? const Color(0xFF1E293B)
                                                          : const Color(0xFF475569),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        lesson.duration,
                                                        style: const TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 12,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                      if (lesson.isYoutubeVideo) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFF0000).withAlpha(26),
                                                            borderRadius: BorderRadius.circular(2),
                                                          ),
                                                          child: const Text(
                                                            'YouTube',
                                                            style: TextStyle(
                                                              fontFamily: 'Inter',
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w500,
                                                              color: Color(0xFFFF0000),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              : Container(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // Main content area
        Expanded(
          child: Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isSidebarExpanded 
                          ? Icons.menu_open 
                          : Icons.menu),
                      onPressed: () {
                        setState(() {
                          _isSidebarExpanded = !_isSidebarExpanded;
                        });
                      },
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLesson.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (currentLesson.isYoutubeVideo)
                            Row(
                              children: [
                                const Icon(
                                  Icons.smart_display,
                                  size: 12,
                                  color: Color(0xFFFF0000),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'YouTube Video • ${currentLesson.duration}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Video player area
              Expanded(
                child: Container(
                  color: const Color(0xFF0F172A),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildVideoPlayer(currentLesson),
                    ),
                  ),
                ),
              ),

              // Resources section
              Container(
                height: 200, // Fixed height for resources section
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resources',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: currentLesson.resources.map((resource) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resource.title,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resource.fileType,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  color: Color(0xFF3B82F6),
                                ),
                                onPressed: () {
                                  // Implement download functionality
                                },
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CourseModule {
  final String title;
  final List<Lesson> lessons;

  CourseModule({
    required this.title,
    required this.lessons,
  });
}

class Lesson {
  final String title;
  final String duration;
  final String videoUrl;
  final String directVideoUrl;
  final bool isYoutubeVideo;
  final List<Resource> resources;

  Lesson({
    required this.title,
    required this.duration,
    required this.videoUrl,
    this.directVideoUrl = '',
    required this.resources,
    this.isYoutubeVideo = false,
  });
}

class Resource {
  final String title;
  final String fileType;
  final String downloadUrl;

  Resource({
    required this.title,
    required this.fileType,
    required this.downloadUrl,
  });
} 