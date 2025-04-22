import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  final String department;
  final int semester;

  const TimetableScreen({
    super.key,
    required this.department,
    required this.semester,
  });

  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<TimeSlot>> _timetableData = {};
  bool _isLoading = true;
  bool _isValidUser = false;
  String _selectedSection = 'A'; // Default section

  @override
  void initState() {
    super.initState();
    
    // Validate user department and semester
    if (widget.department.contains('Computer Science') && widget.semester == 4) {
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
        TimeSlot('09:00 - 09:50', 'TOC', 'Mrs. Ramyadevi S', 'C11'),
        TimeSlot('09:50 - 10:40', 'ALG', 'Mrs. T.C. Vidhya', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'DBMS', 'Mrs. Mary Angeline', 'C11'),
        TimeSlot('11:45 - 12:35', 'TECHNICAL APTITUDE', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'AIML', 'Mrs. J. Hemapoorani', 'C11'),
        TimeSlot('02:15 - 03:05', 'ESS', 'Mr. Yuvaraj', 'C11'),
      ],
      'Tuesday': [
        TimeSlot('09:00 - 09:50', 'ESS', 'Mr. Yuvaraj', 'C11'),
        TimeSlot('09:50 - 10:40', 'DBMS', 'Mrs. Mary Angeline', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TOC', 'Mrs. Ramyadevi S', 'C11'),
        TimeSlot('11:45 - 12:35', 'IOS', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 03:05', 'AIML/ALG LAB', 'Mrs. J. Hemapoorani/Mrs. T.C. Vidhya', 'Lab'),
      ],
      'Wednesday': [
        TimeSlot('09:00 - 09:50', 'AIML', 'Mrs. J. Hemapoorani', 'C11'),
        TimeSlot('09:50 - 10:40', 'ALG', 'Mrs. T.C. Vidhya', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TOC', 'Mrs. Ramyadevi S', 'C11'),
        TimeSlot('11:45 - 12:35', 'IOS', '', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'DBMS/OS LAB', 'Mrs. Mary Angeline/Mr. Anand Babu R.M.', 'Lab'),
        TimeSlot('02:15 - 03:05', 'DBMS/OS LAB', 'Mrs. Mary Angeline/Mr. Anand Babu R.M.', 'Lab'),
        TimeSlot('03:05 - 03:45', 'AIML', 'Mrs. J. Hemapoorani', 'C11'),
      ],
      'Thursday': [
        TimeSlot('09:00 - 09:50', 'DBMS', 'Mrs. Mary Angeline', 'C11'),
        TimeSlot('09:50 - 10:40', 'IOS', '', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'TOC', 'Mrs. Ramyadevi S', 'C11'),
        TimeSlot('11:45 - 12:35', 'ESS', 'Mr. Yuvaraj', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 03:05', 'OS/DBMS LAB', 'Mr. Anand Babu R.M./Mrs. Mary Angeline', 'Lab'),
      ],
      'Friday': [
        TimeSlot('09:00 - 09:50', 'IOS', '', 'C11'),
        TimeSlot('09:50 - 10:40', 'ALG', 'Mrs. T.C. Vidhya', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'AIML', 'Mrs. J. Hemapoorani', 'C11'),
        TimeSlot('11:45 - 12:35', 'AIML/ALG LAB', 'Mrs. J. Hemapoorani/Mrs. T.C. Vidhya', 'Lab'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'ESS', 'Mr. Yuvaraj', 'C11'),
        TimeSlot('02:15 - 03:05', 'DBMS', 'Mrs. Mary Angeline', 'C11'),
        TimeSlot('03:05 - 03:45', 'ALG', 'Mrs. T.C. Vidhya', 'C11'),
      ],
      'Saturday': [
        TimeSlot('09:00 - 09:50', 'ALG', 'Mrs. T.C. Vidhya', 'C11'),
        TimeSlot('09:50 - 10:40', 'ESS', 'Mr. Yuvaraj', 'C11'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'AIML', 'Mrs. J. Hemapoorani', 'C11'),
        TimeSlot('11:45 - 12:35', 'DBMS', 'Mrs. Mary Angeline', 'C11'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 02:15', 'AIML', 'Mrs. J. Hemapoorani', 'C11'),
        TimeSlot('02:15 - 03:05', 'IOS', '', 'C11'),
        TimeSlot('03:05 - 03:45', 'TOC', 'Mrs. Ramyadevi S', 'C11'),
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
        TimeSlot('01:25 - 02:15', 'TECHNICAL APTITUDE', 'Mrs. G.Christiana Mercy', 'C12'),
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
        TimeSlot('10:55 - 12:35', 'AIML/ALG LAB', 'Mrs. S.Thamilvannan/Mrs. V.Balammal', 'Lab'),
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
        TimeSlot('01:25 - 03:05', 'ALG/AIML LAB', 'Mrs. V.Balammal/Mrs. S.Thamilvannan', 'Lab'),
        TimeSlot('03:05 - 03:45', 'AIML/LIB', 'Mrs. S.Thamilvannan', 'Lab/Library'),
      ],
      'Friday': [
        TimeSlot('09:00 - 09:50', 'AIML', 'Mrs. S.Thamilvannan', 'C12'),
        TimeSlot('09:50 - 10:40', 'IOS', 'Dr. M.Parameswari', 'C12'),
        TimeSlot('10:40 - 10:55', 'Break', '', ''),
        TimeSlot('10:55 - 11:45', 'ALG', 'Mrs. V.Balammal', 'C12'),
        TimeSlot('11:45 - 12:35', 'TOC', 'Mrs. Ramyadevi S', 'C12'),
        TimeSlot('12:35 - 01:25', 'Lunch', '', ''),
        TimeSlot('01:25 - 03:45', 'OS/DBMS LAB', 'Dr. M.Parameswari/Mr. Anand Babu R.M.', 'Lab'),
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Timetable',
            style: TextStyle(
              fontFamily: 'Clash Grotesk',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The detailed timetable is only available for Computer Science Engineering Semester 4 students.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      fontFamily: 'Clash Grotesk',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Timetable',
          style: TextStyle(
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderInfo(),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.symmetric(horizontal: 12),
                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 12),
                  tabs: [
                    Tab(
                      height: 30,
                      text: 'MONDAY',
                    ),
                    Tab(
                      height: 30,
                      text: 'TUESDAY',
                    ),
                    Tab(
                      height: 30,
                      text: 'WEDNESDAY',
                    ),
                    Tab(
                      height: 30,
                      text: 'THURSDAY',
                    ),
                    Tab(
                      height: 30,
                      text: 'FRIDAY',
                    ),
                    Tab(
                      height: 30,
                      text: 'SATURDAY',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sem 4 - Section $_selectedSection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Clash Grotesk',
                      ),
                    ),
                    SizedBox(width: 4),
                    InkWell(
                      onTap: _showSectionSelectionDialog,
                      child: Icon(
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
          SizedBox(height: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Class Room: ${_selectedSection == 'A' ? 'C11' : 'C12'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
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
          SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Clash Grotesk',
                    ),
                    children: [
                      TextSpan(
                        text: 'Class Advisors: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: _selectedSection == 'A' 
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
          SizedBox(height: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'W.E.F: 10.02.2025',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
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
      padding: EdgeInsets.all(16),
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
      margin: EdgeInsets.symmetric(vertical: 6),
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
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFullSubjectName(slot.subject),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Clash Grotesk',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (slot.faculty.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              slot.faculty,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Clash Grotesk',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (slot.room.isNotEmpty && slot.room != defaultClassroom)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              slot.room,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontFamily: 'Clash Grotesk',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  String _getSubjectInitials(String subject) {
    if (subject.contains('/')) {
      // Handle lab subjects with slashes
      List<String> parts = subject.split('/');
      return parts[0].substring(0, min(3, parts[0].length));
    }
    
    // Handle normal subjects
    List<String> words = subject.split(' ');
    if (words.length > 1) {
      // If multiple words, use first letter of each word
      return words.map((word) => word[0]).take(3).join('');
    } else {
      // Use first 3 letters for single words
      return subject.substring(0, min(3, subject.length));
    }
  }

  String _getFullSubjectName(String subject) {
    Map<String, String> subjectNames = {
      'TOC': 'Theory of Computation',
      'ALG': 'Algorithms',
      'DBMS': 'Database Management Systems',
      'AIML': 'Artificial Intelligence and Machine Learning',
      'ESS': 'Environmental Sciences and Sustainability',
      'IOS': 'Introduction to Operating Systems',
      'AIML/ALG LAB': 'AI & ML / Algorithms Lab',
      'DBMS/OS LAB': 'DBMS / OS Lab',
      'OS/DBMS LAB': 'OS / DBMS Lab',
      'TECHNICAL APTITUDE': 'Technical Aptitude',
      'AIML/LIB': 'AI & ML / Library',
      'TOC/SBL': 'Theory of Computation / Self Based Learning',
      'IOS/SBL': 'Introduction to OS / Self Based Learning',
      'ESS/SBL': 'Environmental Sciences / Self Based Learning',
      'DBMS/SBL': 'Database Systems / Self Based Learning',
      'AIML/SBL': 'AI & ML / Self Based Learning',
      'ALG/SBL': 'Algorithms / Self Based Learning',
      'ALG/AIML LAB': 'Algorithms / AI & ML Lab',
    };
    
    return subjectNames[subject] ?? subject;
  }

  Color _getSubjectColor(String subject) {
    Map<String, Color> subjectColors = {
      'TOC': Colors.purple,
      'ALG': Colors.blue,
      'DBMS': Colors.orange,
      'AIML': Colors.green,
      'ESS': Colors.teal,
      'IOS': Colors.red,
      'TECHNICAL APTITUDE': Colors.indigo,
    };
    
    // Handle lab subjects
    if (subject.contains('LAB')) {
      return Colors.deepPurple;
    }
    
    // Handle SBL subjects
    if (subject.contains('SBL')) {
      if (subject.contains('TOC')) return Colors.purple;
      if (subject.contains('ALG')) return Colors.blue;
      if (subject.contains('DBMS')) return Colors.orange;
      if (subject.contains('AIML')) return Colors.green;
      if (subject.contains('ESS')) return Colors.teal;
      if (subject.contains('IOS')) return Colors.red;
      return Colors.deepPurple;
    }
    
    // Extract the main subject for subjects with slashes
    if (subject.contains('/')) {
      String mainSubject = subject.split('/')[0].trim();
      return subjectColors[mainSubject] ?? Colors.grey;
    }
    
    return subjectColors[subject] ?? Colors.grey;
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }

  void _showTodayClasses() {
    String today = _getDayOfWeek();
    
    // Switch to today's tab
    int todayIndex = _getDayIndex(today);
    if (todayIndex >= 0 && todayIndex < 6) {
      _tabController.animateTo(todayIndex);
    }
    
    List<TimeSlot> todaysSlots = _timetableData[today] ?? [];
    
    // Filter out break and lunch slots
    List<TimeSlot> classSlots = todaysSlots.where((slot) {
      return !slot.subject.contains('Break') && !slot.subject.contains('Lunch');
    }).toList();
    
    // Find current and upcoming classes
    TimeSlot? currentClass;
    TimeSlot? nextClass;
    
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    
    for (int i = 0; i < classSlots.length; i++) {
      final slot = classSlots[i];
      final timeRange = slot.time.split(' - ');
      if (timeRange.length != 2) continue;
      
      final startTime = _parseTime(timeRange[0]);
      final endTime = _parseTime(timeRange[1]);
      
      if (startTime == null || endTime == null) continue;
      
      if (currentTimeInMinutes >= startTime && currentTimeInMinutes <= endTime) {
        currentClass = slot;
        if (i < classSlots.length - 1) {
          nextClass = classSlots[i + 1];
        }
        break;
      } else if (currentTimeInMinutes < startTime) {
        // This is an upcoming class
        nextClass = slot;
        break;
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Classes ($today)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Clash Grotesk',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Section $_selectedSection',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Clash Grotesk',
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showSectionSelectionDialog();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size(0, 0),
                                ),
                                child: Text(
                                  'Change Section',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Clash Grotesk',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sharing timetable...')),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Divider(),
              
              // Show current class if any
              if (currentClass != null)
                _buildCurrentClassCard(currentClass),
                
              // Show next class if any
              if (nextClass != null)
                _buildNextClassCard(nextClass),
              
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),
              
              // Header for all classes
              Text(
                'Full Schedule:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Clash Grotesk',
                ),
              ),
              SizedBox(height: 8),
              
              // List of all classes for the day
              Expanded(
                child: classSlots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No classes today',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontFamily: 'Clash Grotesk',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: classSlots.length,
                        itemBuilder: (context, index) {
                          return _buildTodayTimeSlot(classSlots[index], index);
                        },
                      ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Clash Grotesk',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentClassCard(TimeSlot slot) {
    Color subjectColor = _getSubjectColor(slot.subject);
    final timeRange = slot.time.split(' - ');
    final endTime = _parseTime(timeRange[1]);
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final minutesRemaining = endTime != null ? endTime - currentTimeInMinutes : 0;
    String defaultClassroom = _selectedSection == 'A' ? 'C11' : 'C12';
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      color: subjectColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: subjectColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: subjectColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ONGOING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Clash Grotesk',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getFullSubjectName(slot.subject),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Clash Grotesk',
                      color: subjectColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: subjectColor),
                  SizedBox(width: 8),
                  Text(
                    '${slot.time} (${minutesRemaining > 0 ? "$minutesRemaining minutes remaining" : "Ending soon"})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Clash Grotesk',
                    ),
                  ),
                ],
              ),
            ),
            if (slot.faculty.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: subjectColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot.faculty,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Clash Grotesk',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (slot.room.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: subjectColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot.room == defaultClassroom ? 'Regular Classroom' : slot.room,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Clash Grotesk',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildNextClassCard(TimeSlot slot) {
    Color subjectColor = Colors.grey[700]!;
    final timeRange = slot.time.split(' - ');
    final startTime = _parseTime(timeRange[0]);
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final minutesUntilStart = startTime != null ? startTime - currentTimeInMinutes : 0;
    String defaultClassroom = _selectedSection == 'A' ? 'C11' : 'C12';
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Clash Grotesk',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getFullSubjectName(slot.subject),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Clash Grotesk',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '${slot.time} (in ${minutesUntilStart > 0 ? "$minutesUntilStart minutes" : "a few moments"})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Clash Grotesk',
                    ),
                  ),
                ],
              ),
            ),
            if (slot.faculty.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot.faculty,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Clash Grotesk',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (slot.room.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot.room == defaultClassroom ? 'Regular Classroom' : slot.room,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Clash Grotesk',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildTodayTimeSlot(TimeSlot slot, int index) {
    Color subjectColor = _getSubjectColor(slot.subject);
    bool isCurrentClass = _isCurrentClass(slot);
    String defaultClassroom = _selectedSection == 'A' ? 'C11' : 'C12';
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentClass ? subjectColor : Colors.grey.shade200,
          width: isCurrentClass ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isCurrentClass ? subjectColor.withOpacity(0.1) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getFullSubjectName(slot.subject),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Clash Grotesk',
                              color: isCurrentClass ? subjectColor : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentClass)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: subjectColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NOW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Clash Grotesk',
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (slot.faculty.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                slot.faculty,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'Clash Grotesk',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Text(
                              slot.time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                                fontFamily: 'Clash Grotesk',
                              ),
                            ),
                            SizedBox(width: 12),
                            if (slot.room.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                                  SizedBox(width: 4),
                                  Text(
                                    slot.room == defaultClassroom ? 'Regular Classroom' : slot.room,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                      fontFamily: 'Clash Grotesk',
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  String _getDayOfWeek() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    
    switch (dayOfWeek) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }

  bool _isCurrentClass(TimeSlot slot) {
    // Get current time
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Parse the time slot
    final timeRange = slot.time.split(' - ');
    if (timeRange.length != 2) return false;
    
    final startTime = _parseTime(timeRange[0]);
    final endTime = _parseTime(timeRange[1]);
    
    if (startTime == null || endTime == null) return false;
    
    // Current time in minutes since midnight
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    // Check if current time falls within this slot
    return currentTimeInMinutes >= startTime && currentTimeInMinutes <= endTime;
  }
  
  int? _parseTime(String timeStr) {
    // Handle formats like "09:00", "9:50", "01:25", "1:25", "10:55"
    try {
      // Remove any am/pm if present and trim whitespace
      timeStr = timeStr.replaceAll(RegExp(r'[aApP][mM]'), '').trim();
      
      // Split into hour and minute parts
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        // Convert 12-hour format to 24-hour if needed
        // For timetable, we know all morning classes are 9-12
        // and afternoon classes are 1-4, so we convert times like 1:25 to 13:25
        if (hour <= 8 && hour > 0) { // Assuming afternoon classes (12pm-8pm)
          hour += 12;
        }
        
        return hour * 60 + minute;
      }
    } catch (e) {
      print('Error parsing time: $e for input "$timeStr"');
    }
    return null;
  }

  int _getDayIndex(String day) {
    switch (day) {
      case 'Monday': return 0;
      case 'Tuesday': return 1;
      case 'Wednesday': return 2;
      case 'Thursday': return 3;
      case 'Friday': return 4;
      case 'Saturday': return 5;
      default: return 0;
    }
  }

  Widget _buildFloatingActionButton() {
    String today = _getDayOfWeek();
    bool isToday = today != 'Sunday'; // Check if it's a college day
    
    // Find current class if any
    List<TimeSlot> todaysSlots = _timetableData[today] ?? [];
    TimeSlot? currentClass = todaysSlots.firstWhere(
      (slot) => _isCurrentClass(slot),
      orElse: () => TimeSlot('', '', '', ''),
    );
    
    bool hasCurrentClass = currentClass.subject.isNotEmpty;
    
    return FloatingActionButton.extended(
      onPressed: _showTodayClasses,
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
        child: Text(
          hasCurrentClass ? "Now: ${currentClass.subject}" : "Today's Classes",
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Clash Grotesk',
            fontWeight: hasCurrentClass ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      icon: Icon(
        hasCurrentClass ? Icons.now_widgets : Icons.today, 
        size: 16
      ),
      backgroundColor: hasCurrentClass 
          ? _getSubjectColor(currentClass.subject) 
          : Theme.of(context).primaryColor,
      extendedPadding: EdgeInsets.symmetric(horizontal: 12),
    );
  }

  void _showSectionSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Your Section',
            style: TextStyle(
              fontFamily: 'Clash Grotesk',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please select your class section to view the corresponding timetable:',
                  style: TextStyle(
                    fontFamily: 'Clash Grotesk',
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedSection = 'A';
                              _loadTimetableData();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: _selectedSection == 'A' 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey[300],
                          ),
                          child: Text(
                            'Section A',
                            style: TextStyle(
                              fontFamily: 'Clash Grotesk',
                              fontWeight: FontWeight.bold,
                              color: _selectedSection == 'A' ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedSection = 'B';
                              _loadTimetableData();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: _selectedSection == 'B' 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey[300],
                          ),
                          child: Text(
                            'Section B',
                            style: TextStyle(
                              fontFamily: 'Clash Grotesk',
                              fontWeight: FontWeight.bold,
                              color: _selectedSection == 'B' ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TimeSlot {
  final String time;
  final String subject;
  final String faculty;
  final String room;

  TimeSlot(this.time, this.subject, this.faculty, this.room);
}