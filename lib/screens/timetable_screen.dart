import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../services/timetable_service.dart';
import '../services/cache_service.dart';

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
  final CacheService _cache = CacheService();
  String _errorMessage = '';
  Timer? _refreshTimer;
  int? _lastPeriodIndex; // Track period to avoid unnecessary rebuilds
  Map<String, ScrollController> _scrollControllers = {};
  Map<String, GlobalKey> _listViewKeys = {};

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // Helper methods for current time detection
  String _getCurrentDay() {
    final now = DateTime.now();
    final weekday = now.weekday;
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return '';
    }
  }

  // Get current period index for smart refresh optimization
  int? _getCurrentPeriodIndex() {
    final currentDay = _getCurrentDay();
    final dayCapitalized = currentDay.isNotEmpty 
        ? currentDay[0].toUpperCase() + currentDay.substring(1) 
        : '';
    final schedule = _timetableData[dayCapitalized] ?? [];
    
    for (int i = 0; i < schedule.length; i++) {
      if (_isCurrentPeriod(currentDay, schedule[i].time)) {
        return i;
      }
    }
    return null;
  }

  bool _isCurrentPeriod(String day, String timeSlot) {
    final now = DateTime.now();
    final currentDay = _getCurrentDay();

    // Check if it's the current day
    if (day.toLowerCase() != currentDay) {
      return false;
    }

    try {
      // Parse time slot (format: "HH:MM AM/PM - HH:MM AM/PM")
      final timeParts = timeSlot.split(' - ');
      if (timeParts.length != 2) return false;

      // Parse start time
      final startTime = _parseTimeString(timeParts[0].trim());
      final endTime = _parseTimeString(timeParts[1].trim());

      if (startTime == null || endTime == null) return false;

      // Create DateTime objects for comparison
      final startDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );
      final endDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        endTime.hour,
        endTime.minute,
      );

      // Check if current time is within the period
      return now.isAfter(startDateTime) && now.isBefore(endDateTime);
    } catch (e) {
      print('Error parsing time: $e');
      return false;
    }
  }

  DateTime? _parseTimeString(String timeStr) {
    try {
      // Handle formats like "9:15 AM", "12:45 PM", etc.
      final regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(timeStr);

      if (match == null) return null;

      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String period = match.group(3)!.toUpperCase();

      // Convert to 24-hour format
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(2025, 1, 1, hour, minute); // Just need hour and minute
    } catch (e) {
      print('Error parsing time string "$timeStr": $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    // Initialize scroll controllers and keys for each day
    for (String day in _days) {
      _scrollControllers[day] = ScrollController();
      _listViewKeys[day] = GlobalKey();
    }

    // Add listener to tab controller
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Tab change completed, check if we need to auto-scroll
        Future.delayed(Duration(milliseconds: 300), () {
          _scrollToCurrentPeriod();
        });
      }
    });

    _loadTimetableData();

    // Set the initial tab to today's day of the week
    String today = _getDayOfWeek();
    int todayIndex = _getDayIndex(today);
    if (todayIndex >= 0 && todayIndex < 6) {
      _tabController.animateTo(todayIndex);
    }

    // Start timer to refresh UI every minute - OPTIMIZED: only rebuild when period changes
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (!mounted) return;
      
      // Calculate current period index
      final currentPeriodIndex = _getCurrentPeriodIndex();
      
      // Only rebuild if period actually changed
      if (currentPeriodIndex != _lastPeriodIndex) {
        _lastPeriodIndex = currentPeriodIndex;
        setState(() {});
        _scrollToCurrentPeriod();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    // Dispose all scroll controllers
    for (ScrollController controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollToCurrentPeriod() {
    if (!mounted) return;

    // Get current day and current tab
    String currentDay = _getCurrentDay();
    int currentTabIndex = _tabController.index;
    String currentTabDay = _days[currentTabIndex];

    // Only auto-scroll if we're on today's tab
    if (currentTabDay.toLowerCase() != currentDay) return;

    // Get scroll controller for current tab
    ScrollController? scrollController = _scrollControllers[currentTabDay];
    if (scrollController == null || !scrollController.hasClients) return;

    // Get schedule for current day
    List<TimeSlot> schedule = _timetableData[currentTabDay] ?? [];
    if (schedule.isEmpty) return;

    // Find current period index
    int currentPeriodIndex = -1;
    for (int i = 0; i < schedule.length; i++) {
      if (_isCurrentPeriod(currentDay, schedule[i].time)) {
        currentPeriodIndex = i;
        break;
      }
    }

    // If current period found, scroll to make it visible
    if (currentPeriodIndex >= 0) {
      // Calculate item position
      double itemHeight = 86.0; // Approximate card height + margin
      double targetPosition = currentPeriodIndex * itemHeight;

      // Get viewport height
      double viewportHeight = scrollController.position.viewportDimension;

      // Calculate position to center the item
      double centerPosition =
          targetPosition - (viewportHeight / 2) + (itemHeight / 2);

      // Ensure position is within bounds
      double maxScroll = scrollController.position.maxScrollExtent;
      double scrollPosition = centerPosition.clamp(0.0, maxScroll);

      // Animate to position
      scrollController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadTimetableData() async {
    // Try to get from cache first
    final cacheKey = 'timetable_${widget.department}_${widget.semester}_$_selectedSection';
    final cached = _cache.get<Map<String, List<TimeSlot>>>(cacheKey);
    
    if (cached != null) {
      setState(() {
        _timetableData = cached;
        _isLoading = false;
        _errorMessage = '';
      });
      
      // Auto-scroll to current period after cache load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentPeriod();
      });
      return;
    }

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

        // Check for the day in lowercase to match database format
        String dayLower = day.toLowerCase();
        print('Checking for day: $day (lowercase: $dayLower)');
        if (timetableData.containsKey(dayLower)) {
          final daySchedule = timetableData[dayLower]!;
          print('Found ${daySchedule.length} periods for $day');

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

            print('Adding period: $timeRange - $subjectName');

            formattedData[day]!.add(
              TimeSlot(timeRange, subjectName, facultyName, room, batch),
            );
          }
        } else {
          print('No data found for $day (lowercase: $dayLower)');
        }

        // Add standard break and lunch periods if not already present
        if (formattedData[day]!.length > 0) {
          _addStandardBreaks(formattedData[day]!);
        }
      }

      print(
        'Final formatted data: ${formattedData.keys.map((k) => '$k: ${formattedData[k]!.length} periods').join(', ')}',
      );

      // Cache the timetable data for 30 minutes
      final cacheKey = 'timetable_${widget.department}_${widget.semester}_$_selectedSection';
      _cache.set(cacheKey, formattedData, CacheService.timetableTTL);

      setState(() {
        _timetableData = formattedData;
        _isLoading = false;
      });

      // Auto-scroll to current period after data is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentPeriod();
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
    // Add standard break and lunch periods based on your college schedule

    bool hasBreak = daySchedule.any(
      (slot) => slot.subject.toLowerCase().contains('break'),
    );
    bool hasLunch = daySchedule.any(
      (slot) => slot.subject.toLowerCase().contains('lunch'),
    );

    if (!hasBreak && daySchedule.length >= 2) {
      // Insert break after 2nd period (10:15 - 10:30)
      daySchedule.insert(
        2,
        TimeSlot('10:15 AM - 10:30 AM', 'Break', '', 'C11'),
      );
    }

    if (!hasLunch && daySchedule.length >= 5) {
      // Insert lunch after 5th period (12:00 - 12:45)
      daySchedule.insert(5, TimeSlot('12:00 PM - 12:45 PM', 'Lunch', '', ''));
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
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            onPressed: _loadTimetableData,
            tooltip: 'Refresh timetable',
          ),
          IconButton(
            icon: Icon(
              Icons.center_focus_strong,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _scrollToCurrentPeriod();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Scrolled to current period'),
                  duration: Duration(milliseconds: 1500),
                ),
              );
            },
            tooltip: 'Center current period',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.group, color: Theme.of(context).primaryColor),
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
            tooltip: 'Select section',
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

    // Get scroll controller for this day
    ScrollController scrollController =
        _scrollControllers[day] ?? ScrollController();

    return ListView.builder(
      key: _listViewKeys[day],
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        return _buildTimeSlotCard(schedule[index], day);
      },
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot, String day) {
    // Determine color based on subject
    Color subjectColor = _getSubjectColor(slot.subject);
    String defaultClassroom = _selectedSection == 'A' ? 'C11' : 'C12';

    // Check if this is the current period - use the passed day parameter
    bool isCurrentPeriod = _isCurrentPeriod(day.toLowerCase(), slot.time);

    return Card(
      elevation: isCurrentPeriod ? 4 : 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPeriod ? Colors.green.shade400 : Colors.grey.shade200,
          width: isCurrentPeriod ? 2 : 1,
        ),
      ),
      color: isCurrentPeriod ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.time,
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          isCurrentPeriod
                              ? Colors.green[700]
                              : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if (isCurrentPeriod) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isCurrentPeriod
                        ? Colors.green.withOpacity(0.3)
                        : subjectColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border:
                    isCurrentPeriod
                        ? Border.all(color: Colors.green.shade400, width: 2)
                        : null,
              ),
              alignment: Alignment.center,
              child: Text(
                _getSubjectInitials(slot.subject),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrentPeriod ? Colors.green.shade700 : subjectColor,
                  
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      
                      color:
                          isCurrentPeriod
                              ? Colors.green.shade700
                              : Colors.black87,
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
                          color:
                              isCurrentPeriod
                                  ? Colors.green[600]
                                  : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            slot.instructor!,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isCurrentPeriod
                                      ? Colors.green[600]
                                      : Colors.grey[600],
                              
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
                        color:
                            isCurrentPeriod
                                ? Colors.green[600]
                                : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        slot.room?.isNotEmpty == true
                            ? slot.room!
                            : defaultClassroom,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isCurrentPeriod
                                  ? Colors.green[600]
                                  : Colors.grey[600],
                          
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
                            color:
                                isCurrentPeriod
                                    ? Colors.green.withOpacity(0.2)
                                    : subjectColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            slot.batch!,
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isCurrentPeriod
                                      ? Colors.green.shade700
                                      : subjectColor,
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
