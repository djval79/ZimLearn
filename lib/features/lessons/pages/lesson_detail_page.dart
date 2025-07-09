import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/constants.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../common/widgets/glassmorphic_widgets.dart';
import '../../common/widgets/kids_animation_widgets.dart';
import '../bloc/lesson_bloc.dart';
import '../widgets/interactive_content_widget.dart';
import '../widgets/lesson_notes_widget.dart';

class LessonDetailPage extends StatefulWidget {
  final Lesson lesson;
  final bool isYoungerChild;
  
  const LessonDetailPage({
    Key? key,
    required this.lesson,
    this.isYoungerChild = false,
  }) : super(key: key);

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  late PageController _contentPageController;
  late VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  bool _isVideoInitialized = false;
  bool _isBookmarked = false;
  bool _showNotes = false;
  int _currentContentIndex = 0;
  double _currentProgress = 0.0;
  String _noteText = '';
  
  // Track if we've shown the celebration animation
  bool _hasShownCelebration = false;
  
  // Mock next and previous lessons
  Lesson? _nextLesson;
  Lesson? _previousLesson;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _scrollController = ScrollController();
    _contentPageController = PageController();
    
    // Initialize video if lesson has video content
    _initializeVideo();
    
    // Load lesson data
    _loadLessonData();
    
