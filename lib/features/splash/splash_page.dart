import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../core/routing/route_extensions.dart';
import '../../core/routing/app_router.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/onboarding/bloc/onboarding_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isError = false;
  String _errorMessage = '';
  
  // Flag to track if navigation has been triggered
  bool _hasNavigated = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
    // Initialize app and check auth state
    _initializeApp();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Delay for minimum splash screen display time
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Check connectivity
      final connectivityService = sl<ConnectivityService>();
      final isConnected = await connectivityService.isConnected();
      
      if (!isConnected) {
        // Handle offline mode
        final storageService = sl<StorageService>();
        final hasOfflineData = await storageService.containsKey('user_data');
        
        if (!hasOfflineData) {
          _showError('No internet connection. Please connect to continue.');
          return;
        }
      }
      
      // Check auth state using BLoC
      if (!mounted) return;
      
      // Listen for auth state changes
      final authBloc = context.read<AuthBloc>();
      
      // Dispatch auth check event if not already done
      if (authBloc.state is AuthInitial) {
        authBloc.add(AuthStarted());
      }
      
      // Set up subscription to handle auth state changes
      final subscription = authBloc.stream.listen((state) {
        if (!mounted || _hasNavigated) return;
        
        if (state is AuthAuthenticated) {
          _navigateBasedOnUserState(state);
        } else if (state is AuthUnauthenticated) {
          _navigateToLogin();
        } else if (state is AuthError) {
          _showError(state.message);
        }
      });
      
      // Cancel subscription after 5 seconds if no auth state change
      Future.delayed(const Duration(seconds: 5), () {
        subscription.cancel();
        if (mounted && !_hasNavigated) {
          _showError('Authentication check timed out. Please try again.');
        }
      });
    } catch (e) {
      _showError('Failed to initialize app: ${e.toString()}');
    }
  }
  
  void _navigateBasedOnUserState(AuthAuthenticated state) {
    if (!mounted || _hasNavigated) return;
    
    _hasNavigated = true;
    
    // Check if onboarding is completed
    final storageService = sl<StorageService>();
    final hasCompletedOnboarding = storageService.getBool('has_completed_onboarding') ?? false;
    
    if (!hasCompletedOnboarding) {
      // Navigate to onboarding
      context.go(AppRoutes.onboarding);
    } else {
      // Navigate to dashboard
      context.go(AppRoutes.dashboard);
    }
  }
  
  void _navigateToLogin() {
    if (!mounted || _hasNavigated) return;
    
    _hasNavigated = true;
    context.go(AppRoutes.login);
  }
  
  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isError = true;
        _errorMessage = message;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary, // Zimbabwean green
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background pattern with Zimbabwean flag colors
              Positioned.fill(
                child: CustomPaint(
                  painter: ZimbabweanPatternPainter(
                    progress: _animationController.value,
                  ),
                ),
              ),
              
              // Main content
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.school,
                                size: 80,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // App name
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: Text(
                            AppConstants.appName,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Tagline
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: Text(
                            AppConstants.appTagline,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Loading indicator or error message
                        if (_isError)
                          _buildErrorMessage(theme)
                        else
                          _buildLoadingIndicator(theme),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Zimbabwe flag emblem in corner
              Positioned(
                bottom: 24,
                right: 24,
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Image.asset(
                    'assets/images/zim_emblem.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if image is not available
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🇿🇼',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingIndicator(ThemeData theme) {
    return Column(
      children: [
        // Custom loading animation
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.secondary, // Zimbabwean yellow/gold
            ),
            strokeWidth: 4,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Loading text
        Text(
          'Initializing...',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorMessage(ThemeData theme) {
    return Column(
      children: [
        // Error icon
        Icon(
          Icons.error_outline,
          size: 60,
          color: theme.colorScheme.tertiary, // Zimbabwean red
        ),
        
        const SizedBox(height: 16),
        
        // Error message
        Text(
          _errorMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Retry button
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isError = false;
              _errorMessage = '';
              _hasNavigated = false;
            });
            _initializeApp();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

/// Custom painter for Zimbabwean-themed background pattern
class ZimbabweanPatternPainter extends CustomPainter {
  final double progress;
  
  ZimbabweanPatternPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Zimbabwean flag colors
    const green = Color(0xFF008751);
    const yellow = Color(0xFFFFD700);
    const red = Color(0xFFCE1126);
    const black = Color(0xFF000000);
    const white = Colors.white;
    
    // Background
    final backgroundPaint = Paint()..color = green;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // Diagonal stripes pattern (inspired by Zimbabwe flag)
    final stripePaint = Paint()
      ..color = yellow.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    final stripeWidth = size.width * 0.2;
    final numStripes = (size.height / (stripeWidth * 0.5)).ceil() + 2;
    
    for (int i = 0; i < numStripes; i++) {
      final path = Path();
      final yOffset = i * stripeWidth * 0.7 - stripeWidth;
      final animatedOffset = yOffset + (size.height * 0.3 * (1 - progress));
      
      path.moveTo(0, animatedOffset);
      path.lineTo(size.width, animatedOffset + size.width * 0.2);
      path.lineTo(size.width, animatedOffset + size.width * 0.2 + stripeWidth);
      path.lineTo(0, animatedOffset + stripeWidth);
      path.close();
      
      canvas.drawPath(path, stripePaint);
    }
    
    // Zimbabwe bird symbol (simplified)
    if (progress > 0.5) {
      final symbolOpacity = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final symbolPaint = Paint()
        ..color = white.withOpacity(symbolOpacity * 0.1)
        ..style = PaintingStyle.fill;
      
      final centerX = size.width * 0.5;
      final centerY = size.height * 0.25;
      final symbolSize = size.width * 0.4;
      
      final symbolPath = Path();
      
      // Simplified Zimbabwe bird symbol
      symbolPath.moveTo(centerX, centerY - symbolSize * 0.3);
      symbolPath.lineTo(centerX + symbolSize * 0.3, centerY + symbolSize * 0.1);
      symbolPath.lineTo(centerX, centerY + symbolSize * 0.3);
      symbolPath.lineTo(centerX - symbolSize * 0.3, centerY + symbolSize * 0.1);
      symbolPath.close();
      
      canvas.drawPath(symbolPath, symbolPaint);
    }
  }
  
  @override
  bool shouldRepaint(ZimbabweanPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
