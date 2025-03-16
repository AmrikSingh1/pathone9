import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // Add import for ImageFilter
import 'package:country_code_picker/country_code_picker.dart'; // Import for country code picker
import 'package:pathone9/services/auth_service.dart'; // Import for Google sign-in
import 'package:firebase_auth/firebase_auth.dart'; // Import for Firebase Auth
import 'main.dart'; // Import for SizeConfig

// Define consistent color constants to match logo-transparent.png
const Color kPrimaryBlue = Color(0xFF13519C); // Primary blue from logo
const Color kSecondaryBlue = Color(0xFF1A6BC6); // Secondary blue
const Color kLightBlue = Color(0xFF3B82F6); // Light blue for gradients

class LoginPage extends StatefulWidget {
  final bool isSignUp;
  final bool isFirstLaunch;
  final bool showLoginContent;

  const LoginPage({
    super.key,
    this.isSignUp = false,
    this.isFirstLaunch = false,
    this.showLoginContent = false,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late bool _isLogin;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // Added for phone number
  final _confirmPasswordController = TextEditingController(); // Added for confirm password
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false; // Added for confirm password visibility

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  late AnimationController _stretchController;
  double _stretchAmount = 0.0;
  bool _isStretching = false;

  late AnimationController _transitionController;
  late Animation<Offset> _imageOffsetAnimation;

  // Content fade animations
  late AnimationController _contentFadeController;
  late Animation<double> _optionsContentFadeAnimation;
  late Animation<double> _loginFormContentFadeAnimation;

  // Container states and animations
  bool _showOptionsContainer = false;
  bool _showLoginContent = false;
  bool _showForgotPasswordContent = false; // Added for forgot password screen
  double _containerSlidePosition = 1.0; // 1.0 = hidden, 0.0 = options visible
  double _containerExpandPosition = 0.0; // 0.0 = options size, 1.0 = login form size
  double _formContentOffset = 0.0; // Additional offset for form content (login vs signup)
  double _formContentOpacity = 1.0; // Added for fade animations

  // Forgot password flow state
  int _forgotPasswordStep = 1; // 1: Phone number, 2: Verification code, 3: New password
  final _verificationCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  // Keyboard state
  bool _isKeyboardVisible = false;
  late AnimationController _keyboardAnimController;
  double _keyboardSlideOffset = 0.0;

  // Country code for phone number
  String _selectedCountryCode = '+91'; // Changed from +1 to +91 (India) as default

  // Add these variables for Google sign-in
  final AuthService _authService = AuthService();
  bool _isGoogleSignInLoading = false;

  // Add these variables for phone verification
  bool _isPhoneVerified = false;
  bool _isShowingOtpField = false;
  final _otpController = TextEditingController();
  bool _isVerifyingPhone = false;
  bool _isGettingCode = false;
  
  // Add Firebase Phone Auth variables
  String _verificationId = '';
  int? _resendToken;
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    // Initialize all controllers first to avoid late initialization errors
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _stretchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _keyboardAnimController = AnimationController(
      duration: const Duration(milliseconds: 500), // Increased from 300 to 500 for smoother animation
      vsync: this,
    );

    // Initialize content fade controller
    _contentFadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Now set up the animations and listeners
    _isLogin = !widget.isSignUp;
    _showLoginContent = widget.showLoginContent || !widget.isFirstLaunch;

    // Initialize fade animation for Get Started page
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Initialize slide animation for logo
    _logoSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 0.5),
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInCubic),
    );

    // Initialize content fade animations
    _optionsContentFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentFadeController, curve: Curves.easeOut),
    );

    _loginFormContentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentFadeController, curve: Curves.easeIn),
    );

    // Add listeners
    _stretchController.addListener(() {
      setState(() {});
    });

    // Initialize transition animations for background image
    // Use a sequence of animations for better control
    _imageOffsetAnimation = TweenSequence<Offset>([
      // Start from far top right corner
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(4.0, -4.0),
          end: const Offset(2.0, -2.0),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Move to final position with enhanced bounce effect
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(2.0, -2.0),
          end: const Offset(0.02, -0.3),
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 80,
      ),
    ]).animate(_transitionController);

    // Initialize keyboard animation controller listener
    _keyboardAnimController.addListener(() {
      setState(() {
        _keyboardSlideOffset = _keyboardAnimController.value;
      });
    });

    if (_showLoginContent) {
      _containerExpandPosition = 1.0; // Start with login form size
      _transitionController.forward();
      _contentFadeController.value = 1.0; // Set content fade to completed state
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _stretchController.dispose();
    _transitionController.dispose();
    _fadeController.dispose();
    _keyboardAnimController.dispose();
    _contentFadeController.dispose(); // Dispose content fade controller
    _otpController.dispose();
    super.dispose();
  }

  void _showOptions() {
    setState(() {
      _showOptionsContainer = true;
      _animateContainerSlideUp();
    });
  }

  void _animateContainerSlideUp() {
    // Increase duration for slower animation
    const duration = Duration(milliseconds: 800);
    final startTime = DateTime.now();

    void updatePosition() {
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsedTime / duration.inMilliseconds).clamp(0.0, 1.0);
      // Use a gentler curve for slower start and finish
      final curvedT = Curves.easeInOutCubic.transform(t);

      setState(() {
        // Adjust the final position to be slightly lower (0.15 instead of 0.0)
        _containerSlidePosition = 1.0 - (curvedT * 0.85);
      });

      if (t < 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => updatePosition());
      }
    }

    updatePosition();
  }

  void _hideOptionsContainer() {
    const duration = Duration(milliseconds: 300);
    final startTime = DateTime.now();

    void updatePosition() {
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsedTime / duration.inMilliseconds).clamp(0.0, 1.0);
      final curvedT = Curves.easeInCubic.transform(t);

      setState(() {
        _containerSlidePosition = curvedT;
      });

      if (t < 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => updatePosition());
      } else {
        setState(() {
          _showOptionsContainer = false;
          _containerSlidePosition = 1.0;
        });
      }
    }

    updatePosition();
  }

  void _expandContainer() {
    // Increase duration for slower animation to match logo fade-out
    const duration = Duration(milliseconds: 800);
    final startTime = DateTime.now();

    void updateExpansion() {
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsedTime / duration.inMilliseconds).clamp(0.0, 1.0);
      // Use a smoother curve for expansion
      final curvedT = Curves.easeInOutCubic.transform(t);

      setState(() {
        _containerExpandPosition = curvedT;
      });

      if (t < 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => updateExpansion());
      }
    }

    updateExpansion();
  }

  void _showForgotPasswordScreen() {
    setState(() {
      _formContentOpacity = 0.0;
      _forgotPasswordStep = 1; // Reset to first step
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _showForgotPasswordContent = true;
        _formContentOpacity = 1.0;
      });
    });

    // Adjust container position for forgot password form
    _animateFormContentOffset(50.0);
  }

  void _returnToLogin() {
    setState(() {
      _formContentOpacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _showForgotPasswordContent = false;
        _forgotPasswordStep = 1; // Reset step when returning to login
        _formContentOpacity = 1.0;
      });
    });

    // Reset container position for login form
    _animateFormContentOffset(20.0);
  }

  void _moveToNextForgotPasswordStep() {
    if (_formKey.currentState!.validate()) {
      // For step 1, send verification code
      if (_forgotPasswordStep == 1) {
        final phoneNumber = '$_selectedCountryCode${_phoneController.text}';
        
      setState(() {
        _formContentOpacity = 0.0;
      });
        
        // Firebase phone verification for password reset
        _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) {
            // Auto-verification is not used for password reset flow
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() {
                _formContentOpacity = 1.0;
              });
              
              String errorMessage = 'Verification failed';
              if (e.code == 'invalid-phone-number') {
                errorMessage = 'Invalid phone number format';
              } else if (e.code == 'too-many-requests') {
                errorMessage = 'Too many requests. Try again later';
              } else {
                errorMessage = 'Error: ${e.message}';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            if (mounted) {
              _verificationId = verificationId;

      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _forgotPasswordStep++;
          _formContentOpacity = 1.0;
        });
      });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification code sent! Please check your messages.'),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (mounted) {
              _verificationId = verificationId;
            }
          },
          timeout: const Duration(seconds: 60),
        );
      } 
      // For step 2, verify the code
      else if (_forgotPasswordStep == 2) {
        setState(() {
          _formContentOpacity = 0.0;
        });
        
        // Verify the OTP code
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _verificationCodeController.text,
        );
        
        _auth.signInWithCredential(credential).then((_) {
          // Successfully verified, move to password reset step
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _forgotPasswordStep++;
                _formContentOpacity = 1.0;
              });
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _formContentOpacity = 1.0;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid verification code. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } else {
        setState(() {
          _formContentOpacity = 0.0;
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _forgotPasswordStep++;
            _formContentOpacity = 1.0;
          });
        });
      }
    }
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      // Get current user
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Update password
        user.updatePassword(_newPasswordController.text).then((_) {
      // Show success message and return to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful! Please login with your new password.'),
          backgroundColor: Colors.green,
            ),
          );
          _returnToLogin();
        }).catchError((error) {
          // Handle errors (e.g., requires recent authentication)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating password: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        });
      } else {
        // User not authenticated
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please try again.'),
            backgroundColor: Colors.red,
        ),
      );
      _returnToLogin();
      }
    }
  }

  void _navigateToLoginContent({bool isLoginMode = true}) {
    setState(() {
      _formContentOpacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isLogin = isLoginMode;
        _showLoginContent = true;
        _showOptionsContainer = false; // Hide options container
        _showForgotPasswordContent = false;
        _formContentOpacity = 1.0;
        _containerExpandPosition = 1.0; // Ensure container is fully expanded
      });

      // Ensure content fade controller is at the right value
      _contentFadeController.value = 1.0;
    });

    // Adjust container position based on form type - move content higher up
    _animateFormContentOffset(isLoginMode ? 10.0 : 30.0); // Reduced from 20.0 and 50.0

    // Start transition animation for background image if not already started
    if (_transitionController.status != AnimationStatus.completed) {
      _transitionController.forward();
    }

    // Fade out the logo if needed
    if (_fadeController.status != AnimationStatus.completed) {
      _fadeController.forward();
    }
  }

  void _switchMode() {
    setState(() {
      _formContentOpacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isLogin = !_isLogin;
        _showForgotPasswordContent = false; // Reset forgot password state when switching modes
        _formContentOpacity = 1.0;
      });
    });

    if (_isLogin) {
      // Switching to Create Account - move content higher up
      _animateFormContentOffset(30.0); // Reduced from 50.0
    } else {
      // Switching to Login - move content higher up
      _animateFormContentOffset(10.0); // Reduced from 20.0
    }
  }

  void _animateFormContentOffset(double targetOffset) {
    const duration = Duration(milliseconds: 300);
    final startTime = DateTime.now();
    final startOffset = _formContentOffset;
    final offsetDifference = targetOffset - startOffset;

    void updateOffset() {
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsedTime / duration.inMilliseconds).clamp(0.0, 1.0);
      final curvedT = Curves.easeInOut.transform(t);

      setState(() {
        _formContentOffset = startOffset + (offsetDifference * curvedT);
      });

      if (t < 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => updateOffset());
      }
    }

    updateOffset();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // For sign up, check if phone is verified
      if (!_isLogin && !_isPhoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your phone number before signing up'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the full phone number with country code for sign up
      String fullPhoneNumber = '';
      if (!_isLogin) {
        fullPhoneNumber = '$_selectedCountryCode${_phoneController.text}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? 'Processing Login...' : 'Processing Sign up...'),
        ),
      );

      // Simulate authentication process
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          // In a real app, you would authenticate with your backend here
          // For this example, we'll simulate a successful authentication
          
          // Generate a mock user ID (in a real app, this would come from your backend)
          final String mockUserId = DateTime.now().millisecondsSinceEpoch.toString();
          
          // Save user data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          
          // Get the current user ID (could be from Google sign-in)
          final userId = prefs.getString('user_id') ?? mockUserId;
          
          // Save the user ID (if not already saved)
          await prefs.setString('user_id', userId);
          
          // If this is a Google user completing their profile, mark it as completed
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.providerData.any((info) => 
              info.providerId == 'google.com')) {
            await prefs.setBool('google_profile_completed_$userId', true);
          }
          
          // For login flow, check if user has already selected a membership
          final hasMembership = prefs.getBool('has_membership') ?? false;
          final isNewUser = !_isLogin;
          
          if (mounted) {
            if (isNewUser) {
              // New user - navigate to membership selection
              Navigator.pushReplacementNamed(
                context, 
                '/membership',
              );
            } else {
              if (hasMembership) {
                // Returning user with membership - go directly to homepage
                Navigator.pushReplacementNamed(context, '/homepage');
              } else {
                // Returning user without membership - go to membership selection
                Navigator.pushReplacementNamed(
                  context, 
                  '/membership',
                );
              }
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authentication error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }
  }

  // Update this method for Firebase phone verification
  void _getVerificationCode() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    
    setState(() {
      _isGettingCode = true;
    });
    
    // Format the phone number with country code
    final phoneNumber = '$_selectedCountryCode${_phoneController.text}';
    
    // Firebase phone verification
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification on Android (not typically triggered on iOS)
        if (mounted) {
          setState(() {
            _isGettingCode = false;
            _isVerifyingPhone = true;
          });
          
          try {
            await _auth.signInWithCredential(credential);
            if (mounted) {
              setState(() {
                _isVerifyingPhone = false;
                _isShowingOtpField = false;
                _isPhoneVerified = true;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number verified automatically!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isVerifyingPhone = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle verification failure
        if (mounted) {
          setState(() {
            _isGettingCode = false;
          });
          
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Try again later';
          } else {
            errorMessage = 'Error: ${e.message}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        // Save verification ID and token for later use
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isGettingCode = false;
            _isShowingOtpField = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent! Please check your messages.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Update verification ID if auto retrieval times out
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
          });
        }
      },
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
    );
  }
  
  void _verifyOtpCode() {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code')),
      );
      return;
    }
    
    setState(() {
      _isVerifyingPhone = true;
    });
    
    // Create credential with verification ID and OTP
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text,
    );
    
    // Sign in with credential
    _auth.signInWithCredential(credential).then((userCredential) {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
          _isShowingOtpField = false;
          _isPhoneVerified = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid verification code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize SizeConfig
    SizeConfig().init(context);
    
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isSmallScreen = SizeConfig.isSmallScreen;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Check if keyboard is visible and animate accordingly
    if (keyboardHeight > 0 && !_isKeyboardVisible) {
      _isKeyboardVisible = true;
      _keyboardAnimController.forward(from: _keyboardAnimController.value);
    } else if (keyboardHeight == 0 && _isKeyboardVisible) {
      _isKeyboardVisible = false;
      _keyboardAnimController.reverse(from: _keyboardAnimController.value);
    }

    // Calculate container height based on animation state and form type
    // Adjust height for small screens to prevent overflow
    final optionsHeight = isSmallScreen ? screenHeight * 0.28 : screenHeight * 0.32; // Further reduced from 0.30/0.34
    final loginFormHeight = _isLogin 
        ? (isSmallScreen ? screenHeight * 0.70 : screenHeight * 0.74) // Increased from 0.68 to 0.70 for small screens
        : (isSmallScreen ? screenHeight * 0.85 : screenHeight * 0.88); // Increased from 0.82 to 0.85 for small screens
    final containerHeight = optionsHeight + (loginFormHeight - optionsHeight) * _containerExpandPosition;

    // Calculate keyboard slide offset - make it negative to move down instead of up
    final keyboardSlideAmount = -screenHeight * 0.16 * CurvedAnimation(
      parent: _keyboardAnimController,
      curve: Curves.easeInOutCubic, // Use a smoother curve for keyboard animation
    ).value;

    // Calculate responsive padding and spacing
    final horizontalPadding = screenWidth * 0.06; // 6% of screen width
    final verticalSpacing = isSmallScreen ? screenHeight * 0.012 : screenHeight * 0.025; // Smaller spacing on small screens

    // Calculate responsive font sizes
    final headingFontSize = isSmallScreen ? 20.0 : 24.0; // Reduced from 22.0/28.0
    final subheadingFontSize = isSmallScreen ? 14.0 : 16.0;
    final buttonFontSize = isSmallScreen ? 12.0 : 13.0;
    final inputFontSize = isSmallScreen ? 14.0 : 16.0;

    // Calculate responsive button sizes
    final buttonHeight = isSmallScreen ? 44.0 : 56.0;
    final iconSize = isSmallScreen ? 18.0 : 22.0;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Changed from false to allow resizing with keyboard
      body: Stack(
        children: [
          // Full-length background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Logo image with fade and slide animations - only shown when needed
          if (!_showLoginContent) // Only include logo in widget tree when not showing login content
            Align(
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _logoSlideAnimation,
                  child: Container(
                    height: screenHeight * 0.4,
                    margin: EdgeInsets.only(top: screenHeight * 0.15),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/logo-transparent.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (!_showLoginContent) ...[
            // Get Started Button
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.05),
                      child: Container(
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
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _showOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                              horizontal: screenWidth * 0.08,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            minimumSize: Size(double.infinity, buttonHeight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Your Journey',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: isSmallScreen ? 18 : 20,
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
          ] else ...[
            // Login page background image
            SlideTransition(
              position: _imageOffsetAnimation,
              child: Align(
                alignment: Alignment(0.5, 0.2), // Moved up from 0.3 to 0.2
                child: Container(
                  height: screenHeight * 0.4,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/backimg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Unified container for both options and login form
          if (_showOptionsContainer || _showLoginContent)
            Positioned(
              // Position the container with keyboard awareness and form type
              // Reduce the negative offset to prevent container from moving too high
              bottom: -screenHeight * 0.036 * _containerSlidePosition +
                  (_containerExpandPosition * -screenHeight * 0.05) + // Reduced from 0.072 to 0.05
                  keyboardSlideAmount +
                  _formContentOffset - screenHeight * 0.01,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  // Only allow dismissing if we're showing options and not login form
                  if (!_showLoginContent && details.primaryVelocity != null && details.primaryVelocity! > 300) {
                    _hideOptionsContainer();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 0),
                  curve: Curves.easeOut,
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle with glowing effect
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          // Only allow dismissing if we're showing options and not login form
                          if (!_showLoginContent && details.primaryDelta != null && details.primaryDelta! > 0) {
                            _hideOptionsContainer();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(
                            top: screenHeight * 0.02, // Reduced from 0.03
                            bottom: screenHeight * 0.01, // Reduced from 0.012
                          ),
                          child: Center(
                            child: Container(
                              width: screenWidth * 0.1,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryBlue.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Content - either options or login form
                      Expanded(
                        child: _showLoginContent
                            ? FadeTransition(
                          opacity: _loginFormContentFadeAnimation,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: horizontalPadding,
                              right: horizontalPadding,
                              top: screenHeight * 0.01, // Reduced from 0.02
                              bottom: screenHeight * 0.05, // Increased from 0.01 to ensure content is scrollable
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Reduced top spacing
                                  SizedBox(height: verticalSpacing * 0.3), // Further reduced from 0.5
                                  // Futuristic header with glow effect
                                  Container(
                                    margin: EdgeInsets.only(bottom: verticalSpacing * 0.6), // Reduced from 0.8
                                    child: Column(
                                      children: [
                                        // App Logo/Title
                                        ShaderMask(
                                          shaderCallback: (bounds) => LinearGradient(
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
                                              fontSize: headingFontSize,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: verticalSpacing * 0.6), // Reduced from verticalSpacing

                                        // Form Title
                                        AnimatedOpacity(
                                          opacity: _formContentOpacity,
                                          duration: const Duration(milliseconds: 300),
                                          child: Text(
                                            _isLogin
                                                ? (_showForgotPasswordContent ? 'Forgot Password' : 'Welcome Back')
                                                : 'Create New Account',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16.0 : 18.0, // Reduced from 22.0/28.0
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Futuristic form fields
                                  if (!_isLogin) ...[
                                    _buildFuturisticTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: verticalSpacing * 0.8), // Reduced from verticalSpacing

                                    _buildFuturisticTextField(
                                      controller: _emailController,
                                      label: 'Email ID',
                                      icon: Icons.email_outlined,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: verticalSpacing * 0.8), // Reduced from verticalSpacing

                                    // Phone number field with country code picker and verification
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: kPrimaryBlue.withOpacity(0.1),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Country code picker
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: CountryCodePicker(
                                              onChanged: (CountryCode countryCode) {
                                                setState(() {
                                                  _selectedCountryCode = countryCode.dialCode!;
                                                });
                                              },
                                              initialSelection: 'IN',
                                              favorite: const ['+91', '+1', '+44', '+61', '+86', '+81', '+49', '+33', '+7', '+55'],
                                              showCountryOnly: false,
                                              showOnlyCountryWhenClosed: false,
                                              alignLeft: false,
                                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                              textStyle: TextStyle(
                                                color: Colors.grey[800],
                                                    fontSize: inputFontSize,
                                                fontFamily: 'Inter',
                                              ),
                                              searchDecoration: InputDecoration(
                                                labelText: 'Search Country',
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                      fontSize: inputFontSize,
                                                  fontFamily: 'Inter',
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search,
                                                  color: kPrimaryBlue,
                                                      size: iconSize,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                              ),
                                              flagDecoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              boxDecoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: kPrimaryBlue.withOpacity(0.1),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Phone number input field
                                          Expanded(
                                            child: TextFormField(
                                              controller: _phoneController,
                                                  enabled: !_isPhoneVerified, // Disable when verified
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your phone number';
                                                }
                                                if (value.length < 10) {
                                                  return 'Please enter a valid phone number';
                                                }
                                                    if (!_isPhoneVerified) {
                                                      return 'Please verify your phone number';
                                                }
                                                return null;
                                              },
                                              keyboardType: TextInputType.phone,
                                                  style: TextStyle(
                                                color: Color(0xFF1F2937),
                                                    fontSize: inputFontSize,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'Phone Number',
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                      fontSize: inputFontSize,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.phone_outlined,
                                                  color: kPrimaryBlue,
                                                      size: iconSize,
                                                    ),
                                                    suffixIcon: _isPhoneVerified 
                                                      ? Icon(
                                                          Icons.verified,
                                                          color: Colors.green,
                                                          size: iconSize,
                                                        )
                                                      : null,
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(16),
                                                    bottomRight: Radius.circular(16),
                                                  ),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[300]!,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(16),
                                                    bottomRight: Radius.circular(16),
                                                  ),
                                                  borderSide: BorderSide(
                                                    color: kPrimaryBlue,
                                                    width: 2,
                                                  ),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(16),
                                                    bottomRight: Radius.circular(16),
                                                  ),
                                                  borderSide: const BorderSide(
                                                    color: Colors.redAccent,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                focusedErrorBorder: OutlineInputBorder(
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(16),
                                                    bottomRight: Radius.circular(16),
                                                  ),
                                                  borderSide: const BorderSide(
                                                    color: Colors.redAccent,
                                                    width: 2,
                                                  ),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                    contentPadding: EdgeInsets.symmetric(
                                                      horizontal: screenWidth * 0.05,
                                                      vertical: screenHeight * 0.02,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                        
                                        // Get Code button (only show if not verified and not showing OTP field)
                                        if (!_isPhoneVerified && !_isShowingOtpField)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Padding(
                                              padding: EdgeInsets.only(top: screenHeight * 0.01, right: screenWidth * 0.02),
                                              child: TextButton(
                                                onPressed: _isGettingCode ? null : _getVerificationCode,
                                                style: TextButton.styleFrom(
                                                  foregroundColor: kPrimaryBlue,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: screenWidth * 0.03, 
                                                    vertical: screenHeight * 0.007
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: BorderSide(color: kPrimaryBlue, width: 1),
                                                  ),
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: _isGettingCode
                                                  ? SizedBox(
                                                      width: screenWidth * 0.04,
                                                      height: screenWidth * 0.04,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                                                      ),
                                                    )
                                                  : Text(
                                                      'Get Code',
                                                      style: TextStyle(
                                                        fontSize: buttonFontSize,
                                                        fontWeight: FontWeight.w500,
                                                        fontFamily: 'Inter',
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        
                                        // OTP verification field (only show when requested)
                                        if (_isShowingOtpField) ...[
                                          SizedBox(height: screenHeight * 0.02),
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: kPrimaryBlue.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: TextFormField(
                                              controller: _otpController,
                                              keyboardType: TextInputType.number,
                                              maxLength: 6,
                                              style: TextStyle(
                                                color: Color(0xFF1F2937),
                                                fontSize: inputFontSize,
                                                letterSpacing: screenWidth * 0.03, // Responsive letter spacing
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center, // Center the OTP digits
                                              decoration: InputDecoration(
                                                labelText: 'Verification Code',
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: inputFontSize,
                                                  fontFamily: 'Inter',
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.security,
                                                  color: kPrimaryBlue,
                                                  size: iconSize,
                                                ),
                                                counterText: '', // Hide the character counter
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[300]!,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: kPrimaryBlue,
                                                    width: 2,
                                                  ),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: screenWidth * 0.05,
                                                  vertical: screenHeight * 0.02,
                                                ),
                                                hintText: "• • • • • •", // Dot placeholders for OTP
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: inputFontSize,
                                                  letterSpacing: screenWidth * 0.03,
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          // Verify button
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Padding(
                                              padding: EdgeInsets.only(top: screenHeight * 0.01, right: screenWidth * 0.02),
                                              child: TextButton(
                                                onPressed: _isVerifyingPhone ? null : _verifyOtpCode,
                                                style: TextButton.styleFrom(
                                                  foregroundColor: kPrimaryBlue,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: screenWidth * 0.04, 
                                                    vertical: screenHeight * 0.007
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: BorderSide(color: kPrimaryBlue, width: 1),
                                                  ),
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: _isVerifyingPhone
                                                  ? SizedBox(
                                                      width: screenWidth * 0.04,
                                                      height: screenWidth * 0.04,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                                                      ),
                                                    )
                                                  : Text(
                                                      'Verify',
                                                      style: TextStyle(
                                                        fontSize: buttonFontSize,
                                                        fontWeight: FontWeight.w500,
                                                        fontFamily: 'Inter',
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: verticalSpacing * 0.8),

                                    _buildFuturisticTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                          color: kPrimaryBlue,
                                          size: iconSize,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: verticalSpacing * 0.8),

                                    _buildFuturisticTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      isConfirmPassword: true,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                          color: kPrimaryBlue,
                                          size: iconSize,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else if (_showForgotPasswordContent) ...[
                                    // Forgot Password Form
                                    const SizedBox(height: 10),
                                    Text(
                                      _forgotPasswordStep == 1
                                          ? 'Enter your registered phone number to reset your password'
                                          : _forgotPasswordStep == 2
                                          ? 'Enter the verification code sent to your phone'
                                          : 'Create your new password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontFamily: 'Inter',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 30),

                                    // Step 1: Phone number input
                                    if (_forgotPasswordStep == 1)
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: kPrimaryBlue.withOpacity(0.1),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Country code picker
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Colors.grey[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: CountryCodePicker(
                                                onChanged: (CountryCode countryCode) {
                                                  setState(() {
                                                    _selectedCountryCode = countryCode.dialCode!;
                                                  });
                                                },
                                                initialSelection: 'IN',
                                                favorite: const ['+91', '+1', '+44', '+61', '+86', '+81', '+49', '+33', '+7', '+55'],
                                                showCountryOnly: false,
                                                showOnlyCountryWhenClosed: false,
                                                alignLeft: false,
                                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                                textStyle: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: inputFontSize,
                                                  fontFamily: 'Inter',
                                                ),
                                                searchDecoration: InputDecoration(
                                                  labelText: 'Search Country',
                                                  labelStyle: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: inputFontSize,
                                                    fontFamily: 'Inter',
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.search,
                                                    color: kPrimaryBlue,
                                                    size: iconSize,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Phone number input field
                                            Expanded(
                                              child: TextFormField(
                                                controller: _phoneController,
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Please enter your phone number';
                                                  }
                                                  if (value.length < 10) {
                                                    return 'Please enter a valid phone number';
                                                  }
                                                  return null;
                                                },
                                                keyboardType: TextInputType.phone,
                                                style: TextStyle(
                                                  color: Color(0xFF1F2937),
                                                  fontSize: inputFontSize,
                                                ),
                                                decoration: InputDecoration(
                                                  labelText: 'Phone Number',
                                                  labelStyle: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: inputFontSize,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.phone_outlined,
                                                    color: kPrimaryBlue,
                                                    size: iconSize,
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: const BorderRadius.only(
                                                      topRight: Radius.circular(16),
                                                      bottomRight: Radius.circular(16),
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: const BorderRadius.only(
                                                      topRight: Radius.circular(16),
                                                      bottomRight: Radius.circular(16),
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: kPrimaryBlue,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius: const BorderRadius.only(
                                                      topRight: Radius.circular(16),
                                                      bottomRight: Radius.circular(16),
                                                    ),
                                                    borderSide: const BorderSide(
                                                      color: Colors.redAccent,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  focusedErrorBorder: OutlineInputBorder(
                                                    borderRadius: const BorderRadius.only(
                                                      topRight: Radius.circular(16),
                                                      bottomRight: Radius.circular(16),
                                                    ),
                                                    borderSide: const BorderSide(
                                                      color: Colors.redAccent,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: screenWidth * 0.05,
                                                    vertical: screenHeight * 0.02,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Step 2: Verification code input
                                    if (_forgotPasswordStep == 2)
                                      _buildFuturisticTextField(
                                        controller: _verificationCodeController,
                                        label: 'Verification Code',
                                        icon: Icons.lock_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the verification code';
                                          }
                                          if (value.length < 4) {
                                            return 'Please enter a valid verification code';
                                          }
                                          return null;
                                        },
                                      ),

                                    // Step 3: New password input
                                    if (_forgotPasswordStep == 3) ...[
                                      _buildFuturisticTextField(
                                        controller: _newPasswordController,
                                        label: 'New Password',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                            color: kPrimaryBlue,
                                            size: iconSize,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isNewPasswordVisible = !_isNewPasswordVisible;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your new password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 20),

                                      _buildFuturisticTextField(
                                        controller: _confirmNewPasswordController,
                                        label: 'Confirm New Password',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isConfirmNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                            color: kPrimaryBlue,
                                            size: iconSize,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isConfirmNewPasswordVisible = !_isConfirmNewPasswordVisible;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your new password';
                                          }
                                          if (value != _newPasswordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],

                                    const SizedBox(height: 30),

                                    // Action Button (Get Code, Verify Code, Reset Password)
                                    Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF2563EB),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _forgotPasswordStep < 3
                                            ? _moveToNextForgotPasswordStep
                                            : _resetPassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          _forgotPasswordStep == 1
                                              ? 'Get Code'
                                              : _forgotPasswordStep == 2
                                              ? 'Verify Code'
                                              : 'Reset Password',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Back to Login Button
                                    TextButton(
                                      onPressed: _returnToLogin,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Back to Login',
                                        style: TextStyle(
                                          color: kPrimaryBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    _buildFuturisticTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),

                                    SizedBox(height: verticalSpacing * 0.8),

                                    _buildFuturisticTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                          color: kPrimaryBlue,
                                          size: iconSize,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),

                                    // Forgot Password Button
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _showForgotPasswordScreen,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: kPrimaryBlue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Futuristic gradient button with glow effect - only shown when not in forgot password flow
                                  Visibility(
                                    visible: !_showForgotPasswordContent,
                                    child: Container(
                                      height: isSmallScreen ? 48 : 56, // Reduced height on small screens
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
                                        onPressed: _submitForm,
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
                                              _isLogin ? 'Login' : 'Sign Up',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Inter',
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Divider with futuristic styling
                                  if (!_showForgotPasswordContent && _isLogin) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.grey[300]!,
                                                  Colors.grey[400]!,
                                                  Colors.grey[300]!,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'OR CONTINUE WITH',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[500],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.grey[300]!,
                                                  Colors.grey[400]!,
                                                  Colors.grey[300]!,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 15), // Reduced from 20

                                    // Google sign-in button (wide style) - only show in login mode
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: _buildWideGoogleButton(
                                        _handleGoogleSignIn,
                                      ),
                                    ),

                                    const SizedBox(height: 10), // Reduced from 13
                                  ],

                                  const SizedBox(height: 5), // Reduced from 10

                                  // Mode switch with elegant, classic styling
                                  if (!_showForgotPasswordContent) Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.only(bottom: screenHeight * 0.03), // Added margin to ensure visibility
                                    child: Center(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4), // Reduced from 6
                                      child: TextButton(
                                        onPressed: _switchMode,
                                        style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20), // Reduced padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 14 : 16, // Smaller font on small screens
                                              fontWeight: FontWeight.w400,
                                              fontFamily: 'Inter',
                                              color: Color(0xFF6B7280),
                                              height: 1.5,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: _isLogin ? 'Don\'t have an account? ' : 'Already have an account? ',
                                              ),
                                              TextSpan(
                                                text: _isLogin ? 'Sign Up' : 'Login',
                                                style: const TextStyle(
                                                  color: kPrimaryBlue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            : FadeTransition(
                          opacity: _optionsContentFadeAnimation,
                          // Make the options container scrollable to prevent overflow on small screens
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? verticalSpacing * 0.6 : verticalSpacing, // Reduced padding further
                                horizontal: horizontalPadding * 0.5,
                              ),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    kPrimaryBlue,
                                    kSecondaryBlue,
                                    kLightBlue,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  '',
                                  style: TextStyle(
                                        fontSize: isSmallScreen ? 20 : 22,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF1F2937),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                                  SizedBox(height: verticalSpacing * 0.8), // Reduced from verticalSpacing
                              Padding(
                                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: Container(
                                      height: buttonHeight * 0.9, // Reduced button height
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
                                    onPressed: () => _navigateToLoginContent(isLoginMode: true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                        child: Text(
                                      'Login',
                                      style: TextStyle(
                                            fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                                  SizedBox(height: verticalSpacing * 0.8), // Reduced from verticalSpacing
                              Padding(
                                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: Container(
                                      height: buttonHeight * 0.9, // Reduced button height
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
                                    onPressed: () => _navigateToLoginContent(isLoginMode: false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                        child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                            fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                                  // Add bottom padding to ensure content doesn't get cut off
                                  SizedBox(height: verticalSpacing * 0.8), // Reduced from verticalSpacing
                            ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    // Determine which visibility state to use
    bool isVisible = false;
    if (isPassword) {
      if (controller == _newPasswordController) {
        isVisible = _isNewPasswordVisible;
      } else if (controller == _confirmNewPasswordController) {
        isVisible = _isConfirmNewPasswordVisible;
      } else if (isConfirmPassword) {
        isVisible = _isConfirmPasswordVisible;
      } else {
        isVisible = _isPasswordVisible;
      }
    }

    // Get screen dimensions for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    final inputFontSize = isSmallScreen ? 14.0 : 16.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !isVisible : false,
        validator: validator,
        style: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: inputFontSize,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: inputFontSize,
          ),
          prefixIcon: Icon(
            icon,
            color: kPrimaryBlue,
            size: iconSize,
          ),
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: kPrimaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String imagePath, VoidCallback onPressed, {double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Image.asset(
          imagePath,
          width: size * 0.5,
          height: size * 0.5,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildWideGoogleButton(VoidCallback onPressed) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isGoogleSignInLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isGoogleSignInLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                    ),
                  )
                : Image.asset(
              'assets/images/google_icon.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _isGoogleSignInLoading ? 'Signing in...' : 'Continue with Google',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Color(0xFF1F2937),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method for Google sign-in
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleSignInLoading = true;
    });
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        // Get user ID and user info
        final userId = userCredential.user!.uid;
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        // Save user ID to shared preferences
        final prefs = await SharedPreferences.getInstance();
        
        // Check if this Google user has signed in before and completed profile
        final existingUserId = prefs.getString('user_id');
        final hasCompletedProfile = prefs.getBool('google_profile_completed_$userId') ?? false;
        final isReturningUser = existingUserId == userId && hasCompletedProfile;
        
        // Always save the user ID
        await prefs.setString('user_id', userId);
        await prefs.setBool('is_first_launch', false);
        
        // If user is new OR hasn't completed their profile yet, show the account creation form
        if (isNewUser || !hasCompletedProfile) {
          if (mounted) {
            // Pre-fill email if available
            if (userCredential.user?.email != null) {
              _emailController.text = userCredential.user!.email!;
            }
            
            // Pre-fill name if available
            if (userCredential.user?.displayName != null) {
              _nameController.text = userCredential.user!.displayName!;
            }
            
            // Navigate to sign up form
            setState(() {
              _isGoogleSignInLoading = false;
              _isLogin = false; // Switch to sign up mode
              _showLoginContent = true;
              _showOptionsContainer = false;
              _formContentOpacity = 1.0;
              _containerExpandPosition = 1.0;
            });
            
            // Ensure content fade controller is at the right value
            _contentFadeController.value = 1.0;
            
            // Adjust container position for sign up form
            _animateFormContentOffset(30.0);
            
            // Start transition animation for background image if not already started
            if (_transitionController.status != AnimationStatus.completed) {
              _transitionController.forward();
            }
            
            // Fade out the logo if needed
            if (_fadeController.status != AnimationStatus.completed) {
              _fadeController.forward();
            }
            
            // Show a message to complete profile
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please complete your profile to continue'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          // For returning Google users, set has_membership to true if not already set
          // This ensures returning Google users don't see the membership screen again
          if (isReturningUser) {
            // If they're a returning user, ensure has_membership is set to true
            await prefs.setBool('has_membership', true);
          }
          
          // Check if user has selected a membership
          final hasMembership = prefs.getBool('has_membership') ?? false;
          
          if (mounted) {
            if (hasMembership || isReturningUser) {
              // Navigate directly to home page for returning users or users with membership
              Navigator.pushReplacementNamed(context, '/homepage');
            } else {
              // Navigate to membership selection page for new users who completed Google sign-in
              Navigator.pushReplacementNamed(context, '/membership');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted && _isGoogleSignInLoading) {
        setState(() {
          _isGoogleSignInLoading = false;
        });
      }
    }
  }
}
