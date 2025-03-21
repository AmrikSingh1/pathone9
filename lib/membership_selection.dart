import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'course_viewer.dart';

class MembershipSelectionPage extends StatefulWidget {
  final String userId;

  const MembershipSelectionPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MembershipSelectionPage> createState() => _MembershipSelectionPageState();
}

class _MembershipSelectionPageState extends State<MembershipSelectionPage> with TickerProviderStateMixin {
  int _selectedPlan = -1;
  bool _isProcessing = false;

  // Animation controllers - add pulse animation controller
  late AnimationController _cardsAnimController;
  late AnimationController _shineAnimController;
  late AnimationController _pulseAnimController;

  // Animations
  late List<Animation<double>> _cardAnims;
  late Animation<double> _shineAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    try {
      // Initialize animation controllers
      _cardsAnimController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      // Add shine animation controller back
      _shineAnimController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat();

      // Add pulse animation controller
      _pulseAnimController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);

      // Create staggered animations for cards
      _cardAnims = List.generate(3, (index) {
        final delay = 0.2 * index;
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _cardsAnimController,
            curve: Interval(delay, delay + 0.6, curve: Curves.easeOutCubic),
          ),
        );
      });

      // Add shine animation back
      _shineAnim = Tween<double>(begin: -0.5, end: 1.5).animate(
          CurvedAnimation(parent: _shineAnimController, curve: Curves.easeInOut)
      );

      // Add pulse animation
      _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
          CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut)
      );

      // Start animations
      _cardsAnimController.forward();
    } catch (e) {
      debugPrint('Error initializing animations: $e');
      // Initialize with default values to prevent null errors
      _cardAnims = List.generate(3, (_) => const AlwaysStoppedAnimation(1.0));
      _shineAnim = const AlwaysStoppedAnimation(0.0);
      _pulseAnim = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    // Safely dispose animation controllers
    try {
      if (_cardsAnimController.isAnimating) {
        _cardsAnimController.stop();
      }
      if (_shineAnimController.isAnimating) {
        _shineAnimController.stop();
      }
      if (_pulseAnimController.isAnimating) {
        _pulseAnimController.stop();
      }

      _cardsAnimController.dispose();
      _shineAnimController.dispose();
      _pulseAnimController.dispose();
    } catch (e) {
      debugPrint('Error disposing animation controllers: $e');
    }
    super.dispose();
  }

  Future<void> _selectMembership() async {
    if (_selectedPlan == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a membership plan'),
          backgroundColor: Color(0xFF6B46C1),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop animations to prevent rendering issues during navigation
      _stopAllAnimations();

      // Save membership selection to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('membership_plan', _selectedPlan);
      await prefs.setBool('has_membership', true);

      // Get course title based on selected plan
      String courseTitle = '';
      switch (_selectedPlan) {
        case 0:
          courseTitle = 'Basic Course';
          break;
        case 1:
          courseTitle = 'Mega Course';
          break;
        case 2:
          courseTitle = 'Excellence Course';
          break;
      }

      // Navigate to course viewer after a short delay to show the processing state
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/course',
              arguments: {
                'courseTitle': courseTitle,
                'membershipPlan': _selectedPlan,
              },
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error selecting membership: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting membership: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to safely stop all animations
  void _stopAllAnimations() {
    try {
      if (_cardsAnimController.isAnimating) {
        _cardsAnimController.stop();
      }
      if (_shineAnimController.isAnimating) {
        _shineAnimController.stop();
      }
      if (_pulseAnimController.isAnimating) {
        _pulseAnimController.stop();
      }
    } catch (e) {
      debugPrint('Error stopping animations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final screenSize = MediaQuery.of(context).size;
      final screenWidth = screenSize.width;
      final screenHeight = screenSize.height;

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            'Select Membership',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // Simple solid background instead of animated background
            Container(
              color: const Color(0xFFF8FAFC),
            ),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    // Header text with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Choose Your Path',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subheader
                    Text(
                      'Select the membership that fits your journey',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Membership cards
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: const BouncingScrollBehavior(),
                        child: ListView(
                          clipBehavior: Clip.none,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Free Membership Card
                            _buildMembershipCard(
                              index: 0,
                              title: 'Free',
                              price: '₹0',
                              period: 'forever',
                              features: [
                                'Access to Basic Course (100 Career Fields)',
                                '10-Minute Teaching Videos per Career Field',
                                '7-Day AI-Powered Career Discovery (5 Hours A Day)',
                                'Basic AI Career Tests (10-min per field)',
                                'Top 5 Career Recommendations after completion',
                              ],
                              gradientColors: const [
                                Color(0xFF64748B), // Darker slate
                                Color(0xFF94A3B8), // Medium slate
                              ],
                              glowColor: const Color(0xFF475569), // Darker glow color
                              isPopular: false,
                            ),

                            const SizedBox(height: 20),

                            // Premium Membership Card
                            _buildMembershipCard(
                              index: 1,
                              title: 'Premium',
                              price: '₹1499',
                              period: 'per month',
                              features: [
                                'Access to Mega Course (All Free Features Included)',
                                'Deep-Dive into 5 Best-Fit Careers (AI Recommended)',
                                'In-Depth Teaching (5 Hours Daily for 7 Days)',
                                'Advanced AI Tests & Performance Analysis',
                                'Exclusive premium content',
                              ],
                              gradientColors: const [
                                Color(0xFF3B82F6),
                                Color(0xFF00E5FF),
                              ],
                              glowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                              isPopular: true,
                              popularLabel: 'POPULAR',
                            ),

                            const SizedBox(height: 20),

                            // Ultimate Membership Card
                            _buildMembershipCard(
                              index: 2,
                              title: 'Ultimate',
                              price: '₹2499',
                              period: 'per month',
                              features: [
                                'Access to Excellence Course (All Premium Features Included)',
                                'Specialized Career Training (1 Best-Fit Career)',
                                'Job Role Selection within that Career',
                                'Real-World Projects & Industry Case Studies',
                                ' AI-Powered Personalized Career Roadmap',
                              ],
                              gradientColors: const [
                                Color(0xFF6366F1),
                                Color(0xFFA855F7),
                              ],
                              glowColor: const Color(0xFF6366F1).withOpacity(0.5),
                              isPopular: false,
                              isElite: true,
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Select button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildSelectButton(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error building membership selection page: $e');
      // Return a simple fallback UI in case of error
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Membership'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              try {
                Navigator.of(context).pop();
              } catch (e) {
                debugPrint('Error navigating back: $e');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  try {
                    Navigator.of(context).pushReplacementNamed('/homepage');
                  } catch (e) {
                    debugPrint('Error navigating to homepage: $e');
                  }
                },
                child: const Text('Go to Homepage'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMembershipCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required List<Color> gradientColors,
    required Color glowColor,
    required bool isPopular,
    String? popularLabel,
    bool isElite = false,
  }) {
    // Ensure index is within bounds for _cardAnims
    if (index < 0 || index >= _cardAnims.length) {
      debugPrint('Invalid card index: $index');
      return const SizedBox.shrink(); // Return empty widget instead of crashing
    }

    return AnimatedBuilder(
      animation: _cardAnims[index],
      builder: (context, child) {
        // Safely handle animation value
        final animValue = _cardAnims[index].value;

        return Transform.translate(
          offset: Offset(0, 50 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlan = index;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  // Apply pulse animation only to the selected card
                  final scale = _selectedPlan == index ? _pulseAnim.value : 1.0;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Stack(
                        children: [
                          // Card with simplified effect
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedPlan == index
                                      ? glowColor.withOpacity(0.5)
                                      : glowColor.withOpacity(0.3),
                                  blurRadius: _selectedPlan == index ? 15 : 10,
                                  spreadRadius: _selectedPlan == index ? 2 : 1,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                              border: Border.all(
                                color: _selectedPlan == index
                                    ? gradientColors[1].withOpacity(0.8)
                                    : Colors.white.withOpacity(0.5),
                                width: _selectedPlan == index ? 2.0 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row with badge if applicable
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Title with gradient
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                    // Badge for popular or elite
                                    if (isPopular)
                                      _buildBadge(
                                        label: popularLabel ?? 'POPULAR',
                                        colors: gradientColors,
                                      )
                                    else if (isElite)
                                      _buildEliteBadge(),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Price
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      price,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 32,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        period,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Features list
                                ...features.map((feature) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      // Checkmark icon with gradient
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: gradientColors,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 15,
                                            color: Color(0xFF334155),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),

                          // Shine effect for Ultimate tier
                          if (isElite)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedBuilder(
                                  animation: _shineAnim,
                                  builder: (context, child) {
                                    return SimplifiedShineEffect(
                                      position: _shineAnim.value,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({required String label, required List<Color> colors}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEliteBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFFD946EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD946EF).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.star,
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'ELITE ACCESS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectButton() {
    try {
      // Define gradient colors based on selected plan
      List<Color> buttonGradient;
      Color shadowColor;

      if (_selectedPlan == 0) {
        // Free plan colors - updated to match darker colors
        buttonGradient = const [Color(0xFF64748B), Color(0xFF94A3B8)];
        shadowColor = const Color(0xFF475569);
      } else if (_selectedPlan == 1) {
        // Premium plan colors
        buttonGradient = const [Color(0xFF3B82F6), Color(0xFF00E5FF)];
        shadowColor = const Color(0xFF3B82F6);
      } else if (_selectedPlan == 2) {
        // Ultimate plan colors
        buttonGradient = const [Color(0xFF6366F1), Color(0xFFA855F7)];
        shadowColor = const Color(0xFF6366F1);
      } else {
        // Default colors when no plan is selected
        buttonGradient = const [Color(0xFF3B82F6), Color(0xFF00E5FF)];
        shadowColor = const Color(0xFF3B82F6);
      }

      return Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _selectedPlan == -1
                ? [buttonGradient[0].withOpacity(0.5), buttonGradient[1].withOpacity(0.5)]
                : buttonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(_selectedPlan == -1 ? 0.2 : 0.4),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _selectMembership,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Select Membership',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building select button: $e');
      // Return a simple fallback button
      return ElevatedButton(
        onPressed: _isProcessing ? null : _selectMembership,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text('Select Membership'),
      );
    }
  }
}

// Custom scroll behavior for bouncing effect
class BouncingScrollBehavior extends ScrollBehavior {
  const BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

// Simplified shine effect that uses a positioned container instead of CustomPaint
class SimplifiedShineEffect extends StatelessWidget {
  final double position;
  final Color color;

  const SimplifiedShineEffect({
    Key? key,
    required this.position,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Calculate position of the shine
        final shineWidth = width * 0.4;
        final left = width * position - shineWidth;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: 0,
              bottom: 0,
              width: shineWidth,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      color.withOpacity(0.0),
                      color.withOpacity(0.2),
                      color.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 