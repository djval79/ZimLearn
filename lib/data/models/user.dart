import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String username;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String? phoneNumber;
  
  @HiveField(4)
  final String? firstName;
  
  @HiveField(5)
  final String? lastName;
  
  @HiveField(6)
  final DateTime? dateOfBirth;
  
  @HiveField(7)
  final String gradeLevel;
  
  @HiveField(8)
  final String preferredLanguage;
  
  @HiveField(9)
  final String? profileImageUrl;
  
  @HiveField(10)
  final String region;
  
  @HiveField(11)
  final bool isVerified;
  
  @HiveField(12)
  final UserSubscription subscription;
  
  @HiveField(13)
  final UserPreferences preferences;
  
  @HiveField(14)
  final DateTime createdAt;
  
  @HiveField(15)
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    required this.gradeLevel,
    required this.preferredLanguage,
    this.profileImageUrl,
    required this.region,
    this.isVerified = false,
    required this.subscription,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        phoneNumber,
        firstName,
        lastName,
        dateOfBirth,
        gradeLevel,
        preferredLanguage,
        profileImageUrl,
        region,
        isVerified,
        subscription,
        preferences,
        createdAt,
        updatedAt,
      ];

  User copyWith({
    String? username,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gradeLevel,
    String? preferredLanguage,
    String? profileImageUrl,
    String? region,
    bool? isVerified,
    UserSubscription? subscription,
    UserPreferences? preferences,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      region: region ?? this.region,
      isVerified: isVerified ?? this.isVerified,
      subscription: subscription ?? this.subscription,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gradeLevel': gradeLevel,
      'preferredLanguage': preferredLanguage,
      'profileImageUrl': profileImageUrl,
      'region': region,
      'isVerified': isVerified,
      'subscription': subscription.toJson(),
      'preferences': preferences.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      gradeLevel: json['gradeLevel'],
      preferredLanguage: json['preferredLanguage'],
      profileImageUrl: json['profileImageUrl'],
      region: json['region'],
      isVerified: json['isVerified'] ?? false,
      subscription: UserSubscription.fromJson(json['subscription']),
      preferences: UserPreferences.fromJson(json['preferences']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return ' ';
    } else if (firstName != null) {
      return firstName!;
    } else {
      return username;
    }
  }

  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isPremiumUser {
    return subscription.tier == 'premium' || subscription.tier == 'family';
  }

  bool get isSubscriptionActive {
    return subscription.isActive && 
           (subscription.expiryDate?.isAfter(DateTime.now()) ?? false);
  }
}

@HiveType(typeId: 1)
class UserSubscription extends Equatable {
  @HiveField(0)
  final String tier; // basic, standard, premium, family
  
  @HiveField(1)
  final bool isActive;
  
  @HiveField(2)
  final DateTime? startDate;
  
  @HiveField(3)
  final DateTime? expiryDate;
  
  @HiveField(4)
  final String? paymentMethod;
  
  @HiveField(5)
  final double? monthlyPrice;

  const UserSubscription({
    required this.tier,
    required this.isActive,
    this.startDate,
    this.expiryDate,
    this.paymentMethod,
    this.monthlyPrice,
  });

  @override
  List<Object?> get props => [
        tier,
        isActive,
        startDate,
        expiryDate,
        paymentMethod,
        monthlyPrice,
      ];

  UserSubscription copyWith({
    String? tier,
    bool? isActive,
    DateTime? startDate,
    DateTime? expiryDate,
    String? paymentMethod,
    double? monthlyPrice,
  }) {
    return UserSubscription(
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'monthlyPrice': monthlyPrice,
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      tier: json['tier'],
      isActive: json['isActive'] ?? false,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : null,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : null,
      paymentMethod: json['paymentMethod'],
      monthlyPrice: json['monthlyPrice']?.toDouble(),
    );
  }

  static UserSubscription get free => const UserSubscription(
        tier: 'basic',
        isActive: true,
      );

  bool get isFree => tier == 'basic';
  bool get isPaid => !isFree && isActive;
  
