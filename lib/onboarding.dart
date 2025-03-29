import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  late AnimationController _slideAnimController;
  late Animation<Offset> _slideAnimation;

  // Animation for "Start" button
  late AnimationController _startButtonAnimController;
  late Animation<double> _startButtonScaleAnimation;

  // List of all animation files with their respective titles and descriptions
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'animation': 'assets/animations/start.json',
      'title': 'Start Your Journey',
      'description': 'Begin your career exploration with our AI-powered guidance system'
    },
    {
      'animation': 'assets/animations/thinking_about_career.json',
      'title': 'Discover Your Path',
      'description': 'Explore hundreds of career options tailored to your skills and interests'
    },
    {
      'animation': 'assets/animations/ai_tests.json',
      'title': 'Take AI Tests',
      'description': 'Complete interactive assessments designed to match your abilities with ideal careers'
    },
    {
      'animation': 'assets/animations/searching_career.json',
      'title': 'Find Your Passion',
      'description': 'Our advanced AI analyzes your unique profile to suggest the perfect career matches'
    },
    {
      'animation': 'assets/animations/module_by_module_courses.json',
      'title': 'Learn Step by Step',
      'description': 'Access comprehensive courses broken down into easy-to-follow modules'
    },
    {
      'animation': 'assets/animations/24:7_ai_powered_customer_support.json',
      'title': 'Get 24/7 Support',
      'description': 'Our AI-powered support system is always ready to assist with your career questions'
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize slide animation controller
    _slideAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-1.0, 0),
    ).animate(CurvedAnimation(
      parent: _slideAnimController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize start button animation controller
    _startButtonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _startButtonScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_startButtonAnimController);
    
    // Start the pulsating animation for the start button
    _startButtonAnimController.repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideAnimController.dispose();
    _startButtonAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == _onboardingData.length - 1;
    });
  }

  void _skipToEnd() {
    _slideAnimController.forward().then((_) {
      _pageController.animateToPage(
        _onboardingData.length - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _slideAnimController.reset();
    });
  }

  void _goToNextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _slideAnimController.forward().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _slideAnimController.reset();
      });
    }
  }

  void _completeOnboarding() async {
    // Save that onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_started_onboarding', true);
    
    if (mounted) {
      // Navigate to login page
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(
            showLoginContent: true,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _slideAnimController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _slideAnimation,
                        child: _buildOnboardingPage(index),
                      );
                    },
                  );
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(int index) {
    final data = _onboardingData[index];
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation
          Expanded(
            flex: 5,
            child: Lottie.asset(
              data['animation'],
              fit: BoxFit.contain,
              animate: true,
            ),
          ),
          
          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF00E5FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              data['title'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            data['description'],
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip button (only visible if not on last page)
          !_isLastPage
              ? TextButton(
                  onPressed: _skipToEnd,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox(width: 60), // Placeholder for alignment
              
          // Page indicators
          Row(
            children: List.generate(
              _onboardingData.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          // Next or Start button
          _isLastPage
              ? ScaleTransition(
                  scale: _startButtonScaleAnimation,
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 20)
                      ],
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 20)
                    ],
                  ),
                ),
        ],
      ),
    );
  }
} 