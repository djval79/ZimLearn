import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../../data/models/user.dart';
import 'storage_service.dart';

/// Authentication result status
enum AuthStatus {
  authenticated,
  unauthenticated,
  error,
  networkError,
  invalidCredentials,
  accountLocked,
  unverified,
  biometricsAvailable,
  biometricsUnavailable,
  biometricsNoEnrolled,
  biometricsError,
}

/// Authentication service that handles user authentication, token management,
/// and secure storage of authentication data. Also supports biometric authentication
/// for enhanced security and user experience.
class AuthService {
  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Connectivity _connectivity = Connectivity();
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();
  
  // Token keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _biometricsEnabledKey = 'biometrics_enabled';
  static const String _userCredentialsKey = 'user_credentials';
  
  // Auth state stream controller
  final _authStateController = StreamController<AuthStatus>.broadcast();
  
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() => _instance;
  
  AuthService._internal();
  
  // Getters
  Stream<AuthStatus> get authStateStream => _authStateController.stream;
  
  /// Initializes the authentication service.
  Future<void> initialize() async {
    try {
      _logger.i('Initializing AuthService...');
      
      // Check if user is already authenticated
      final isAuthenticated = await isLoggedIn();
      
      // Emit initial auth state
      _authStateController.add(
        isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated
      );
      
      // Check token expiry and refresh if needed
      if (isAuthenticated) {
        final shouldRefresh = await _shouldRefreshToken();
        if (shouldRefresh) {
          await refreshToken();
        }
      }
      
      _logger.i('AuthService initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Error initializing AuthService', error: e, stackTrace: stackTrace);
      _authStateController.add(AuthStatus.error);
    }
  }
  