  int get daysUntilExpiry {
    if (expiryDate == null) return -1;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
}

@HiveType(typeId: 2)
class UserPreferences extends Equatable {
  @HiveField(0)
  final bool enableNotifications;
  
  @HiveField(1)
  final bool enableSounds;
  
  @HiveField(2)
  final bool enableVibration;
  
  @HiveField(3)
  final bool enableOfflineMode;
  
  @HiveField(4)
  final double fontSize;
  
  @HiveField(5)
  final String themeMode; // light, dark, system
  
  @HiveField(6)
  final bool enableDataSaver;
  
  @HiveField(7)
  final bool enableAutoDownload;
  
  @HiveField(8)
  final List<String> subjectsOfInterest;
  
  @HiveField(9)
  final int dailyStudyGoalMinutes;
  
  @HiveField(10)
  final String reminderTime; // HH:MM format
  
  @HiveField(11)
  final List<String> reminderDays; // Mon, Tue, Wed, etc.

  const UserPreferences({
    this.enableNotifications = true,
    this.enableSounds = true,
    this.enableVibration = true,
    this.enableOfflineMode = true,
    this.fontSize = 16.0,
    this.themeMode = 'system',
    this.enableDataSaver = false,
    this.enableAutoDownload = false,
    this.subjectsOfInterest = const [],
    this.dailyStudyGoalMinutes = 30,
    this.reminderTime = '18:00',
    this.reminderDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  });

  @override
  List<Object?> get props => [
        enableNotifications,
        enableSounds,
        enableVibration,
        enableOfflineMode,
        fontSize,
        themeMode,
        enableDataSaver,
        enableAutoDownload,
        subjectsOfInterest,
        dailyStudyGoalMinutes,
        reminderTime,
        reminderDays,
      ];

  UserPreferences copyWith({
    bool? enableNotifications,
    bool? enableSounds,
    bool? enableVibration,
    bool? enableOfflineMode,
    double? fontSize,
    String? themeMode,
    bool? enableDataSaver,
    bool? enableAutoDownload,
    List<String>? subjectsOfInterest,
    int? dailyStudyGoalMinutes,
    String? reminderTime,
    List<String>? reminderDays,
  }) {
    return UserPreferences(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSounds: enableSounds ?? this.enableSounds,
      enableVibration: enableVibration ?? this.enableVibration,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
      enableDataSaver: enableDataSaver ?? this.enableDataSaver,
      enableAutoDownload: enableAutoDownload ?? this.enableAutoDownload,
      subjectsOfInterest: subjectsOfInterest ?? this.subjectsOfInterest,
      dailyStudyGoalMinutes: dailyStudyGoalMinutes ?? this.dailyStudyGoalMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'enableSounds': enableSounds,
      'enableVibration': enableVibration,
      'enableOfflineMode': enableOfflineMode,
      'fontSize': fontSize,
      'themeMode': themeMode,
      'enableDataSaver': enableDataSaver,
      'enableAutoDownload': enableAutoDownload,
      'subjectsOfInterest': subjectsOfInterest,
      'dailyStudyGoalMinutes': dailyStudyGoalMinutes,
      'reminderTime': reminderTime,
      'reminderDays': reminderDays,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      enableNotifications: json['enableNotifications'] ?? true,
      enableSounds: json['enableSounds'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      enableOfflineMode: json['enableOfflineMode'] ?? true,
      fontSize: (json['fontSize'] ?? 16.0).toDouble(),
      themeMode: json['themeMode'] ?? 'system',
      enableDataSaver: json['enableDataSaver'] ?? false,
      enableAutoDownload: json['enableAutoDownload'] ?? false,
      subjectsOfInterest: List<String>.from(json['subjectsOfInterest'] ?? []),
      dailyStudyGoalMinutes: json['dailyStudyGoalMinutes'] ?? 30,
      reminderTime: json['reminderTime'] ?? '18:00',
      reminderDays: List<String>.from(json['reminderDays'] ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']),
    );
  }
}
