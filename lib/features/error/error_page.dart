import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:logger/logger.dart';

import '../../core/routing/route_extensions.dart';
import '../../core/routing/app_router.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/connectivity_service.dart';

class ErrorPage extends StatefulWidget {
  final Exception? error;
  final String? location;
  final String? errorCode;
  final String? customMessage;

  const ErrorPage({
    Key? key,
    this.error,
    this.location,
    this.errorCode,
    this.customMessage,
  }) : super(key: key);

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isCheckingConnectivity = false;
  bool _hasConnectivity = true;
  
  final Logger _logger = sl<Logger>();
  
  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
    // Log the error
    _logError();
    
    // Check connectivity
    _checkConnectivity();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _logError() {
    _logger.e(
      'Navigation error',
      error: widget.error,
      stackTrace: StackTrace.current,
    );
  }
  
  Future<void> _checkConnectivity() async {
    setState(() {
      _isCheckingConnectivity = true;
    });
    
    try {
      if (sl.isRegistered<ConnectivityService>()) {
        final connectivityService = sl<ConnectivityService>();
        final isConnected = await connectivityService.isConnected();
        
        setState(() {
          _hasConnectivity = isConnected;
          _isCheckingConnectivity = false;
        });
      } else {
        setState(() {
          _isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      _logger.e('Error checking connectivity', error: e);
      setState(() {
        _isCheckingConnectivity = false;
      });
    }
  }
  
  String _getErrorTitle() {
    if (widget.customMessage != null) {
      return widget.customMessage!;
    }
    
    if (widget.error != null) {
      final errorString = widget.error.toString().toLowerCase();
      
      if (errorString.contains('not found') || errorString.contains('404')) {
        return 'Page Not Found';
      } else if (errorString.contains('permission') || errorString.contains('403')) {
        return 'Access Denied';
      } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
        return 'Connection Timeout';
      } else if (errorString.contains('offline') || errorString.contains('connection')) {
        return 'Connection Error';
      }
    }
    
    return 'Something Went Wrong';
  }
  
  String _getErrorMessage() {
    if (widget.error != null) {
      final errorString = widget.error.toString().toLowerCase();
      
      if (errorString.contains('not found') || errorString.contains('404')) {
        return 'The page you were looking for could not be found. It might have been moved or deleted.';
      } else if (errorString.contains('permission') || errorString.contains('403')) {
        return 'You don\'t have permission to access this page. Please log in or contact support if you believe this is an error.';
      } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
        return 'The connection timed out. Please check your internet connection and try again.';
      } else if (errorString.contains('offline') || errorString.contains('connection')) {
        return 'You appear to be offline. Please check your internet connection and try again.';
      } else if (errorString.contains('parameter') || errorString.contains('argument')) {
        return 'There was an issue with the information provided. Please try again or contact support.';
      }
      
      return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }
    
    return 'We encountered an unexpected issue. Please try again or go back to the dashboard.';
  }
  
  List<String> _getTroubleshootingSteps() {
    if (!_hasConnectivity) {
      return [
        'Check your internet connection',
        'Enable Wi-Fi or mobile data',
        'Try accessing offline content',
        'Restart the app when you\'re back online'
      ];
    }
    
    if (widget.error != null) {
      final errorString = widget.error.toString().toLowerCase();
      
      if (errorString.contains('not found') || errorString.contains('404')) {
        return [
          'Check if the URL is correct',
          'Go back to the previous page',
          'Navigate to the dashboard',
          'Search for the content you need'
        ];
      } else if (errorString.contains('permission') || errorString.contains('403')) {
        return [
          'Make sure you\'re logged in',
          'Check if your subscription is active',
          'Contact support if you should have access',
          'Try logging out and back in'
        ];
      } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
        return [
          'Check your internet connection',
          'Try again in a few moments',
          'Switch to a different network if possible',
          'Restart the app if the problem persists'
        ];
      } else if (errorString.contains('parameter') || errorString.contains('argument')) {
        return [
          'Go back to the previous page',
          'Try the action again',
          'Clear app cache if the problem persists',
          'Update the app to the latest version'
        ];
      }
    }
    
    return [
      'Restart the app',
      'Check for app updates',
      'Clear the app cache',
      'Contact support if the problem persists'
    ];
  }
  
  String _getErrorCode() {
    if (widget.errorCode != null) {
      return widget.errorCode!;
    }
    
    if (widget.error != null) {
      final errorString = widget.error.toString();
      
      if (errorString.contains('not found') || errorString.contains('404')) {
        return 'ERR_NOT_FOUND';
      } else if (errorString.contains('permission') || errorString.contains('403')) {
        return 'ERR_ACCESS_DENIED';
      } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
        return 'ERR_TIMEOUT';
      } else if (errorString.contains('offline') || errorString.contains('connection')) {
        return 'ERR_CONNECTION';
      } else if (errorString.contains('parameter') || errorString.contains('argument')) {
        return 'ERR_INVALID_PARAM';
      }
      
      // Generate a unique error code based on error hash
      final errorHash = errorString.hashCode.abs() % 10000;
      return 'ERR_${errorHash.toString().padLeft(4, '0')}';
    }
    
    return 'ERR_UNKNOWN';
  }
  
  Widget _buildLottieAnimation() {
    if (!_hasConnectivity) {
      return Lottie.asset(
        'assets/animations/no_connection.json',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.wifi_off_rounded,
            size: 100,
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
          );
        },
      );
    }
    
    if (widget.error != null) {
      final errorString = widget.error.toString().toLowerCase();
      
      if (errorString.contains('not found') || errorString.contains('404')) {
        return Lottie.asset(
          'assets/animations/404.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.search_off_rounded,
              size: 100,
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
            );
          },
        );
      } else if (errorString.contains('permission') || errorString.contains('403')) {
        return Lottie.asset(
          'assets/animations/access_denied.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.no_accounts_rounded,
              size: 100,
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
            );
          },
        );
      }
    }
    
    return Lottie.asset(
      'assets/animations/error.json',
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.error_outline_rounded,
          size: 100,
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorTitle = _getErrorTitle();
    final errorMessage = _getErrorMessage();
    final troubleshootingSteps = _getTroubleshootingSteps();
    final errorCode = _getErrorCode();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animation or Icon
                _buildLottieAnimation(),
                
                const SizedBox(height: 24),
                
                // Error Title
                Text(
                  errorTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Error Message
                Text(
                  errorMessage,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Error Code
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Error Code: $errorCode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Troubleshooting Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Troubleshooting Steps',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...troubleshootingSteps.map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Go Back Button
                    if (context.canPop())
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.pop();
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    
                    if (context.canPop())
                      const SizedBox(width: 16),
                    
                    // Dashboard Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go(AppRoutes.dashboard);
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Dashboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Retry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (widget.location != null) {
                        context.go(widget.location!);
                      } else {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.dashboard);
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Support Link
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement support page navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support functionality coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: const Text('Contact Support'),
                ),
                
                const SizedBox(height: 16),
                
                // Location info (for debugging)
                if (widget.location != null)
                  Text(
                    'Location: ${widget.location}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: theme.colorScheme.background,
    );
  }
}