    // Mock next and previous lessons
    _loadAdjacentLessons();
  }
  
  Future<void> _initializeVideo() async {
    if (widget.lesson.hasVideoContent) {
      try {
        final videoUrl = widget.lesson.videoUrl;
        if (videoUrl != null && videoUrl.isNotEmpty) {
          _videoController = VideoPlayerController.network(videoUrl);
          await _videoController!.initialize();
          
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: false,
            looping: false,
            aspectRatio: 16 / 9,
            autoInitialize: true,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading video: $errorMessage',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            placeholder: Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
          
          setState(() {
            _isVideoInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error initializing video: $e');
      }
    }
  }
  
  void _loadLessonData() {
    // In a real app, we would load this from the bloc
    // For now, use mock data
    setState(() {
      _isBookmarked = widget.lesson.isBookmarked ?? false;
      _currentProgress = widget.lesson.progress ?? 0.0;
      _noteText = widget.lesson.notes ?? '';
    });
    
    // Start a timer to update progress as user views the lesson
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          // Increment progress by 5% every 10 seconds, max 100%
          _currentProgress = math.min(1.0, _currentProgress + 0.05);
          
          // Show celebration when reaching 100% if not shown before
          if (_currentProgress >= 1.0 && !_hasShownCelebration) {
            _hasShownCelebration = true;
            _showCompletionCelebration();
          }
        });
        
        // Save progress to bloc
        // context.read<LessonBloc>().add(UpdateLessonProgress(
        //   lessonId: widget.lesson.id,
        //   progress: _currentProgress,
        // ));
      }
    });
  }
  
  void _loadAdjacentLessons() {
    // In a real app, we would load this from the bloc
    // For now, use mock data
    _nextLesson = Lesson(
      id: 'next_lesson',
      title: 'Next: Advanced Concepts',
      description: 'Taking your knowledge to the next level',
      subject: widget.lesson.subject,
      gradeLevel: widget.lesson.gradeLevel,
      contentType: ContentType.mixed,
      progress: 0.0,
    );
    
    _previousLesson = Lesson(
      id: 'prev_lesson',
      title: 'Previous: Basic Concepts',
      description: 'Foundation knowledge',
      subject: widget.lesson.subject,
      gradeLevel: widget.lesson.gradeLevel,
      contentType: ContentType.text,
      progress: 1.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _contentPageController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  
  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    // In a real app, we would save this to the bloc
    // context.read<LessonBloc>().add(ToggleLessonBookmark(
    //   lessonId: widget.lesson.id,
    //   isBookmarked: _isBookmarked,
    // ));
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked 
              ? 'Lesson added to bookmarks' 
              : 'Lesson removed from bookmarks',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _toggleNotes() {
    setState(() {
      _showNotes = !_showNotes;
    });
  }
  
  void _saveNotes(String notes) {
    setState(() {
      _noteText = notes;
    });
    
    // In a real app, we would save this to the bloc
    // context.read<LessonBloc>().add(UpdateLessonNotes(
    //   lessonId: widget.lesson.id,
    //   notes: notes,
    // ));
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes saved successfully'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _navigateToNextLesson() {
    if (_nextLesson != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LessonDetailPage(
            lesson: _nextLesson!,
            isYoungerChild: widget.isYoungerChild,
          ),
        ),
      );
    }
  }
  
  void _navigateToPreviousLesson() {
    if (_previousLesson != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LessonDetailPage(
            lesson: _previousLesson!,
            isYoungerChild: widget.isYoungerChild,
          ),
        ),
      );
    }
  }
  
  void _showCompletionCelebration() {
    if (widget.isYoungerChild) {
      // Show fun celebration for younger kids
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                height: 300,
                child: ConfettiCelebration(
                  onComplete: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 20),
              GlassmorphicCard(
                width: 300,
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Great Job! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedGlassmorphicButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Continue Learning',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
    } else {
      // Show more mature celebration for older students
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 16),
              const Text('Lesson completed successfully!'),
              const Spacer(),
              TextButton(
                onPressed: _navigateToNextLesson,
                child: const Text(
                  'Next Lesson',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: widget.lesson.title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? theme.colorScheme.secondary : Colors.white,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: Icon(
              Icons.note_alt_outlined,
              color: _showNotes ? theme.colorScheme.secondary : Colors.white,
            ),
            onPressed: _toggleNotes,
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
          child: Stack(
            children: [
              // Main content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Progress indicator
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Progress',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_currentProgress * 100).toInt()}%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          widget.isYoungerChild
                              ? RainbowProgressIndicator(
                                  percent: _currentProgress,
                                  height: 12,
                                )
                              : LinearPercentIndicator(
                                  percent: _currentProgress,
                                  lineHeight: 8,
                                  animation: true,
                                  animationDuration: 500,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  progressColor: theme.colorScheme.secondary,
                                  barRadius: const Radius.circular(4),
                                  padding: EdgeInsets.zero,
                                ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Video player (if available)
                  if (widget.lesson.hasVideoContent) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: GlassmorphicCard(
                          height: 230,
                          child: _isVideoInitialized && _chewieController != null
                              ? Chewie(controller: _chewieController!)
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Lesson title and details
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSubjectColor(widget.lesson.subject).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.lesson.subject ?? 'General',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getLessonTypeText(widget.lesson.contentType),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          widget.isYoungerChild
                              ? DancingLetters(
                                  text: widget.lesson.title,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  widget.lesson.title,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            widget.lesson.description ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Lesson content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GlassmorphicCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Lesson Content',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(
                              color: Colors.white24,
                              height: 1,
                            ),
                            SizedBox(
                              height: 400,
                              child: PageView(
                                controller: _contentPageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentContentIndex = index;
                                  });
                                },
                                children: [
                                  // Main content
                                  _buildMainContent(theme),
                                  
                                  // Interactive content
                                  _buildInteractiveContent(theme),
                                  
                                  // Summary content
                                  _buildSummaryContent(theme),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (index) => _buildPageIndicator(index, theme),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Navigation between lessons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Row(
                        children: [
                          if (_previousLesson != null)
                            Expanded(
                              child: AnimatedGlassmorphicButton(
                                height: 50,
                                onPressed: _navigateToPreviousLesson,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Previous Lesson',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          if (_nextLesson != null)
                            Expanded(
                              child: AnimatedGlassmorphicButton(
                                height: 50,
                                color: theme.colorScheme.secondary,
                                onPressed: _navigateToNextLesson,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Next Lesson',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 50),
                  ),
                ],
              ),
              
              // Notes overlay
              if (_showNotes)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: LessonNotesWidget(
                        initialNotes: _noteText,
                        onSave: _saveNotes,
                        onClose: _toggleNotes,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isYoungerChild
          ? FloatingActionGlass(
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                _showCompletionCelebration();
              },
            )
          : null,
    );
  }
  
  Widget _buildMainContent(ThemeData theme) {
    // This would be dynamic content from the lesson
    // For now, use mock markdown content
    const String markdownContent = '''
# Introduction

This lesson will cover the fundamental concepts of this subject. We'll explore the key ideas and principles that form the foundation of your understanding.

## Key Concepts

1. **First Principle**: Understanding the basic elements
2. **Second Principle**: How elements interact with each other
3. **Third Principle**: Applying concepts to real-world scenarios

## Example

Consider the following example:

> When we apply the first principle to a real situation, we observe that the outcome depends on multiple factors including the initial conditions and external influences.

### Mathematical Expression

If we represent this as a mathematical equation:

$y = mx + b$

Where:
- $y$ is the outcome
- $m$ is the rate of change
- $x$ is the input variable
- $b$ is the initial condition

## Practical Application

In Zimbabwe, these principles can be observed in various sectors:

1. Agriculture: Crop yields depend on soil quality, rainfall, and farming techniques
2. Business: Market dynamics follow similar patterns of input and output relationships
3. Education: Learning outcomes depend on teaching quality, student engagement, and resources
''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: markdownContent,
            styleSheet: MarkdownStyleSheet(
              h1: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              h2: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              h3: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              p: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              listBullet: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              blockquote: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
              blockquoteDecoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              blockquotePadding: const EdgeInsets.all(16),
              code: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
                backgroundColor: Colors.black45,
              ),
              codeblockDecoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              codeblockPadding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteractiveContent(ThemeData theme) {
    // In a real app, this would be interactive content from the lesson
    // For now, use a placeholder
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              color: theme.colorScheme.secondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Interactive Content',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This section would contain interactive exercises, quizzes, and activities related to the lesson.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Sample interactive element
            GlassmorphicCard(
              height: 120,
              child: Center(
                child: Text(
                  'Tap to interact with content',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'In this lesson, we covered:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            icon: Icons.check_circle,
            text: 'The fundamental principles and concepts',
            theme: theme,
          ),
          _buildSummaryItem(
            icon: Icons.check_circle,
            text: 'How to apply these concepts in real-world scenarios',
            theme: theme,
          ),
          _buildSummaryItem(
            icon: Icons.check_circle,
            text: 'Mathematical representations and formulas',
            theme: theme,
          ),
          _buildSummaryItem(
            icon: Icons.check_circle,
            text: 'Practical applications in Zimbabwe',
            theme: theme,
          ),
          const SizedBox(height: 24),
          Text(
            'Key Takeaways:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Understanding these principles is essential for mastering the subject. Practice applying them in different contexts to deepen your understanding.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator(int index, ThemeData theme) {
    final isSelected = index == _currentContentIndex;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isSelected ? 24 : 8,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.secondary
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
  
  Color _getSubjectColor(String? subject) {
    switch (subject?.toLowerCase()) {
      case 'mathematics':
        return const Color(0xFF008751); // Green
      case 'english':
        return const Color(0xFFFFD700); // Yellow
      case 'science':
        return const Color(0xFFCE1126); // Red
      case 'history':
        return const Color(0xFF9C27B0); // Purple
      case 'geography':
        return const Color(0xFF4CAF50); // Different green
      case 'agriculture':
        return const Color(0xFF795548); // Brown
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }
  
  String _getLessonTypeText(ContentType? contentType) {
    switch (contentType) {
      case ContentType.text:
        return 'Reading';
      case ContentType.video:
        return 'Video';
      case ContentType.audio:
        return 'Audio';
      case ContentType.interactive:
        return 'Interactive';
      case ContentType.quiz:
        return 'Quiz';
      case ContentType.mixed:
        return 'Mixed Media';
      default:
        return 'Lesson';
    }
  }
}
