import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
// Removed duplicate import 'package:intl/intl.dart';

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

  const TimeSlot(this.time, this.subject, [this.instructor, this.room]);
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<TimeSlot>> _timetableData = {};
  bool _isLoading = true;
  bool _isValidUser = false;
  String _selectedSection = 'A'; // Default section
  static const String defaultClassroom = 'C11';

  @override
  void initState() {
    super.initState();

    // Validate user department and semester
    if (widget.department.contains('Computer Science') &&
        widget.semester == 4) {
      _isValidUser = true;
      _tabController = TabController(length: 6, vsync: this);

      // Pre-initialize with default section data to avoid late initialization error
      _loadTimetableData();

      // Show section selection dialog
      Future.delayed(Duration.zero, () {
        _showSectionSelectionDialog();
      });

      // Set the initial tab to today's day of the week
      String today = _getDayOfWeek();
      int todayIndex = _getDayIndex(today);
      if (todayIndex >= 0 && todayIndex < 6) {
        _tabController.animateTo(todayIndex);
      }
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTimetableData() {
    if (_selectedSection == 'A') {
      _loadSectionATimetable();
    } else {
      _loadSectionBTimetable();
    }

    // Set loading to false after data is loaded
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _loadSectionATimetable() {
    _timetableData = {
      'Monday': [
        TimeSlot('09:00 - 09:50', 'TOC', '', 'C11'),
        TimeSlot('09:50 - 10:40', 'ALG', '', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TECHNICAL APTITUDE', '', 'C11'),
        TimeSlot('11:45 - 12:35', 'TECHNICAL APTITUDE', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'AIML', '', 'C11'),
        TimeSlot('02:15 - 03:05', 'DBMS', '', 'C11'),
        TimeSlot('03:05 - 03:45', 'ESS', '', 'C11'),
      ],
      'Tuesday': [
        TimeSlot('09:00 - 09:50', 'ESS', '', 'C11'),
        TimeSlot('09:50 - 10:40', 'DBMS', '', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TOC', '', 'C11'),
        TimeSlot('11:45 - 12:35', 'IOS', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 03:05', 'AIML/ALG LAB', '', 'Lab'),
        TimeSlot('03:05 - 03:45', 'AIML/LIB', '', 'Lab/Library'),
      ],
      'Wednesday': [
        TimeSlot('09:00 - 09:50', 'AIML', '', 'C11'),
        TimeSlot('09:50 - 10:40', 'ALG', '', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TOC', '', 'C11'),
        TimeSlot('11:45 - 12:35', 'IOS', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 03:05', 'DBMS/OS LAB', '', 'Lab'),
      ],
      'Thursday': [
        TimeSlot('09:00 - 09:50', 'DBMS', '', 'C11'),
        TimeSlot('09:50 - 10:40', 'IOS', '', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TOC', '', 'C11'),
        TimeSlot('11:45 - 12:35', 'ESS', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 03:05', 'OS/DBMS LAB', '', 'Lab'),
      ],
      'Friday': [
        TimeSlot('09:00 - 09:50', 'IOS', '', 'C11'),
        TimeSlot('09:50 - 10:40', 'ALG', '', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'AIML/ALG LAB', '', 'Lab'),
        TimeSlot('11:45 - 12:35', 'AIML/ALG LAB', '', 'Lab'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'ESS', '', 'C11'),
        TimeSlot('02:15 - 03:05', 'DBMS', '', 'C11'),
        TimeSlot('03:05 - 03:45', 'ALG', '', 'C11'),
      ],
      'Saturday': [
        TimeSlot('09:00 - 09:50', 'ALG', '', 'C11'),
        TimeSlot('09:50 - 10:40', 'ESS', '', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'AIML', '', 'C11'),
        TimeSlot('11:45 - 12:35', 'DBMS', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'AIML', '', 'C11'),
        TimeSlot('02:15 - 03:05', 'OS', '', 'C11'),
        TimeSlot('03:05 - 03:45', 'TOC', '', 'C11'),
      ],
    };
  }

  void _loadSectionBTimetable() {
    _timetableData = {
      'Monday': [
        TimeSlot('09:00 - 09:50', 'ALG', 'Mrs. V.Balammal', 'C12'),
        TimeSlot('09:50 - 10:40', 'AIML', 'Mrs. S.Thamilvannan', 'C12'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'DBMS', 'Mr. Anand Babu R.M.', 'C12'),
        TimeSlot('11:45 - 12:35', 'ESS', 'Mr. Yuvaraj G', 'C12'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot(
          '01:25 - 02:15',
          'TECHNICAL APTITUDE',
          'Mrs. G.Christiana Mercy',
          'C12',
        ),
        TimeSlot('02:15 - 03:05', 'TOC/SBL', 'Mrs. Ramyadevi S', 'C12'),
      ],
      'Tuesday': [
        TimeSlot('09:00 - 09:50', 'TOC', 'Mrs. Ramyadevi S', 'C12'),
        TimeSlot('09:50 - 10:40', 'DBMS', 'Mr. Anand Babu R.M.', 'C12'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'IOS', 'Dr. M.Parameswari', 'C12'),
        TimeSlot('11:45 - 12:35', 'ESS', 'Mr. Yuvaraj G', 'C12'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 03:05', 'DBMS/OS LAB', 'Mr. Anand Babu R.M.', 'Lab'),
      ],
      'Wednesday': [
        TimeSlot('09:00 - 09:50', 'DBMS', 'Mr. Anand Babu R.M.', 'C12'),
        TimeSlot('09:50 - 10:40', 'AIML', 'Mrs. S.Thamilvannan', 'C12'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot(
          '10:55 - 12:35',
          'AIML/ALG LAB',
          'Mrs. S.Thamilvannan/Mrs. V.Balammal',
          'Lab',
        ),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'IOS/SBL', 'Dr. M.Parameswari', 'C12'),
        TimeSlot('02:15 - 03:05', 'TOC', 'Mrs. Ramyadevi S', 'C12'),
        TimeSlot('03:05 - 03:45', 'ESS/SBL', 'Mr. Yuvaraj G', 'C12'),
      ],
      'Thursday': [
        TimeSlot('09:00 - 09:50', 'ESS', 'Mr. Yuvaraj G', 'C12'),
        TimeSlot('09:50 - 10:40', 'ALG', 'Mrs. V.Balammal', 'C12'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'IOS', 'Dr. M.Parameswari', 'C12'),
        TimeSlot('11:45 - 12:35', 'DBMS/SBL', 'Mr. Anand Babu R.M.', 'C12'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot(
          '01:25 - 03:05',
          'ALG/AIML LAB',
          'Mrs. V.Balammal/Mrs. S.Thamilvannan',
          'Lab',
        ),
        TimeSlot(
          '03:05 - 03:45',
          'AIML/LIB',
          'Mrs. S.Thamilvannan',
          'Lab/Library',
        ),
      ],
      'Friday': [
        TimeSlot('09:00 - 09:50', 'AIML', 'Mrs. S.Thamilvannan', 'C12'),
        TimeSlot('09:50 - 10:40', 'IOS', 'Dr. M.Parameswari', 'C12'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'ALG', 'Mrs. V.Balammal', 'C12'),
        TimeSlot('11:45 - 12:35', 'TOC', 'Mrs. Ramyadevi S', 'C12'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot(
          '01:25 - 03:45',
          'OS/DBMS LAB',
          'Dr. M.Parameswari/Mr. Anand Babu R.M.',
          'Lab',
        ),
      ],
      'Saturday': [
        TimeSlot('09:00 - 09:50', 'IOS', 'Dr. M.Parameswari', 'C12'),
        TimeSlot('09:50 - 10:40', 'ALG', 'Mrs. V.Balammal', 'C12'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TOC', 'Mrs. Ramyadevi S', 'C12'),
        TimeSlot('11:45 - 12:35', 'DBMS', 'Mr. Anand Babu R.M.', 'C12'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'AIML/SBL', 'Mrs. S.Thamilvannan', 'C12'),
        TimeSlot('02:15 - 03:05', 'ESS', 'Mr. Yuvaraj G', 'C12'),
        TimeSlot('03:05 - 03:45', 'ALG/SBL', 'Mrs. V.Balammal', 'C12'),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timetable',
          style: TextStyle(
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (!_isValidUser) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
                    SizedBox(height: 16),
                    Text(
                      'Timetable not available for your department and semester.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Clash Grotesk',
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
                  labelStyle: const TextStyle(
                    fontFamily: 'Clash Grotesk',
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Clash Grotesk',
                  ),
                  tabs: const [
                    Tab(text: 'Monday'),
                    Tab(text: 'Tuesday'),
                    Tab(text: 'Wednesday'),
                    Tab(text: 'Thursday'),
                    Tab(text: 'Friday'),
                    Tab(text: 'Saturday'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDaySchedule('Monday'),
                      _buildDaySchedule('Tuesday'),
                      _buildDaySchedule('Wednesday'),
                      _buildDaySchedule('Thursday'),
                      _buildDaySchedule('Friday'),
                      _buildDaySchedule('Saturday'),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
                  'Computer Science Engineering',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Clash Grotesk',
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
                        fontFamily: 'Clash Grotesk',
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _showSectionSelectionDialog,
                      child: const Icon(
                        Icons.swap_horiz,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Class Room: ${_selectedSection == 'A' ? 'C11' : 'C12'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Class Strength: ${_selectedSection == 'A' ? '60' : '60'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Clash Grotesk',
                    ),
                    children: [
                      const TextSpan(
                        text: 'Class Advisors: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text:
                            _selectedSection == 'A'
                                ? 'Mr. E. Munusamy, Mrs. Ramya Devi'
                                : 'Mrs. V.Balammal, Mr. Anand Babu R.M.',
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'W.E.F: 10.02.2025',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Batch: 2023-2027',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final slots = _timetableData[day] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];

        // Show appropriate break divider for Break and Lunch slots
        if (slot.subject == 'Break' || slot.subject == 'Lunch') {
          return _buildBreakDivider(slot.time);
        }

        return _buildTimeSlotCard(slot);
      },
    );
  }

  Widget _buildBreakDivider(String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 64,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontFamily: 'Clash Grotesk',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                time.contains('12:35') ? 'LUNCH BREAK' : 'BREAK',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Clash Grotesk',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    // Determine color based on subject
    Color subjectColor = _getSubjectColor(slot.subject);
    bool isCurrentClass = _isCurrentClass(slot);
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
                  fontFamily: 'Clash Grotesk',
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
                  fontFamily: 'Clash Grotesk',
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
                      fontFamily: 'Clash Grotesk',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
                          fontFamily: 'Clash Grotesk',
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

  bool _isCurrentClass(TimeSlot slot) {
    // Get current time
    DateTime now = DateTime.now();
    int currentHour = now.hour;
    int currentMinute = now.minute;

    // Parse the time slot
    List<String> timeParts = slot.time.split(' - ');
    List<String> startTimeParts = timeParts[0].split(':');
    int startHour = int.parse(startTimeParts[0]);
    int startMinute = int.parse(startTimeParts[1]);

    List<String> endTimeParts = timeParts[1].split(':');
    int endHour = int.parse(endTimeParts[0]);
    int endMinute = int.parse(endTimeParts[1]);

    // Create DateTime objects for start and end times
    DateTime startTime = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute,
    );
    DateTime endTime = DateTime(
      now.year,
      now.month,
      now.day,
      endHour,
      endMinute,
    );
    DateTime currentTime = DateTime(
      now.year,
      now.month,
      now.day,
      currentHour,
      currentMinute,
    );

    // Check if current time is within the time slot
    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  String _getDayOfWeek() {
    return DateFormat('EEEE').format(DateTime.now());
  }

  int _getDayIndex(String day) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days.indexOf(day);
  }

  void _showSectionSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Section'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Section A'),
                  onTap: () {
                    setState(() {
                      _selectedSection = 'A';
                      _loadTimetableData();
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Section B'),
                  onTap: () {
                    setState(() {
                      _selectedSection = 'B';
                      _loadTimetableData();
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Add your onPressed logic here
      },
      child: const Icon(Icons.add), // Example icon
    );
  }
}
