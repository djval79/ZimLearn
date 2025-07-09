import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants.dart';
import '../../../data/models/user.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/subscription.dart';
import '../../common/widgets/glassmorphic_widgets.dart';
import '../../subscription/pages/pricing_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isScrolled = false;
  
  // Mock data - would come from BLoC in production
  final User _mockUser = User(
    id: '1',
    username: 'tafadzwa',
    email: 'tafadzwa@example.com',
    firstName: 'Tafadzwa',
    lastName: 'Moyo',
    gradeLevel: 'primary_4_7',
    preferredLanguage: 'en',
    region: 'harare',
    subscription: UserSubscription.basic, // Updated from free to basic
    preferences: const UserPreferences(),
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );
  
  // Mock subscription data - would come from SubscriptionBloc in production
  final Subscription _currentSubscription = Subscription.basicPlan;
  final DateTime _subscriptionEndDate = DateTime.now().add(const Duration(days: 15));
  
  final List<Map<String, dynamic>> _subjects = [
    {
      'id': 'math',
      'name': 'Mathematics',
      'icon': Icons.calculate,
      'color': const Color(0xFF008751), // Green
      'progress': 0.68,
      'lessons': 24,
      'completedLessons': 16,
    },
    {
      'id': 'english',
      'name': 'English',
      'icon': Icons.menu_book,
      'color': const Color(0xFFFFD700), // Yellow
      'progress': 0.75,
      'lessons': 20,
      'completedLessons': 15,
    },
    {
      'id': 'science',
      'name': 'Science',
      'icon': Icons.science,
      'color': const Color(0xFFCE1126), // Red
      'progress': 0.42,
      'lessons': 30,
      'completedLessons': 12,
    },
    {
      'id': 'geography',
      'name': 'Geography',
      'icon': Icons.public,
      'color': const Color(0xFF4CAF50), // Different green
      'progress': 0.55,
      'lessons': 18,
      'completedLessons': 10,
    },
    {
      'id': 'history',
      'name': 'History',
      'icon': Icons.history_edu,
      'color': const Color(0xFF9C27B0), // Purple
      'progress': 0.33,
      'lessons': 15,
      'completedLessons': 5,
    },
    {
      'id': 'agriculture',
      'name': 'Agriculture',
      'icon': Icons.grass,
      'color': const Color(0xFF795548), // Brown
      'progress': 0.6,
      'lessons': 15,
      'completedLessons': 9,
    },
  ];
  
  final List<Map<String, dynamic>> _quickActions = [
    {
      'id': 'upgrade',
      'name': 'Upgrade Plan',
      'icon': Icons.workspace_premium,
      'color': const Color(0xFFFFD700), // Yellow/Gold
    },
    {
      'id': 'offline',
      'name': 'Download Content',
      'icon': Icons.download_for_offline,
      'color': const Color(0xFF008751), // Green
    },
    {
      'id': 'business',
      'name': 'Business Simulation',
      'icon': Icons.store,
      'color': const Color(0xFFCE1126), // Red
    },
    {
      'id': 'ai_tutor',
      'name': 'AI Tutor',
      'icon': Icons.smart_toy,
      'color': const Color(0xFF2196F3), // Blue
    },
  ];
  
  final List<Map<String, dynamic>> _recentLessons = [
    {
      'id': '1',
      'title': 'Fractions and Decimals',
      'subject': 'Mathematics',
      'progress': 0.8,
      'lastAccessed': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': '2',
      'title': 'Great Zimbabwe Civilization',
      'subject': 'History',
      'progress': 0.5,
      'lastAccessed': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '3',
      'title': 'Photosynthesis',
      'subject': 'Science',
      'progress': 0.3,
      'lastAccessed': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isScrolled = _scrollController.offset > 20;
        });
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isYoungerChild {
    // Check if user is in early grades (ECD or Primary 1-3)
    return _mockUser.gradeLevel == 'ecd' || _mockUser.gradeLevel == 'primary_1_3';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: _isScrolled ? 'ZimLearn' : '',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // Navigate to profile with subscription options
              _showProfileOptions(context);
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                _mockUser.firstName?.substring(0, 1) ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF008751).withOpacity(0.8), // Green (Zimbabwe flag)
              const Color(0xFF000000).withOpacity(0.9), // Black (Zimbabwe flag)
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Greeting Section
              SliverToBoxAdapter(
                child: _buildGreetingSection(theme),
              ),
              
              // Subscription Status Card
              SliverToBoxAdapter(
                child: _buildSubscriptionStatusCard(theme),
              ),
              
              // Progress Overview
              SliverToBoxAdapter(
                child: _buildProgressOverview(theme),
              ),
              
              // Subject Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Your Subjects',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subject = _subjects[index];
                      return _buildSubjectCard(subject, theme, index);
                    },
                    childCount: _subjects.length,
                  ),
                ),
              ),
              
              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickActions.length,
                    itemBuilder: (context, index) {
                      final action = _quickActions[index];
                      return _buildQuickActionCard(action, theme, index);
                    },
                  ),
                ),
              ),
              
              // Recent Lessons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Text(
                    'Continue Learning',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lesson = _recentLessons[index];
                    return _buildRecentLessonCard(lesson, theme, index);
                  },
                  childCount: _recentLessons.length,
                ),
              ),
              
              // Special Section for Younger Children
              if (_isYoungerChild) ...[
                SliverToBoxAdapter(
                  child: _buildKidsSection(theme),
                ),
              ],
              
              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionGlass(
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 32,
        ),
        onPressed: () {
          // Show a fun animation for kids
          if (_isYoungerChild) {
            _showFunAnimation(context);
          } else {
            // Navigate to most relevant lesson
          }
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  Widget _buildGreetingSection(ThemeData theme) {
    String greeting;
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Hello, ${_mockUser.firstName ?? 'Student'}!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isYoungerChild) ...[
                const SizedBox(width: 8),
                PulseAnimationWidget(
                  child: Image.asset(
                    'assets/images/waving_hand.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.waving_hand, color: Colors.amber, size: 32),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s continue your learning journey!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  // New subscription status card
  Widget _buildSubscriptionStatusCard(ThemeData theme) {
    final daysRemaining = _subscriptionEndDate.difference(DateTime.now()).inDays;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GlassmorphicCard(
        height: 120,
        color: theme.colorScheme.secondary.withOpacity(0.2),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.5),
          width: 1,
        ),
        child: Stack(
          children: [
            // Premium badge for premium subscribers
            if (_currentSubscription.tier == SubscriptionTier.premium)
              Positioned(
                top: -8,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.black,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PREMIUM',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Subscription icon and info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: theme.colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Plan: ${_currentSubscription.name}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Expires in $daysRemaining days',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_currentSubscription.monthlyPrice.toStringAsFixed(2)}/month',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Upgrade button
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentSubscription.tier != SubscriptionTier.premium)
                          AnimatedGlassmorphicButton(
                            height: 40,
                            color: theme.colorScheme.secondary,
                            onPressed: () {
                              // Navigate to pricing page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PricingPage(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.upgrade,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Upgrade',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_currentSubscription.tier == SubscriptionTier.premium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Highest Tier',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview(ThemeData theme) {
    // Calculate overall progress
    final totalLessons = _subjects.fold<int>(0, (sum, subject) => sum + (subject['lessons'] as int));
    final completedLessons = _subjects.fold<int>(0, (sum, subject) => sum + (subject['completedLessons'] as int));
    final overallProgress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GlassmorphicCard(
        height: 140,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Your Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    percent: overallProgress,
                    lineHeight: 8,
                    animation: true,
                    animationDuration: 1500,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    progressColor: theme.colorScheme.secondary,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedLessons of $totalLessons lessons completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.calendar_today,
                        label: 'Streak',
                        value: '7 days',
                        theme: theme,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        icon: Icons.star,
                        label: 'Points',
                        value: '1,250',
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 10,
                  percent: overallProgress,
                  center: Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: theme.colorScheme.secondary,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, ThemeData theme, int index) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.1 * index,
          0.1 * index + 0.5,
          curve: Curves.easeOut,
        ),
      ),
    );
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: BouncingWidget(
          onTap: () {
            // Navigate to subject detail
          },
          child: _isYoungerChild 
              ? _buildKidFriendlySubjectCard(subject, theme)
              : _buildStandardSubjectCard(subject, theme),
        ),
      ),
    );
  }
  
  Widget _buildStandardSubjectCard(Map<String, dynamic> subject, ThemeData theme) {
    return GlassmorphicCard(
      color: (subject['color'] as Color).withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (subject['color'] as Color).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  subject['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              CircularPercentIndicator(
                radius: 16,
                lineWidth: 3,
                percent: subject['progress'] as double,
                progressColor: subject['color'] as Color,
                backgroundColor: Colors.white.withOpacity(0.2),
                center: Text(
                  '${((subject['progress'] as double) * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subject['name'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${subject['completedLessons']}/${subject['lessons']} lessons',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildKidFriendlySubjectCard(Map<String, dynamic> subject, ThemeData theme) {
    return KidsGlassmorphicContainer(
      color: subject['color'] as Color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            subject['icon'] as IconData,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            subject['name'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            percent: subject['progress'] as double,
            lineHeight: 8,
            width: 100,
            animation: true,
            animationDuration: 1500,
            backgroundColor: Colors.white.withOpacity(0.3),
            progressColor: Colors.white,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action, ThemeData theme, int index) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.2 + (0.1 * index),
          0.2 + (0.1 * index) + 0.5,
          curve: Curves.easeOut,
        ),
      ),
    );
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.5, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: BouncingWidget(
            onTap: () {
              // Handle quick action
              if (action['id'] == 'upgrade') {
                // Navigate to pricing page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PricingPage(),
                  ),
                );
              }
            },
            child: GlassmorphicCard(
              width: 100,
              height: 100,
              color: (action['color'] as Color).withOpacity(0.3),
              borderRadius: 16,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['name'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLessonCard(Map<String, dynamic> lesson, ThemeData theme, int index) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.3 + (0.1 * index),
          0.3 + (0.1 * index) + 0.5,
          curve: Curves.easeOut,
        ),
      ),
    );
    
    String timeAgo;
    final now = DateTime.now();
    final difference = now.difference(lesson['lastAccessed'] as DateTime);
    
    if (difference.inHours < 1) {
      timeAgo = '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours} hr ago';
    } else {
      timeAgo = '${difference.inDays} days ago';
    }
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: BouncingWidget(
            onTap: () {
              // Navigate to lesson
            },
            child: GlassmorphicCard(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson['subject'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearPercentIndicator(
                          percent: lesson['progress'] as double,
                          lineHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          progressColor: theme.colorScheme.secondary,
                          barRadius: const Radius.circular(2),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedGlassmorphicButton(
                        width: 80,
                        height: 32,
                        color: theme.colorScheme.secondary,
                        borderRadius: 8,
                        onPressed: () {
                          // Resume lesson
                        },
                        child: Text(
                          'Resume',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKidsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fun Learning Zone',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          KidsGlassmorphicContainer(
            height: 180,
            color: theme.colorScheme.secondary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Lottie.asset(
                    'assets/animations/kids_learning.json',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Center(child: Icon(Icons.child_care, color: Colors.white, size: 64)),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AnimatedGlassmorphicButton(
                    onPressed: () {
                      // Navigate to kids games
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Play & Learn',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.1),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: true,
                theme: theme,
              ),
              _buildNavItem(
                icon: Icons.school,
                label: 'Subjects',
                isSelected: false,
                theme: theme,
              ),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(
                icon: Icons.explore,
                label: 'Explore',
                isSelected: false,
                theme: theme,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                isSelected: false,
                theme: theme,
                onTap: () {
                  _showProfileOptions(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return BouncingWidget(
      onTap: onTap ?? () {
        // Navigate to tab
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? theme.colorScheme.secondary : Colors.white60,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected ? theme.colorScheme.secondary : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showFunAnimation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Lottie.asset(
            'assets/animations/celebration.json',
            onLoaded: (composition) {
              Future.delayed(composition.duration, () {
                Navigator.of(context).pop();
              });
            },
            errorBuilder: (context, error, stackTrace) => 
              const Center(child: Icon(Icons.celebration, color: Colors.white, size: 64)),
          ),
        ),
      ),
    );
  }
  
  // Profile options dialog with subscription options
  void _showProfileOptions(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // User info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        _mockUser.firstName?.substring(0, 1) ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_mockUser.firstName} ${_mockUser.lastName}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _mockUser.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: theme.colorScheme.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentSubscription.name} Plan',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
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
              
              const Divider(color: Colors.white12),
              
              // Subscription option
              ListTile(
                leading: Icon(
                  Icons.card_membership,
                  color: theme.colorScheme.secondary,
                ),
                title: const Text(
                  'Manage Subscription',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Change or upgrade your plan',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  // Navigate to pricing page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PricingPage(),
                    ),
                  );
                },
              ),
              
              // Other profile options
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Settings',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () {
                  // Navigate to settings
                  Navigator.pop(context);
                },
              ),
              
              ListTile(
                leading: const Icon(
                  Icons.help_outline,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Help & Support',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () {
                  // Navigate to help
                  Navigator.pop(context);
                },
              ),
              
              const Spacer(),
              
              // Logout button
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedGlassmorphicButton(
                  onPressed: () {
                    // Logout
                    Navigator.pop(context);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