  /// Registers a new user with email and password.
  Future<AuthStatus> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gradeLevel,
    required String preferredLanguage,
    required String region,
  }) async {
    try {
      _logger.i('Registering new user: $email');
      
      // Check connectivity
      if (!await _isOnline()) {
        _logger.w('Cannot register: Device is offline');
        return AuthStatus.networkError;
      }
      
      // Prepare registration data
      final Map<String, dynamic> registrationData = {
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'gradeLevel': gradeLevel,
        'preferredLanguage': preferredLanguage,
        'region': region,
      };
      
      // Make API request to register user
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.auth}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registrationData),
      ).timeout(AppConstants.defaultTimeout);
      
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Save tokens
        await _saveTokens(
          accessToken: responseData['accessToken'],
          refreshToken: responseData['refreshToken'],
          expiryTime: responseData['expiresIn'],
        );
        
        // Save user data
        final User user = User.fromJson(responseData['user']);
        await _storageService.saveUser(user);
        
        // Update auth state
        _authStateController.add(AuthStatus.authenticated);
        
        _logger.i('User registered successfully: ${user.id}');
        return AuthStatus.authenticated;
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        _logger.w('Registration failed: ${responseData['message']}');
        return AuthStatus.invalidCredentials;
      } else {
        _logger.e('Registration failed with status code: ${response.statusCode}');
        return AuthStatus.error;
      }
    } catch (e, stackTrace) {
      _logger.e('Error during registration', error: e, stackTrace: stackTrace);
      return AuthStatus.error;
    }
  }
  
  /// Logs in a user with email and password.
  Future<AuthStatus> login({
    required String email,
    required String password,
    bool rememberCredentials = false,
  }) async {
    try {
      _logger.i('Logging in user: $email');
      
      // Check connectivity
      if (!await _isOnline()) {
        _logger.w('Cannot login: Device is offline');
        
        // Try offline authentication if credentials are stored
        if (await _hasStoredCredentials()) {
          return await _authenticateOffline(email, password);
        }
        
        return AuthStatus.networkError;
      }
      
      // Prepare login data
      final Map<String, dynamic> loginData = {
        'email': email,
        'password': password,
      };
      
      // Make API request to login
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.auth}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      ).timeout(AppConstants.defaultTimeout);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Save tokens
        await _saveTokens(
          accessToken: responseData['accessToken'],
          refreshToken: responseData['refreshToken'],
          expiryTime: responseData['expiresIn'],
        );
        
        // Save user data
        final User user = User.fromJson(responseData['user']);
        await _storageService.saveUser(user);
        
        // Store credentials if remember me is enabled
        if (rememberCredentials) {
          await _storeCredentials(email, password);
        }
        
        // Update auth state
        _authStateController.add(AuthStatus.authenticated);
        
        _logger.i('User logged in successfully: ${user.id}');
        return AuthStatus.authenticated;
      } else if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        final String errorType = responseData['error'] ?? 'invalid_credentials';
        
        if (errorType == 'account_locked') {
          _logger.w('Login failed: Account locked');
          return AuthStatus.accountLocked;
        } else if (errorType == 'unverified') {
          _logger.w('Login failed: Account not verified');
          return AuthStatus.unverified;
        } else {
          _logger.w('Login failed: Invalid credentials');
          return AuthStatus.invalidCredentials;
        }
      } else {
        _logger.e('Login failed with status code: ${response.statusCode}');
        return AuthStatus.error;
      }
    } catch (e, stackTrace) {
      _logger.e('Error during login', error: e, stackTrace: stackTrace);
      return AuthStatus.error;
    }
  }
  
  /// Logs out the current user.
  Future<void> logout() async {
    try {
      _logger.i('Logging out user');
      
      // Try to revoke token on server if online
      if (await _isOnline()) {
        final accessToken = await getAccessToken();
        if (accessToken != null) {
          try {
            await http.post(
              Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.auth}/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            ).timeout(const Duration(seconds: 5));
          } catch (e) {
            // Ignore errors during logout request
            _logger.w('Error during logout request: $e');
          }
        }
      }
      
      // Clear tokens
      await _clearTokens();
      
      // Clear user data
      await _storageService.clearUser();
      
      // Update auth state
      _authStateController.add(AuthStatus.unauthenticated);
      
      _logger.i('User logged out successfully');
    } catch (e, stackTrace) {
      _logger.e('Error during logout', error: e, stackTrace: stackTrace);
      // Still consider the user logged out even if there was an error
      _authStateController.add(AuthStatus.unauthenticated);
    }
  }
  
  /// Refreshes the access token using the refresh token.
  Future<bool> refreshToken() async {
    try {
      _logger.i('Refreshing access token');
      
      // Check connectivity
      if (!await _isOnline()) {
        _logger.w('Cannot refresh token: Device is offline');
        return false;
      }
      
      // Get refresh token
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        _logger.w('Cannot refresh token: No refresh token found');
        return false;
      }
      
      // Make API request to refresh token
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.auth}/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(AppConstants.defaultTimeout);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Save new tokens
        await _saveTokens(
          accessToken: responseData['accessToken'],
          refreshToken: responseData['refreshToken'],
          expiryTime: responseData['expiresIn'],
        );
        
        _logger.i('Token refreshed successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Refresh token is invalid or expired
        _logger.w('Token refresh failed: Invalid refresh token');
        await logout();
        return false;
      } else {
        _logger.e('Token refresh failed with status code: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Error refreshing token', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Checks if the user is logged in.
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await getAccessToken();
      final user = _storageService.getCurrentUser();
      
      return accessToken != null && user != null;
    } catch (e, stackTrace) {
      _logger.e('Error checking login status', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Gets the current access token.
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e, stackTrace) {
      _logger.e('Error getting access token', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Gets the current refresh token.
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e, stackTrace) {
      _logger.e('Error getting refresh token', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Checks if biometric authentication is available on the device.
  Future<AuthStatus> checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        _logger.i('Biometric authentication not available on this device');
        return AuthStatus.biometricsUnavailable;
      }
      
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        _logger.i('No biometrics enrolled on this device');
        return AuthStatus.biometricsNoEnrolled;
      }
      
      _logger.i('Biometric authentication available: $availableBiometrics');
      return AuthStatus.biometricsAvailable;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Error checking biometric availability', error: e, stackTrace: stackTrace);
      return AuthStatus.biometricsError;
    }
  }
  
  /// Enables biometric authentication for the current user.
  Future<bool> enableBiometricAuth() async {
    try {
      // Check if biometrics are available
      final biometricStatus = await checkBiometricAvailability();
      if (biometricStatus != AuthStatus.biometricsAvailable) {
        _logger.w('Cannot enable biometric auth: Biometrics not available');
        return false;
      }
      
      // Authenticate user with biometrics to confirm
      final authenticated = await _authenticateWithBiometrics(
        'Enable Biometric Login',
        'Authenticate to enable biometric login',
      );
      
      if (!authenticated) {
        _logger.w('Biometric authentication failed during enablement');
        return false;
      }
      
      // Enable biometrics flag
      await _secureStorage.write(key: _biometricsEnabledKey, value: 'true');
      
      _logger.i('Biometric authentication enabled successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Error enabling biometric authentication', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Disables biometric authentication for the current user.
  Future<bool> disableBiometricAuth() async {
    try {
      // Disable biometrics flag
      await _secureStorage.write(key: _biometricsEnabledKey, value: 'false');
      
      _logger.i('Biometric authentication disabled successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Error disabling biometric authentication', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Checks if biometric authentication is enabled for the current user.
  Future<bool> isBiometricAuthEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricsEnabledKey);
      return value == 'true';
    } catch (e, stackTrace) {
      _logger.e('Error checking if biometric auth is enabled', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Authenticates the user using biometrics.
  Future<AuthStatus> loginWithBiometrics() async {
    try {
      _logger.i('Attempting biometric login');
      
      // Check if biometric auth is enabled
      final isEnabled = await isBiometricAuthEnabled();
      if (!isEnabled) {
        _logger.w('Biometric authentication is not enabled');
        return AuthStatus.biometricsUnavailable;
      }
      
      // Check if credentials are stored
      if (!await _hasStoredCredentials()) {
        _logger.w('No stored credentials for biometric login');
        return AuthStatus.invalidCredentials;
      }
      
      // Authenticate with biometrics
      final authenticated = await _authenticateWithBiometrics(
        'ZimLearn Login',
        'Log in to your account using biometrics',
      );
      
      if (!authenticated) {
        _logger.w('Biometric authentication failed');
        return AuthStatus.biometricsError;
      }
      
      // Get stored credentials
      final credentials = await _getStoredCredentials();
      if (credentials == null) {
        _logger.w('Failed to retrieve stored credentials');
        return AuthStatus.error;
      }
      
      // Login with stored credentials
      return await login(
        email: credentials['email'],
        password: credentials['password'],
      );
    } catch (e, stackTrace) {
      _logger.e('Error during biometric login', error: e, stackTrace: stackTrace);
      return AuthStatus.biometricsError;
    }
  }
  
  /// Sends a password reset email to the user.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _logger.i('Sending password reset email to: $email');
      
      // Check connectivity
      if (!await _isOnline()) {
        _logger.w('Cannot send reset email: Device is offline');
        return false;
      }
      
      // Make API request to send reset email
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.auth}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(AppConstants.defaultTimeout);
      
      if (response.statusCode == 200) {
        _logger.i('Password reset email sent successfully');
        return true;
      } else {
        _logger.e('Failed to send password reset email: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Error sending password reset email', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Verifies the user's email address using a verification code.
  Future<bool> verifyEmail(String email, String verificationCode) async {
    try {
      _logger.i('Verifying email: $email');
      
      // Check connectivity
      if (!await _isOnline()) {
        _logger.w('Cannot verify email: Device is offline');
        return false;
      }
      
      // Make API request to verify email
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.auth}/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'verificationCode': verificationCode,
        }),
      ).timeout(AppConstants.defaultTimeout);
      
      if (response.statusCode == 200) {
        _logger.i('Email verified successfully');
        return true;
      } else {
        _logger.e('Failed to verify email: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Error verifying email', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Changes the user's password.
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _logger.i('Changing user password');
      
      // Check connectivity
      if (!await _isOnline()) {
        _logger.w('Cannot change password: Device is offline');
        return false;
      }
      
      // Get access token
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        _logger.w('Cannot change password: No access token');
        return false;
      }
      
      // Make API request to change password
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.auth}/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(AppConstants.defaultTimeout);
      
      if (response.statusCode == 200) {
        _logger.i('Password changed successfully');
        
        // Update stored credentials if they exist
        if (await _hasStoredCredentials()) {
          final credentials = await _getStoredCredentials();
          if (credentials != null) {
            await _storeCredentials(credentials['email'], newPassword);
          }
        }
        
        return true;
      } else if (response.statusCode == 401) {
        _logger.w('Password change failed: Invalid current password');
        return false;
      } else {
        _logger.e('Password change failed: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Error changing password', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Updates the user's profile information.
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _logger.i('Updating user profile');
      
      // Check connectivity
      if (!await _isOnline()) {
        _logger.w('Cannot update profile: Device is offline');
        return false;
      }
      
      // Get access token
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        _logger.w('Cannot update profile: No access token');
        return false;
      }
      
      // Make API request to update profile
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}${ApiEndpoints.user}/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(profileData),
      ).timeout(AppConstants.defaultTimeout);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Update user data
        final User user = User.fromJson(responseData['user']);
        await _storageService.saveUser(user);
        
        _logger.i('Profile updated successfully');
        return true;
      } else {
        _logger.e('Profile update failed: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Error updating profile', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Closes the auth service and releases resources.
  Future<void> dispose() async {
    await _authStateController.close();
  }
  
  /// Saves authentication tokens to secure storage.
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiryTime,
  }) async {
    try {
      // Calculate expiry date
      final expiryDate = DateTime.now().add(Duration(seconds: expiryTime));
      
      // Save tokens and expiry
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      await _secureStorage.write(
        key: _tokenExpiryKey,
        value: expiryDate.toIso8601String(),
      );
      
      _logger.i('Tokens saved successfully');
    } catch (e, stackTrace) {
      _logger.e('Error saving tokens', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Clears authentication tokens from secure storage.
  Future<void> _clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      
      _logger.i('Tokens cleared successfully');
    } catch (e, stackTrace) {
      _logger.e('Error clearing tokens', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Checks if the access token should be refreshed.
  Future<bool> _shouldRefreshToken() async {
    try {
      final expiryDateStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryDateStr == null) return true;
      
      final expiryDate = DateTime.parse(expiryDateStr);
      final now = DateTime.now();
      
      // Refresh if token expires in less than 5 minutes
      return expiryDate.difference(now).inMinutes < 5;
    } catch (e, stackTrace) {
      _logger.e('Error checking token expiry', error: e, stackTrace: stackTrace);
      return true;
    }
  }
  
  /// Stores user credentials securely for biometric authentication.
  Future<void> _storeCredentials(String email, String password) async {
    try {
      final credentials = {
        'email': email,
        'password': password,
      };
      
      await _secureStorage.write(
        key: _userCredentialsKey,
        value: jsonEncode(credentials),
      );
      
      _logger.i('User credentials stored securely');
    } catch (e, stackTrace) {
      _logger.e('Error storing credentials', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Gets stored user credentials.
  Future<Map<String, String>?> _getStoredCredentials() async {
    try {
      final credentialsJson = await _secureStorage.read(key: _userCredentialsKey);
      if (credentialsJson == null) return null;
      
      final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      return {
        'email': credentials['email'],
        'password': credentials['password'],
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting stored credentials', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Checks if user credentials are stored.
  Future<bool> _hasStoredCredentials() async {
    try {
      final credentialsJson = await _secureStorage.read(key: _userCredentialsKey);
      return credentialsJson != null;
    } catch (e, stackTrace) {
      _logger.e('Error checking stored credentials', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Authenticates the user with biometrics.
  Future<bool> _authenticateWithBiometrics(String title, String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e, stackTrace) {
      if (e.code == auth_error.notAvailable) {
        _logger.w('Biometric authentication not available');
      } else if (e.code == auth_error.notEnrolled) {
        _logger.w('No biometrics enrolled on this device');
      } else {
        _logger.e('Biometric authentication error', error: e, stackTrace: stackTrace);
      }
      return false;
    } catch (e, stackTrace) {
      _logger.e('Error during biometric authentication', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Authenticates the user offline using stored credentials.
  Future<AuthStatus> _authenticateOffline(String email, String password) async {
    try {
      _logger.i('Attempting offline authentication');
      
      final credentials = await _getStoredCredentials();
      if (credentials == null) {
        _logger.w('No stored credentials for offline authentication');
        return AuthStatus.networkError;
      }
      
      if (credentials['email'] == email && credentials['password'] == password) {
        _logger.i('Offline authentication successful');
        
        // Get user from storage
        final user = _storageService.getCurrentUser();
        if (user == null) {
          _logger.w('No user data found for offline authentication');
          return AuthStatus.error;
        }
        
        // Update auth state
        _authStateController.add(AuthStatus.authenticated);
        
        return AuthStatus.authenticated;
      } else {
        _logger.w('Offline authentication failed: Invalid credentials');
        return AuthStatus.invalidCredentials;
      }
    } catch (e, stackTrace) {
      _logger.e('Error during offline authentication', error: e, stackTrace: stackTrace);
      return AuthStatus.error;
    }
  }
  
  /// Checks if the device is online.
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  /// Generates a device ID for device identification.
  Future<String> getDeviceId() async {
    try {
      // Try to get existing device ID
      final existingId = await _secureStorage.read(key: 'device_id');
      if (existingId != null) {
        return existingId;
      }
      
      // Generate new device ID
      final deviceId = _uuid.v4();
      await _secureStorage.write(key: 'device_id', value: deviceId);
      
      return deviceId;
    } catch (e, stackTrace) {
      _logger.e('Error getting device ID', error: e, stackTrace: stackTrace);
      // Return a random ID as fallback
      return _uuid.v4();
    }
  }
}
