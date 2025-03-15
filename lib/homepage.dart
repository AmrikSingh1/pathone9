import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pathone9/services/auth_service.dart';
import 'main.dart'; // Import for SizeConfig

// Define consistent color constants to match the app theme
const Color kPrimaryBlue = Color(0xFF13519C);
const Color kSecondaryBlue = Color(0xFF1A6BC6);
const Color kLightBlue = Color(0xFF3B82F6);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _membershipType = 'Loading...';
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membershipType = prefs.getString('user_membership') ?? 'Free';
      
      setState(() {
        _membershipType = membershipType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _membershipType = 'Free';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize SizeConfig
    SizeConfig().init(context);
    
    // Calculate responsive sizes
    final appBarIconSize = SizeConfig.isSmallScreen ? 24.0 : 28.0;
    final titleFontSize = SizeConfig.isSmallScreen ? 20.0 : 24.0;
    final badgeIconSize = SizeConfig.isSmallScreen ? 18.0 : 20.0;
    final badgeFontSize = SizeConfig.isSmallScreen ? 12.0 : 14.0;
    final welcomeFontSize = SizeConfig.isSmallScreen ? 24.0 : 28.0;
    final planFontSize = SizeConfig.isSmallScreen ? 16.0 : 18.0;
    final infoFontSize = SizeConfig.isSmallScreen ? 14.0 : 16.0;
    
    // Calculate responsive paddings
    final horizontalPadding = SizeConfig.blockSizeHorizontal * 4; // 4% of screen width
    final verticalPadding = SizeConfig.blockSizeVertical * 3; // 3% of screen height
    final badgeMargin = SizeConfig.blockSizeHorizontal * 4; // 4% of screen width
    final badgePaddingH = SizeConfig.blockSizeHorizontal * 4; // 4% of screen width
    final badgePaddingV = SizeConfig.blockSizeVertical * 1.5; // 1.5% of screen height
    
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
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
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: kPrimaryBlue, size: appBarIconSize),
            onPressed: () {
              // TODO: Implement profile page navigation
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: kPrimaryBlue, size: appBarIconSize * 0.8),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
          SizedBox(width: horizontalPadding * 0.5),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Membership badge
                  Container(
                    margin: EdgeInsets.all(badgeMargin),
                    padding: EdgeInsets.symmetric(
                      horizontal: badgePaddingH,
                      vertical: badgePaddingV,
                    ),
                    decoration: BoxDecoration(
                      color: _getMembershipColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getMembershipColor(),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getMembershipIcon(),
                          color: _getMembershipColor(),
                          size: badgeIconSize,
                        ),
                        SizedBox(width: horizontalPadding * 0.5),
                        Text(
                          '$_membershipType Membership',
                          style: TextStyle(
                            color: _getMembershipColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: badgeFontSize,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Welcome message
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome to PathOne!',
                              style: TextStyle(
                                fontSize: welcomeFontSize,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: verticalPadding * 0.8),
                            Text(
                              'You are currently on the $_membershipType plan.',
                              style: TextStyle(
                                fontSize: planFontSize,
                                color: Color(0xFF4B5563),
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: verticalPadding * 2),
                            Text(
                              'Your dashboard and app content will appear here.',
                              style: TextStyle(
                                fontSize: infoFontSize,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            // Add responsive orientation handling
                            if (SizeConfig.orientation == Orientation.landscape)
                              Padding(
                                padding: EdgeInsets.only(top: verticalPadding),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildQuickActionButton(
                                      icon: Icons.dashboard,
                                      label: 'Dashboard',
                                      onTap: () {},
                                    ),
                                    SizedBox(width: horizontalPadding),
                                    _buildQuickActionButton(
                                      icon: Icons.settings,
                                      label: 'Settings',
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.only(top: verticalPadding),
                                child: Column(
                                  children: [
                                    _buildQuickActionButton(
                                      icon: Icons.dashboard,
                                      label: 'Dashboard',
                                      onTap: () {},
                                    ),
                                    SizedBox(height: verticalPadding * 0.8),
                                    _buildQuickActionButton(
                                      icon: Icons.settings,
                                      label: 'Settings',
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper method to build quick action buttons
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final buttonWidth = SizeConfig.blockSizeHorizontal * 40; // 40% of screen width in portrait
    final buttonHeight = SizeConfig.blockSizeVertical * 8; // 8% of screen height
    final iconSize = SizeConfig.isSmallScreen ? 24.0 : 28.0;
    final fontSize = SizeConfig.isSmallScreen ? 14.0 : 16.0;
    
    // Adjust width for landscape orientation
    final actualWidth = SizeConfig.orientation == Orientation.landscape
        ? SizeConfig.blockSizeHorizontal * 25 // 25% of screen width in landscape
        : buttonWidth;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: actualWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryBlue.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kPrimaryBlue, size: iconSize),
            SizedBox(height: SizeConfig.blockSizeVertical * 1),
            Text(
              label,
              style: TextStyle(
                color: kPrimaryBlue,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMembershipColor() {
    switch (_membershipType) {
      case 'Premium':
        return const Color(0xFF3B82F6); // Blue
      case 'Ultimate':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF64748B); // Slate gray
    }
  }

  IconData _getMembershipIcon() {
    switch (_membershipType) {
      case 'Premium':
        return Icons.star;
      case 'Ultimate':
        return Icons.diamond;
      default:
        return Icons.check_circle;
    }
  }
} 