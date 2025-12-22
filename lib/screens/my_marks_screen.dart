import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/marks_service.dart';
import '../services/attendance_service.dart';

class MyMarksScreen extends StatefulWidget {
  const MyMarksScreen({super.key});

  @override
  State<MyMarksScreen> createState() => _MyMarksScreenState();
}

class _MyMarksScreenState extends State<MyMarksScreen>
    with TickerProviderStateMixin {
  final MarksService _marksService = MarksService();
  final AttendanceService _attendanceService = AttendanceService();
  List<Map<String, dynamic>> _studentMarks = [];
  Map<String, dynamic> _marksSummary = {};
  bool _isLoading = true;
  String? _currentUserEmail;
  String? _registrationNo;
  String _message = '';

  late AnimationController _animationController;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadUserMarks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMarks() async {
    setState(() => _isLoading = true);
    _refreshController.forward();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.email != null) {
        _currentUserEmail = user!.email;
        _registrationNo = _attendanceService.extractRegistrationFromEmail(
          _currentUserEmail!,
        );

        if (_registrationNo != null) {
          final marks = await _marksService.getStudentMarks(_registrationNo!);
          final summary = await _marksService.getStudentPerformanceSummary(
            _registrationNo!,
          );

          setState(() {
            _studentMarks = marks;
            _marksSummary = summary;
            _isLoading = false;
            _message = marks.isEmpty ? 'No exam results found' : '';
          });

          _animationController.forward();
        } else {
          setState(() {
            _isLoading = false;
            _message = 'Could not extract registration number from email';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _message = 'Please log in to view your marks';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _message = 'Error loading marks: $error';
      });
    } finally {
      _refreshController.reverse();
    }
  }

  Widget _buildGradientBackground({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surface,
                  colorScheme.surface,
                  colorScheme.surface,
                ]
              : [
                  colorScheme.primary.withOpacity(0.05),
                  colorScheme.secondary.withOpacity(0.05),
                  colorScheme.tertiary.withOpacity(0.05),
                ],
        ),
      ),
      child: child,
    );
  }

  Widget _buildAnimatedCard({required Widget child, required int index}) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.8),
            ((index * 0.1) + 0.4).clamp(0.2, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
      child: FadeTransition(opacity: _animationController, child: child),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required int index,
  }) {
    return _buildAnimatedCard(
      index: index,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> mark, int index) {
    final subject = mark['subject']?.toString() ?? 'Unknown';
    final markValue = mark['mark'];
    final outOf = mark['out_of'] ?? 100;

    final isAbsent = markValue == -1;
    final percentage = isAbsent ? 0.0 : ((markValue / outOf) * 100);
    final isPassed = !isAbsent && markValue >= 50;

    Color cardColor;
    String status;
    IconData statusIcon;

    if (isAbsent) {
      cardColor = Colors.grey.shade600;
      status = 'Absent';
      statusIcon = Icons.cancel_outlined;
    } else if (isPassed) {
      cardColor = Colors.green.shade600;
      status = 'Passed';
      statusIcon = Icons.check_circle_outline;
    } else {
      cardColor = Colors.red.shade600;
      status = 'Failed';
      statusIcon = Icons.error_outline;
    }

    return _buildAnimatedCard(
      index: index + 2,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Subject Grade Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getGrade(markValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Subject Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Database Management Systems',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: cardColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: cardColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mark Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isAbsent ? 'AB' : '$markValue',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                  if (!isAbsent) ...[
                    Text(
                      '/ $outOf',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGrade(int? mark) {
    if (mark == null || mark == -1) return 'AB';
    if (mark >= 90) return 'A+';
    if (mark >= 80) return 'A';
    if (mark >= 70) return 'B+';
    if (mark >= 60) return 'B';
    if (mark >= 50) return 'C+';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Exam Results',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildGradientBackground(
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotationTransition(
                        turns: _refreshController,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                spreadRadius: 0,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.autorenew,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading your results...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                : _message.isNotEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(60),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _registrationNo == null
                                ? Icons.person_off_outlined
                                : Icons.assignment_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _registrationNo == null
                              ? 'Registration Not Found'
                              : 'No Results Available',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _message,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_registrationNo != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Registration: $_registrationNo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                : SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Header Card
                      _buildAnimatedCard(
                        index: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Student Dashboard',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'Registration: $_registrationNo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Statistics Summary (Horizontal)
                      if (_marksSummary.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildAnimatedCard(
                          index: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    'Total Exams',
                                    '${_marksSummary['totalExams'] ?? 0}',
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Theme.of(context).dividerColor,
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    'Average',
                                    '${(_marksSummary['averagePercentage'] ?? 0.0).toStringAsFixed(1)}%',
                                    Colors.green.shade600,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Theme.of(context).dividerColor,
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    'Highest',
                                    '${_marksSummary['highestMark'] ?? 0}',
                                    Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Marks List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _studentMarks.length,
                          itemBuilder: (context, index) {
                            return _buildSubjectCard(
                              _studentMarks[index],
                              index,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadUserMarks,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: RotationTransition(
          turns: _refreshController,
          child: const Icon(Icons.refresh),
        ),
        label: const Text(
          'Refresh',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
