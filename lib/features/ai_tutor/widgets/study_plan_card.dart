import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/services/ai_tutor_service.dart';
import '../../common/widgets/glassmorphic_widgets.dart';

class StudyPlanCard extends StatefulWidget {
  final TutoringMessage message;
  final Function(String sessionId) onSessionCompleted;
  
  const StudyPlanCard({
    Key? key,
    required this.message,
    required this.onSessionCompleted,
  }) : super(key: key);

  @override
  State<StudyPlanCard> createState() => _StudyPlanCardState();
}

class _StudyPlanCardState extends State<StudyPlanCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Mock study plan data - in a real app, this would be parsed from the message
  late StudyPlan _studyPlan;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize with mock data
    _initMockStudyPlan();
    
    // Set selected day to today
    _selectedDay = DateTime.now();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _initMockStudyPlan() {
    // Create mock study sessions
    final now = DateTime.now();
    final startDate = now;
    final endDate = now.add(const Duration(days: 14));
    
    final sessions = <StudySession>[];
    
    // Generate sessions for two weeks
    for (int day = 0; day < 14; day++) {
      final date = startDate.add(Duration(days: day));
      
      // Skip weekends for simplicity
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }
      
      // Create 2-3 sessions per day
      final sessionsPerDay = 2 + (day % 2);
      
      for (int session = 0; session < sessionsPerDay; session++) {
        // Alternate subjects
        String subject;
        String title;
        
        switch ((day + session) % 5) {
          case 0:
            subject = 'mathematics';
            title = 'Mathematics - Fractions';
            break;
          case 1:
            subject = 'english';
            title = 'English - Grammar';
            break;
          case 2:
            subject = 'science';
            title = 'Science - Ecosystems';
            break;
          case 3:
            subject = 'history';
            title = 'History - Great Zimbabwe';
            break;
          case 4:
            subject = 'geography';
            title = 'Geography - Climate';
            break;
          default:
            subject = 'mathematics';
            title = 'Mathematics - Review';
        }
        
        // Create session
        sessions.add(StudySession(
          id: 'session_${day}_${session}',
          scheduledDate: date,
          startTime: TimeOfDay(hour: 16 + session, minute: 0),
          endTime: TimeOfDay(hour: 17 + session, minute: 0),
          subject: subject,
          title: title,
          description: 'Focus on key concepts and practice problems',
          isCompleted: date.isBefore(now) && session == 0, // Mark some past sessions as completed
        ));
      }
    }
    
    // Create mock study plan
    _studyPlan = StudyPlan(
      id: 'plan_1',
      userId: 'user_1',
      createdAt: now.subtract(const Duration(days: 1)),
      startDate: startDate,
      endDate: endDate,
      title: 'Two-Week Study Plan for End of Term Exams',
      description: 'This personalized study plan will help you prepare for your upcoming exams. It focuses on key subjects with daily structured sessions.',
      sessions: sessions,
      subjectDistribution: {
        'mathematics': 8,
        'english': 6,
        'science': 6,
        'history': 4,
        'geography': 4,
      },
      isActive: true,
    );
  }
  
  void _toggleSessionCompletion(String sessionId) {
    setState(() {
      final sessionIndex = _studyPlan.sessions.indexWhere((s) => s.id == sessionId);
      
      if (sessionIndex != -1) {
        final session = _studyPlan.sessions[sessionIndex];
        
        // Create updated session
        final updatedSession = StudySession(
          id: session.id,
          scheduledDate: session.scheduledDate,
          startTime: session.startTime,
          endTime: session.endTime,
          subject: session.subject,
          lessonId: session.lessonId,
          quizId: session.quizId,
          title: session.title,
          description: session.description,
          isCompleted: !session.isCompleted,
        );
        
        // Update sessions list
        final updatedSessions = List<StudySession>.from(_studyPlan.sessions);
        updatedSessions[sessionIndex] = updatedSession;
        
        // Update study plan
        _studyPlan = StudyPlan(
          id: _studyPlan.id,
          userId: _studyPlan.userId,
          createdAt: _studyPlan.createdAt,
          startDate: _studyPlan.startDate,
          endDate: _studyPlan.endDate,
          title: _studyPlan.title,
          description: _studyPlan.description,
          sessions: updatedSessions,
          subjectDistribution: _studyPlan.subjectDistribution,
          isActive: _studyPlan.isActive,
        );
        
        // Call the callback
        widget.onSessionCompleted(sessionId);
      }
    });
  }
  
  void _toggleCalendarView() {
    setState(() {
      _showCalendarView = !_showCalendarView;
    });
    
    if (_showCalendarView) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  double _calculateCompletionPercentage() {
    final totalSessions = _studyPlan.sessions.length;
    final completedSessions = _studyPlan.sessions.where((s) => s.isCompleted).length;
    
    return totalSessions > 0 ? completedSessions / totalSessions : 0.0;
  }
  
  List<StudySession> _getSessionsForDay(DateTime day) {
    return _studyPlan.sessions.where((session) {
      return session.scheduledDate.year == day.year &&
             session.scheduledDate.month == day.month &&
             session.scheduledDate.day == day.day;
    }).toList();
  }
  
  String _getTimeRangeString(TimeOfDay start, TimeOfDay end) {
    final startHour = start.hour <= 12 ? start.hour : start.hour - 12;
    final endHour = end.hour <= 12 ? end.hour : end.hour - 12;
    
    final startPeriod = start.hour < 12 ? 'AM' : 'PM';
    final endPeriod = end.hour < 12 ? 'AM' : 'PM';
    
    final startMinute = start.minute.toString().padLeft(2, '0');
    final endMinute = end.minute.toString().padLeft(2, '0');
    
    return '$startHour:$startMinute $startPeriod - $endHour:$endMinute $endPeriod';
  }
  
  Map<String, double> _calculateSubjectProgress() {
    final subjectProgress = <String, double>{};
    final subjectTotals = <String, int>{};
    final subjectCompleted = <String, int>{};
    
    // Initialize counters
    for (final subject in _studyPlan.subjectDistribution.keys) {
      subjectTotals[subject] = 0;
      subjectCompleted[subject] = 0;
    }
    
    // Count sessions by subject
    for (final session in _studyPlan.sessions) {
      if (subjectTotals.containsKey(session.subject)) {
        subjectTotals[session.subject] = (subjectTotals[session.subject] ?? 0) + 1;
        
        if (session.isCompleted) {
          subjectCompleted[session.subject] = (subjectCompleted[session.subject] ?? 0) + 1;
        }
      }
    }
    
    // Calculate progress percentages
    subjectTotals.forEach((subject, total) {
      final completed = subjectCompleted[subject] ?? 0;
      subjectProgress[subject] = total > 0 ? completed / total : 0.0;
    });
    
    return subjectProgress;
  }
  
  String _getSubjectName(String subject) {
    switch (subject) {
      case 'mathematics':
        return 'Mathematics';
      case 'english':
        return 'English';
      case 'science':
        return 'Science';
      case 'history':
        return 'History';
      case 'geography':
        return 'Geography';
      case 'agriculture':
        return 'Agriculture';
      default:
        return subject.substring(0, 1).toUpperCase() + subject.substring(1);
    }
  }
  
  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'mathematics':
        return Colors.blue;
      case 'english':
        return Colors.green;
      case 'science':
        return Colors.purple;
      case 'history':
        return Colors.orange;
      case 'geography':
        return Colors.teal;
      case 'agriculture':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
  
  String _getMotivationalMessage() {
    final completionPercentage = _calculateCompletionPercentage();
    
    if (completionPercentage >= 0.8) {
      return 'Excellent progress! You\'re almost there!';
    } else if (completionPercentage >= 0.5) {
      return 'Great job! Keep up the good work!';
    } else if (completionPercentage >= 0.3) {
      return 'You\'re making good progress. Keep going!';
    } else if (completionPercentage > 0) {
      return 'You\'ve started your journey. Keep building momentum!';
    } else {
      return 'Ready to begin your study plan? Let\'s get started!';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GlassmorphicContainer(
      width: double.infinity,
      borderRadius: 16,
      blur: 10,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Study plan header
          _buildStudyPlanHeader(theme),
          
          // Progress overview
          _buildProgressOverview(theme),
          
          // Subject distribution
          _buildSubjectDistribution(theme),
          
          // Calendar toggle button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AnimatedGlassmorphicButton(
              onPressed: _toggleCalendarView,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showCalendarView ? Icons.list : Icons.calendar_month,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showCalendarView ? 'Show List View' : 'Show Calendar View',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Calendar or list view
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showCalendarView
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildSessionsList(theme),
            secondChild: _buildCalendarView(theme),
          ),
          
          // Motivational message
          _buildMotivationalSection(theme),
        ],
      ),
    );
  }
  
  Widget _buildStudyPlanHeader(ThemeData theme) {
    final dateFormat = DateFormat('MMM d');
    final dateRange = '${dateFormat.format(_studyPlan.startDate)} - ${dateFormat.format(_studyPlan.endDate)}';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _studyPlan.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateRange,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _studyPlan.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressOverview(ThemeData theme) {
    final completionPercentage = _calculateCompletionPercentage();
    final completedSessions = _studyPlan.sessions.where((s) => s.isCompleted).length;
    final totalSessions = _studyPlan.sessions.length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          // Circular progress indicator
          CircularPercentIndicator(
            radius: 40,
            lineWidth: 8,
            percent: completionPercentage,
            center: Text(
              '${(completionPercentage * 100).toInt()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            progressColor: theme.colorScheme.secondary,
            backgroundColor: Colors.white.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1000,
          ),
          const SizedBox(width: 16),
          
          // Progress stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedSessions of $totalSessions sessions completed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                LinearPercentIndicator(
                  percent: completionPercentage,
                  lineHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  progressColor: theme.colorScheme.secondary,
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 1000,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubjectDistribution(ThemeData theme) {
    final subjectProgress = _calculateSubjectProgress();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Subject progress bars
          ...subjectProgress.entries.map((entry) {
            final subject = entry.key;
            final progress = entry.value;
            final subjectName = _getSubjectName(subject);
            final subjectColor = _getSubjectColor(subject);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: subjectColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subjectName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearPercentIndicator(
                    percent: progress,
                    lineHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    progressColor: subjectColor,
                    barRadius: const Radius.circular(3),
                    padding: EdgeInsets.zero,
                    animation: true,
                    animationDuration: 1000,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildSessionsList(ThemeData theme) {
    // Get today's sessions
    final todaySessions = _getSessionsForDay(DateTime.now());
    
    // Get upcoming sessions (excluding today)
    final upcomingSessions = _studyPlan.sessions
        .where((session) => session.scheduledDate.isAfter(DateTime.now()))
        .where((session) => !_isSameDay(session.scheduledDate, DateTime.now()))
        .take(5)
        .toList();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's sessions
          Text(
            'Today\'s Sessions',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (todaySessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No sessions scheduled for today.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...todaySessions.map((session) => _buildSessionItem(session, theme)).toList(),
          
          const SizedBox(height: 16),
          
          // Upcoming sessions
          Text(
            'Upcoming Sessions',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (upcomingSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No upcoming sessions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...upcomingSessions.map((session) => _buildSessionItem(session, theme)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildCalendarView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar
          GlassmorphicContainer(
            width: double.infinity,
            height: 320,
            borderRadius: 12,
            blur: 5,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            child: TableCalendar(
              firstDay: _studyPlan.startDate,
              lastDay: _studyPlan.endDate,
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return _isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return _getSessionsForDay(day);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white70),
                holidayTextStyle: const TextStyle(color: Colors.white70),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  color: Colors.white,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white70),
                weekendStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Selected day sessions
          if (_selectedDay != null) ...[
            Text(
              'Sessions for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ..._getSessionsForDay(_selectedDay!).map((session) => 
              _buildSessionItem(session, theme)
            ).toList(),
            
            if (_getSessionsForDay(_selectedDay!).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No sessions scheduled for this day.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSessionItem(StudySession session, ThemeData theme) {
    final subjectColor = _getSubjectColor(session.subject);
    final subjectName = _getSubjectName(session.subject);
    final timeRange = _getTimeRangeString(session.startTime, session.endTime);
    final isToday = _isSameDay(session.scheduledDate, DateTime.now());
    final isPast = session.scheduledDate.isBefore(DateTime.now());
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 80,
        borderRadius: 12,
        blur: 5,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            subjectColor.withOpacity(0.1),
            subjectColor.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            subjectColor.withOpacity(0.2),
            subjectColor.withOpacity(0.1),
          ],
        ),
        child: Row(
          children: [
            // Subject color indicator
            Container(
              width: 8,
              height: double.infinity,
              color: subjectColor,
            ),
            
            // Session details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          subjectName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.secondary.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Today',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeRange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        if (!isToday && !isPast)
                          Text(
                            DateFormat('MMM d').format(session.scheduledDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Completion checkbox
            Padding(
              padding: const EdgeInsets.all(12),
              child: BouncingWidget(
                onTap: () => _toggleSessionCompletion(session.id),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: session.isCompleted
                        ? subjectColor
                        : Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: session.isCompleted
                          ? subjectColor
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: session.isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMotivationalSection(ThemeData theme) {
    final message = _getMotivationalMessage();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.emoji_emotions,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
