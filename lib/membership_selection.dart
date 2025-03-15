import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'main.dart'; // Import for SizeConfig

// Define consistent color constants to match the app theme
const Color kPrimaryBlue = Color(0xFF13519C);
const Color kSecondaryBlue = Color(0xFF1A6BC6);
const Color kLightBlue = Color(0xFF3B82F6);

class MembershipSelectionPage extends StatefulWidget {
  final String userId; // User ID from authentication

  const MembershipSelectionPage({
    super.key,
    required this.userId,
  });

  @override
  State<MembershipSelectionPage> createState() => _MembershipSelectionPageState();
}

class _MembershipSelectionPageState extends State<MembershipSelectionPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedMembershipIndex = 0; // Default to free membership

  // Membership plan details
  final List<Map<String, dynamic>> _membershipPlans = [
    {
      'title': 'Free',
      'price': '\$0',
      'period': 'forever',
      'features': [
        'Basic features access',
        'Limited storage',
        'Standard support',
        'Ad-supported experience',
      ],
      'color': const Color(0xFF64748B), // Slate gray for free tier
      'recommended': false,
    },
    {
      'title': 'Premium',
      'price': '\$9.99',
      'period': 'per month',
      'features': [
        'All basic features',
        'Enhanced storage capacity',
        'Priority customer support',
        'Ad-free experience',
        'Advanced analytics',
      ],
      'color': const Color(0xFF3B82F6), // Blue for premium tier
      'recommended': true,
    },
    {
      'title': 'Ultimate',
      'price': '\$19.99',
      'period': 'per month',
      'features': [
        'All premium features',
        'Unlimited storage',
        '24/7 dedicated support',
        'Exclusive content access',
        'Custom branding options',
        'Team collaboration tools',
      ],
      'color': const Color(0xFF8B5CF6), // Purple for ultimate tier
      'recommended': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Save user membership selection and navigate to home page
  Future<void> _saveMembershipAndContinue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save membership selection
      await prefs.setString('user_membership', _membershipPlans[_selectedMembershipIndex]['title']);
      
      // Mark user as not new (for future logins)
      await prefs.setBool('is_first_launch', false);
      
      // Save user ID if needed
      await prefs.setString('user_id', widget.userId);
      
      // Navigate to home page and remove all previous routes
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/home', 
          (route) => false,
        );
      }
    } catch (e) {
      // Show error if something goes wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving membership: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize SizeConfig
    SizeConfig().init(context);
    
    // Calculate responsive sizes
    final titleFontSize = SizeConfig.isSmallScreen ? 24.0 : 28.0;
    final subtitleFontSize = SizeConfig.isSmallScreen ? 14.0 : 16.0;
    final planTitleFontSize = SizeConfig.isSmallScreen ? 20.0 : 22.0;
    final priceFontSize = SizeConfig.isSmallScreen ? 22.0 : 24.0;
    final periodFontSize = SizeConfig.isSmallScreen ? 12.0 : 14.0;
    final featureTitleFontSize = SizeConfig.isSmallScreen ? 14.0 : 16.0;
    final featureItemFontSize = SizeConfig.isSmallScreen ? 12.0 : 14.0;
    final buttonFontSize = SizeConfig.isSmallScreen ? 16.0 : 18.0;
    
    // Calculate responsive paddings
    final horizontalPadding = SizeConfig.blockSizeHorizontal * 6; // 6% of screen width
    final verticalPadding = SizeConfig.blockSizeVertical * 3; // 3% of screen height
    final headerTopPadding = SizeConfig.isSmallScreen ? 
        SizeConfig.blockSizeVertical * 3 : SizeConfig.blockSizeVertical * 5;
    final headerBottomPadding = SizeConfig.blockSizeVertical * 2;
    final itemSpacing = SizeConfig.blockSizeVertical * 1.5;
    final buttonHeight = SizeConfig.isSmallScreen ? 48.0 : 56.0;
    
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Container(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 
                  headerTopPadding, 
                  horizontalPadding, 
                  headerBottomPadding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App logo/title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          kPrimaryBlue,
                          kSecondaryBlue,
                          kLightBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'PathOne',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: itemSpacing * 1.5),
                    
                    // Page title
                    Text(
                      'Choose Your Membership',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: itemSpacing * 0.8),
                    
                    // Subtitle
                    Text(
                      'Select the plan that works best for you',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Membership options
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, 
                    vertical: verticalPadding * 0.5
                  ),
                  itemCount: _membershipPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _membershipPlans[index];
                    final isSelected = _selectedMembershipIndex == index;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMembershipIndex = index;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: itemSpacing * 1.3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? plan['color'] 
                                : Colors.grey[300]!,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                  ? plan['color'].withOpacity(0.2) 
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plan header with recommended badge if applicable
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Plan header
                                Container(
                                  padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 5),
                                  decoration: BoxDecoration(
                                    color: plan['color'].withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Plan title
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['title'],
                                            style: TextStyle(
                                              fontSize: planTitleFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: plan['color'],
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          SizedBox(height: itemSpacing * 0.3),
                                          Row(
                                            children: [
                                              Text(
                                                plan['price'],
                                                style: TextStyle(
                                                  fontSize: priceFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1F2937),
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                              SizedBox(width: SizeConfig.blockSizeHorizontal),
                                              Text(
                                                plan['period'],
                                                style: TextStyle(
                                                  fontSize: periodFontSize,
                                                  color: Colors.grey[600],
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      // Selection indicator
                                      Container(
                                        width: SizeConfig.blockSizeHorizontal * 7,
                                        height: SizeConfig.blockSizeHorizontal * 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected 
                                              ? plan['color'] 
                                              : Colors.white,
                                          border: Border.all(
                                            color: isSelected 
                                                ? plan['color'] 
                                                : Colors.grey[300]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected 
                                            ? Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: SizeConfig.blockSizeHorizontal * 4,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Recommended badge
                                if (plan['recommended'])
                                  Positioned(
                                    top: -SizeConfig.blockSizeVertical * 1.5,
                                    right: SizeConfig.blockSizeHorizontal * 5,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: SizeConfig.blockSizeHorizontal * 3,
                                        vertical: SizeConfig.blockSizeVertical * 0.7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: plan['color'],
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: plan['color'].withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'RECOMMENDED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: SizeConfig.isSmallScreen ? 10 : 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            // Plan features
                            Padding(
                              padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Features',
                                    style: TextStyle(
                                      fontSize: featureTitleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  SizedBox(height: itemSpacing * 0.8),
                                  ...List.generate(
                                    plan['features'].length,
                                    (i) => Padding(
                                      padding: EdgeInsets.only(bottom: itemSpacing * 0.7),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: plan['color'],
                                            size: SizeConfig.blockSizeHorizontal * 5,
                                          ),
                                          SizedBox(width: SizeConfig.blockSizeHorizontal * 3),
                                          Expanded(
                                            child: Text(
                                              plan['features'][i],
                                              style: TextStyle(
                                                fontSize: featureItemFontSize,
                                                color: Color(0xFF4B5563),
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Continue button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 
                  verticalPadding * 0.5, 
                  horizontalPadding, 
                  verticalPadding
                ),
                child: Container(
                  height: buttonHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryBlue,
                        kSecondaryBlue,
                        kLightBlue,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveMembershipAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue with ${_membershipPlans[_selectedMembershipIndex]['title']}',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: SizeConfig.blockSizeHorizontal * 2),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: SizeConfig.blockSizeHorizontal * 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 