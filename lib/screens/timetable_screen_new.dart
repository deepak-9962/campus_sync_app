import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../services/timetable_service.dart';

class TimetableScreen extends StatefulWidget {
  final String department;
  final int semester;

  const TimetableScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class TimeSlot {
  final String time;
  final String subject;
  final String? instructor;
  final String? room;
  final String? batch;

  const TimeSlot(
    this.time,
    this.subject, [
    this.instructor,
    this.room,
    this.batch,
  ]);
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<TimeSlot>> _timetableData = {};
  bool _isLoading = true;
  String _selectedSection = 'A';
  final TimetableService _timetableService = TimetableService();
  String _errorMessage = '';

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadTimetableData();

    // Set the initial tab to today's day of the week
    String today = _getDayOfWeek();
    int todayIndex = _getDayIndex(today);
    if (todayIndex >= 0 && todayIndex < 6) {
      _tabController.animateTo(todayIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTimetableData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print(
        'Loading timetable for ${widget.department}, semester ${widget.semester}, section $_selectedSection',
      );

      final timetableData = await _timetableService.getTimetable(
        department: widget.department,
        semester: widget.semester,
        section: _selectedSection,
      );

      print('Received timetable data: $timetableData');

      Map<String, List<TimeSlot>> formattedData = {};

      for (String day in _days) {
        formattedData[day] = [];

        if (timetableData.containsKey(day)) {
          final daySchedule = timetableData[day]!;

          // Sort by period number
          daySchedule.sort(
            (a, b) => a['period_number'].compareTo(b['period_number']),
          );

          for (var period in daySchedule) {
            final startTime = period['start_time'] ?? '';
            final endTime = period['end_time'] ?? '';
            final timeRange = _timetableService.getTimeRange(
              startTime,
              endTime,
            );

            final subjectName =
                period['subjects']?['subject_name'] ??
                period['subject_code'] ??
                'Unknown';
            final facultyName = period['faculty_name'] ?? '';
            final room = period['room'] ?? '';
            final batch = period['batch'] ?? '';

            formattedData[day]!.add(
              TimeSlot(timeRange, subjectName, facultyName, room, batch),
            );
          }
        }

        // Add standard break and lunch periods if not already present
        if (formattedData[day]!.length > 0) {
          _addStandardBreaks(formattedData[day]!);
        }
      }

      setState(() {
        _timetableData = formattedData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading timetable: $e');
      setState(() {
        _errorMessage = 'Error loading timetable: $e';
        _isLoading = false;
      });
    }
  }

  void _addStandardBreaks(List<TimeSlot> daySchedule) {
    // This is a simplified version - you might want to make this more sophisticated
    // based on the actual period timings in your database

    bool hasBreak = daySchedule.any(
      (slot) => slot.subject.toLowerCase().contains('break'),
    );
    bool hasLunch = daySchedule.any(
      (slot) => slot.subject.toLowerCase().contains('lunch'),
    );

    if (!hasBreak && daySchedule.length >= 2) {
      daySchedule.insert(2, TimeSlot('10:40 - 10:55', 'Break', '', ''));
    }

    if (!hasLunch && daySchedule.length >= 5) {
      daySchedule.insert(5, TimeSlot('12:35 - 01:25', 'Lunch', '', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timetable',
          style: TextStyle(
            
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadTimetableData),
          PopupMenuButton<String>(
            icon: Icon(Icons.group),
            onSelected: (String section) {
              setState(() {
                _selectedSection = section;
              });
              _loadTimetableData();
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'A', child: Text('Section A')),
                  PopupMenuItem<String>(value: 'B', child: Text('Section B')),
                ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (_errorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[600]),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[600],
                        
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTimetableData,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (_timetableData.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 48, color: Colors.grey[600]),
                    SizedBox(height: 16),
                    Text(
                      'No timetable available for ${widget.department}, Semester ${widget.semester}, Section $_selectedSection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Column(
              children: [
                _buildHeaderInfo(),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Theme.of(context).primaryColor,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    
                  ),
                  tabs: _days.map((day) => Tab(text: day)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children:
                        _days.map((day) => _buildDaySchedule(day)).toList(),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.department,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sem ${widget.semester} - Section $_selectedSection',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final schedule = _timetableData[day] ?? [];

    if (schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.free_breakfast, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No classes scheduled for $day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        return _buildTimeSlotCard(schedule[index]);
      },
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    // Determine color based on subject
    Color subjectColor = _getSubjectColor(slot.subject);
    String defaultClassroom = _selectedSection == 'A' ? 'C11' : 'C12';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              child: Text(
                slot.time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _getSubjectInitials(slot.subject),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: subjectColor,
                  
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.subject,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (slot.instructor?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            slot.instructor!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        slot.room?.isNotEmpty == true
                            ? slot.room!
                            : defaultClassroom,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          
                        ),
                      ),
                      if (slot.batch?.isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: subjectColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            slot.batch!,
                            style: TextStyle(
                              fontSize: 10,
                              color: subjectColor,
                              fontWeight: FontWeight.w500,
                              
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubjectInitials(String subject) {
    List<String> parts = subject.split(' ');
    if (parts.length == 1) {
      return subject.substring(0, 1).toUpperCase();
    } else {
      String firstLetters =
          parts.map((part) => part.substring(0, 1).toUpperCase()).join();
      return firstLetters;
    }
  }

  Color _getSubjectColor(String subject) {
    int hash = subject.hashCode;
    final random = Random(hash);
    return Color.fromRGBO(
      random.nextInt(200) + 50,
      random.nextInt(200) + 50,
      random.nextInt(200) + 50,
      1,
    );
  }

  String _getDayOfWeek() {
    final now = DateTime.now();
    return DateFormat('EEEE').format(now);
  }

  int _getDayIndex(String dayName) {
    switch (dayName) {
      case 'Monday':
        return 0;
      case 'Tuesday':
        return 1;
      case 'Wednesday':
        return 2;
      case 'Thursday':
        return 3;
      case 'Friday':
        return 4;
      case 'Saturday':
        return 5;
      default:
        return -1;
    }
  }
}
