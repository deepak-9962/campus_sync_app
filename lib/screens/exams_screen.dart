import 'package:flutter/material.dart';

class ExamSchedule {
  final String date;
  final String subjectCode;
  final String subjectName;

  ExamSchedule({
    required this.date,
    required this.subjectCode,
    required this.subjectName,
  });
}

class ExamsScreen extends StatefulWidget {
  final String department;
  final int semester;

  const ExamsScreen({
    super.key,
    required this.department,
    required this.semester,
  });

  @override
  _ExamsScreenState createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ExamSchedule> examSchedules = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    
    // Initialize exam schedules based on department and semester
    _loadExamSchedule();
  }

  void _loadExamSchedule() {
    // Check if it's Computer Science Engineering, 4th semester
    if (widget.department.contains('Computer Science') && widget.semester == 4) {
      examSchedules = [
        ExamSchedule(
          date: "24/03/2025",
          subjectCode: "CS3492",
          subjectName: "Database Management System",
        ),
        ExamSchedule(
          date: "25/03/2025",
          subjectCode: "CS3491",
          subjectName: "Artificial Intelligence and Machine Learning",
        ),
        ExamSchedule(
          date: "26/03/2025",
          subjectCode: "CS3452",
          subjectName: "Theory of Computation",
        ),
        ExamSchedule(
          date: "26/03/2025",
          subjectCode: "CS3401",
          subjectName: "Algorithm",
        ),
        ExamSchedule(
          date: "28/03/2025",
          subjectCode: "CS3451",
          subjectName: "Introduction to Operating System",
        ),
        ExamSchedule(
          date: "29/03/2025",
          subjectCode: "GE3451",
          subjectName: "Environment Science And Sustainability",
        ),
      ];
    } else {
      // For other departments/semesters, show a placeholder message
      // We'll handle this in the build method
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Exam Schedule',
          style: TextStyle(
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.department,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Clash Grotesk',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Semester ${widget.semester}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Clash Grotesk',
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.7),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'March 2025 Exam Schedule',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                fontFamily: 'Clash Grotesk',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Exam schedule table
                  if (examSchedules.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              color: Colors.white.withOpacity(0.5),
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No exam schedule available for ${widget.department}, Semester ${widget.semester}.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.7),
                                fontFamily: 'Clash Grotesk',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        children: [
                          // Table header
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Clash Grotesk',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    'Subject',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Clash Grotesk',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Table rows
                          ...examSchedules.map((exam) {
                            // Check if date is today (for highlighting)
                            bool isToday = false; // Implement actual logic if needed
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isToday 
                                    ? Colors.blue.withOpacity(0.2) 
                                    : Colors.white.withOpacity(0.05),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Row(
                                  children: [
                                    // Date
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        exam.date,
                                        style: TextStyle(
                                          color: isToday 
                                              ? Colors.white 
                                              : Colors.white.withOpacity(0.8),
                                          fontFamily: 'Clash Grotesk',
                                          fontWeight: isToday 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    
                                    // Subject
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '[${exam.subjectCode}] ${exam.subjectName}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Clash Grotesk',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          
                          // Final rounded corner
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ),
                          
                          // Note
                          SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.withOpacity(0.7),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'All exams start at 10:00 AM. Please arrive at the examination hall 30 minutes before the scheduled time.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Clash Grotesk',
                                    ),
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
          ),
        ),
      ),
    );
  }
} 