import 'package:flutter/material.dart';
import '../services/student_data_service.dart';
import '../services/attendance_service.dart';
import '../services/user_session_service.dart';
import '../utils/debouncer.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // added for period lock
import '../widgets/edit_attendance_button.dart'; // added for edit attendance
import 'edit_period_attendance_screen.dart';
import 'edit_daily_attendance_screen.dart';

class StaffAttendanceScreen extends StatefulWidget {
  final String department;
  final int semester;
  final String attendanceType; // 'day' or 'period'

  const StaffAttendanceScreen({
    Key? key,
    required this.department,
    required this.semester,
    this.attendanceType = 'period', // Default to period attendance
  }) : super(key: key);

  @override
  _StaffAttendanceScreenState createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  String? selectedSection;
  String? selectedSubject;
  int? selectedPeriod;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> schedule = [];
  Map<String, bool> attendance = {};
  String _sortBy = 'registration_no'; // registration_no, student_name
  bool _sortAscending = true;
  String _userRole = 'staff'; // For edit attendance permission

  // Add local mode that can be toggled in-screen
  late String _attendanceMode; // 'day' or 'period'

  // Attendance status tracking
  bool _attendanceAlreadyTaken = false;
  int _existingAttendanceCount = 0;
  int _existingPresentCount = 0;

  final List<String> sections = ['A', 'B'];
  final List<int> periods = [1, 2, 3, 4, 5, 6];

  // Helper method to safely call setState
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  final StudentDataService _studentDataService = StudentDataService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _attendanceMode =
        widget.attendanceType; // initialize from initial route param
    // Auto-select Section A by default
    selectedSection = 'A';
    // Auto-select Period 1 for period attendance mode
    if (_attendanceMode == 'period') {
      selectedPeriod = 1;
    }
    _setupDatabase();
    _loadUserRole(); // Load user role for edit permission
  }

  Future<void> _loadUserRole() async {
    try {
      // Use cached UserSessionService instead of direct Supabase query
      final userSession = UserSessionService();
      final info = await userSession.getUserInfo();
      if (mounted) {
        setState(() {
          _userRole = (info['role'] ?? 'staff').toString().toLowerCase();
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  Future<void> _setupDatabase() async {
    // Setup students table and data
    await _studentDataService.setupStudentsTable();
    await _loadSubjects();
    await _loadSchedule();
    // Load students since we auto-select Section A
    await _loadStudents();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjectsList = await _attendanceService.getSubjects(
        department: widget.department,
        semester: widget.semester,
      );
      _safeSetState(() {
        subjects = subjectsList;
      });
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final dayOfWeek = DateFormat('EEEE').format(selectedDate).toLowerCase();
      final scheduleList = await _attendanceService.getClassSchedule(
        department: widget.department,
        semester: widget.semester,
        dayOfWeek: dayOfWeek,
      );
      _safeSetState(() {
        schedule = scheduleList;
      });
    } catch (e) {
      print('Error loading schedule: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (selectedSection == null) return;

    _safeSetState(() {
      isLoading = true;
    });

    try {
      print(
        'Loading students for department: ${widget.department}, semester: ${widget.semester}, section: $selectedSection',
      );

      // Use the student data service to get students
      final studentsList = await _studentDataService.getStudentsBySection(
        department: widget.department,
        semester: widget.semester,
        section: selectedSection!,
      );

      print('Loaded ${studentsList.length} students');

      // Load existing attendance data for the selected date
      Map<String, bool> existingAttendance = {};
      String? resolvedSubjectCode;

      try {
        if (_attendanceMode == 'period' && selectedPeriod != null) {
          // Automatically resolve subject from period and schedule
          final dayOfWeek =
              DateFormat('EEEE').format(selectedDate).toLowerCase();
          final periodClassInfo = await _attendanceService.getPeriodClassInfo(
            department: widget.department,
            semester: widget.semester,
            section: selectedSection!,
            date: selectedDate,
            periodNumber: selectedPeriod!,
          );

          if (periodClassInfo != null) {
            resolvedSubjectCode = periodClassInfo['subject_code'];
            print(
              'Auto-resolved subject: $resolvedSubjectCode for period $selectedPeriod',
            );
          } else {
            print('No subject found for period $selectedPeriod on $dayOfWeek');
          }
        }

        existingAttendance = await _attendanceService.getExistingAttendanceMap(
          department: widget.department,
          semester: widget.semester,
          section: selectedSection!,
          date: selectedDate,
          mode: _attendanceMode == 'day' ? 'daily' : 'period',
          subjectCode:
              _attendanceMode == 'day'
                  ? null
                  : resolvedSubjectCode ?? selectedSubject,
          periodNumber: _attendanceMode == 'day' ? null : selectedPeriod,
        );
        print(
          'Loaded existing attendance for ${existingAttendance.length} students',
        );
      } catch (e) {
        print('Error loading existing attendance: $e');
        // Continue with empty map if loading fails
      }

      // Single setState call to update all state at once
      _safeSetState(() {
        students = studentsList;
        selectedSubject = resolvedSubjectCode ?? selectedSubject;
        // Initialize attendance map with existing data or default to false (absent)
        attendance = {
          for (var s in studentsList)
            s['registration_no'] as String:
                existingAttendance[s['registration_no'] as String] ?? false,
        };
        
        // Check if attendance is already taken
        _attendanceAlreadyTaken = existingAttendance.isNotEmpty;
        _existingAttendanceCount = existingAttendance.length;
        _existingPresentCount = existingAttendance.values.where((v) => v == true).length;
        
        isLoading = false;
      });

      print('UI updated with ${students.length} students');
      print(
        'DEBUG: students variable now contains ${students.length} students',
      );
      print('DEBUG: First few students: ${students.take(3).toList()}');

      // Sort students after loading
      _sortStudents();
    } catch (e) {
      print('Error loading students: $e');
      _safeSetState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    }
  }

  void _selectSection(String section) {
    _safeSetState(() {
      selectedSection = section;
    });
    _loadStudents();
  }

  void _sortStudents() {
    _safeSetState(() {
      students.sort((a, b) {
        int comparison = 0;

        switch (_sortBy) {
          case 'registration_no':
            comparison = a['registration_no'].toString().compareTo(
              b['registration_no'].toString(),
            );
            break;
          case 'student_name':
            final nameA =
                a['student_name']?.toString() ??
                _generateStudentName(a['registration_no'].toString(), 0);
            final nameB =
                b['student_name']?.toString() ??
                _generateStudentName(b['registration_no'].toString(), 0);
            comparison = nameA.compareTo(nameB);
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _changeSortOrder(String sortBy) {
    _safeSetState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
    });
    _sortStudents();
  }

  String _generateStudentName(String registrationNo, int index) {
    // Extract meaningful parts from registration number if possible
    // For example: CS21001 -> "CS Student 001"
    if (registrationNo.length >= 6) {
      final department = registrationNo.substring(0, 2).toUpperCase();
      final year =
          registrationNo.length >= 4 ? registrationNo.substring(2, 4) : '';
      final number =
          registrationNo.length >= 6 ? registrationNo.substring(4) : '';

      return '$department$year Student $number';
    }

    // Fallback to simple numbering
    return 'Student ${index + 1}';
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _safeSetState(() {
        selectedDate = picked;
      });
      // Reload students with fresh attendance data for the new date
      _loadStudents();
    }
  }

  void _markAll(bool present) {
    _safeSetState(() {
      for (var reg in attendance.keys) {
        attendance[reg] = present;
      }
    });
  }

  // Period lock helper
  Future<bool> _acquirePeriodLock() async {
    if (selectedSection == null || selectedPeriod == null) return false;
    try {
      final supabase = Supabase.instance.client;
      final dateStr = selectedDate.toIso8601String().split('T')[0];
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('attendance_period_lock').insert({
        'department': widget.department,
        'semester': widget.semester,
        'section': selectedSection,
        'date': dateStr,
        'period': selectedPeriod,
        'taken_by': userId,
      });
      return true; // lock acquired
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // unique violation => already taken
        return false;
      }
      rethrow;
    }
  }

  Future<void> _submitAttendance() async {
    // Validation based on attendance mode
    if (_attendanceMode == 'period') {
      if (students.isEmpty || selectedPeriod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a period and ensure students are loaded',
            ),
          ),
        );
        return;
      }
    } else {
      if (students.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a section')));
        return;
      }
    }

    // NEW: acquire period lock BEFORE marking individual student attendance
    if (_attendanceMode == 'period') {
      final gotLock = await _acquirePeriodLock();
      if (!gotLock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance already submitted for Period $selectedPeriod today (any subject).',
            ),
          ),
        );
        return; // do not proceed
      }
    }

    _safeSetState(() {
      isLoading = true;
    });
    try {
      bool success = true;
      
      if (_attendanceMode == 'period') {
        // OPTIMIZED: Use bulk attendance for period mode
        final List<Map<String, dynamic>> studentAttendanceList = [];
        for (final student in students) {
          final reg = student['registration_no'] as String;
          final present = attendance[reg] ?? true;
          studentAttendanceList.add({
            'registration_no': reg,
            'is_present': present,
          });
        }
        
        success = await _attendanceService.markBulkPeriodAttendance(
          studentAttendanceList: studentAttendanceList,
          subjectCode: selectedSubject!,
          periodNumber: selectedPeriod!,
          date: selectedDate,
          department: widget.department,
          semester: widget.semester,
          section: selectedSection,
        );
      } else {
        // Keep individual loop for day mode
        for (final student in students) {
          final reg = student['registration_no'] as String;
          final present = attendance[reg] ?? true;
          final result = await _attendanceService.markDayAttendance(
            registrationNo: reg,
            isPresent: present,
            date: selectedDate,
          );
          if (!result) {
            success = false;
            break;
          }
        }
      }
      if (success) {
        final subjectInfo =
            selectedSubject != null ? selectedSubject : 'Unknown Subject';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _attendanceMode == 'period'
                  ? 'Period $selectedPeriod attendance submitted for $subjectInfo\n${DateFormat('dd MMM yyyy').format(selectedDate)} - Section $selectedSection'
                  : 'Day attendance submitted for Section $selectedSection\n${DateFormat('dd MMM yyyy').format(selectedDate)}',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting some attendance records')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting attendance: $e')),
      );
    } finally {
      _safeSetState(() {
        isLoading = false;
      });
    }
  }

  void _showEditAttendanceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Modify attendance for students who arrived late',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            // Edit Period Attendance Option
            _buildEditOption(
              icon: Icons.access_time,
              iconColor: Colors.orange,
              title: 'Edit Period Attendance',
              subtitle: 'Mark late arrivals for a specific period',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditPeriodAttendanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Edit Daily Attendance Option
            _buildEditOption(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: 'Edit Daily Attendance',
              subtitle: 'Modify daily attendance records',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditDailyAttendanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_attendanceMode == 'day' ? 'Day' : 'Period'} Attendance - ${widget.department}',
        ),
        backgroundColor:
            _attendanceMode == 'day' ? Colors.blue[700] : Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          // Edit Attendance Button in AppBar
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white),
            tooltip: 'Edit Attendance',
            onPressed: () => _showEditAttendanceOptions(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: _changeSortOrder,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'registration_no',
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == 'registration_no'
                              ? (_sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)
                              : Icons.sort,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        const Text('Sort by Registration No'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'student_name',
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == 'student_name'
                              ? (_sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)
                              : Icons.sort,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        const Text('Sort by Student Name'),
                      ],
                    ),
                  ),
                ],
            tooltip: 'Sort students',
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with controls
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _attendanceMode == 'day' ? Colors.blue[50] : Colors.green[50],
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(
                  'Semester ${widget.semester} - ${_attendanceMode == "day" ? "Day Attendance" : "Period Attendance"}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        _attendanceMode == 'day'
                            ? Colors.blue[800]
                            : Colors.green[800],
                  ),
                ),
                SizedBox(height: 12),

                // Mode toggle: Day vs Period
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Day Attendance'),
                      selected: _attendanceMode == 'day',
                      onSelected: (selected) {
                        if (selected) {
                          _safeSetState(() {
                            _attendanceMode = 'day';
                            // Reset subject/period when switching to day
                            selectedSubject = null;
                            selectedPeriod = null;
                          });
                          // Reload students with fresh attendance data for the new mode
                          _loadStudents();
                        }
                      },
                      selectedColor: Colors.blue[200],
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Period Attendance'),
                      selected: _attendanceMode == 'period',
                      onSelected: (selected) {
                        if (selected) {
                          _safeSetState(() {
                            _attendanceMode = 'period';
                            // Clear subject since it will be auto-resolved from period
                            selectedSubject = null;
                          });
                          // Reload students with fresh attendance data for the new mode
                          _loadStudents();
                        }
                      },
                      selectedColor: Colors.green[200],
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Section selection
                Text(
                  'Select Section:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Row(
                  children:
                      sections.map((section) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('Section $section'),
                            selected: selectedSection == section,
                            onSelected: (selected) {
                              if (selected) _selectSection(section);
                            },
                            selectedColor: Colors.blue[200],
                          ),
                        );
                      }).toList(),
                ),

                SizedBox(height: 12),

                // Period selection (only for period attendance)
                if (_attendanceMode == 'period') ...[
                  Text(
                    'Select Period:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          periods.map((period) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('Period $period'),
                                selected: selectedPeriod == period,
                                onSelected: (selected) {
                                  if (selected) {
                                    _safeSetState(() {
                                      selectedPeriod = period;
                                    });
                                    // Reload students with fresh attendance data for the new period
                                    _loadStudents();
                                  }
                                },
                                selectedColor: Colors.orange[200],
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Show auto-resolved subject info
                  if (selectedPeriod != null && selectedSubject != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green[700],
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Subject for Period $selectedPeriod: $selectedSubject',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (selectedPeriod != null &&
                      selectedSubject == null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.orange[700],
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No subject scheduled for Period $selectedPeriod on ${DateFormat('EEEE').format(selectedDate)}',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 12),
                ],

                // Date selection
                Row(
                  children: [
                    Text(
                      'Date: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        size: 20,
                        color:
                            _attendanceMode == 'day'
                                ? Colors.blue[700]
                                : Colors.green[700],
                      ),
                      onPressed: _selectDate,
                      tooltip: 'Select date',
                    ),
                  ],
                ),

                if (selectedSection != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markAll(true),
                          icon: Icon(Icons.check_circle, color: Colors.white),
                          label: Text('Mark All Present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markAll(false),
                          icon: Icon(Icons.cancel, color: Colors.white),
                          label: Text('Mark All Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

                  // Students list section (now inside ScrollView)
                  _buildStudentListSection(),
                ],
              ),
            ),
          ),

          // Fixed Submit button at bottom
          _buildSubmitButton(),
        ],
      ),
    );
  }

  /// Build the student list section based on current state
  Widget _buildStudentListSection() {
    // Show placeholder if selections not complete
    if (_attendanceMode == 'period'
        ? (selectedSection == null || selectedPeriod == null)
        : (selectedSection == null)) {
      return Container(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _attendanceMode == 'period'
                  ? 'Please select section and period to view students'
                  : 'Please select a section to view students',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show loading
    if (isLoading) {
      return Container(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Show empty state
    if (students.isEmpty) {
      return Container(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No students found for Section $selectedSection',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show student list
    return Column(
      children: [
        // Attendance Already Taken Status Card
        if (_attendanceAlreadyTaken)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[300]!, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance Already Taken',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '$_existingPresentCount present out of $_existingAttendanceCount students',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_attendanceMode == 'period') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditPeriodAttendanceScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditDailyAttendanceScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Attendance summary
        Container(
          padding: EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Present',
                attendance.values.where((v) => v).length,
                Colors.green,
              ),
              _buildSummaryItem(
                'Absent',
                attendance.values.where((v) => !v).length,
                Colors.red,
              ),
              _buildSummaryItem(
                'Total',
                students.length,
                Colors.blue,
              ),
            ],
          ),
        ),

        // Sort indicator
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          color: Colors.grey[50],
          child: Row(
            children: [
              Icon(
                _sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4),
              Text(
                'Sorted by ${_sortBy == 'registration_no' ? 'Registration No' : 'Student Name'} (${_sortAscending ? 'A-Z' : 'Z-A'})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Students list (using shrinkWrap so it doesn't scroll independently)
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final reg = student['registration_no'] as String;
            final present = attendance[reg] ?? false;
            final studentName =
                student['student_name']?.toString() ??
                _generateStudentName(reg, index);

            return ListTile(
              onTap: () {
                _safeSetState(() {
                  attendance[reg] = !present;
                });
              },
              leading: CircleAvatar(
                backgroundColor:
                    present ? Colors.green[100] : Colors.red[100],
                child: Icon(
                  present ? Icons.check : Icons.close,
                  color: present ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                studentName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Registration: $reg',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Container(
                width: 60,
                child: Switch(
                  value: present,
                  onChanged: (val) {
                    _safeSetState(() {
                      attendance[reg] = val;
                    });
                  },
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red[300],
                  inactiveTrackColor: Colors.red[100],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build the fixed submit button at bottom
  Widget _buildSubmitButton() {
    // Only show submit button when students are loaded
    if (students.isEmpty || isLoading) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : _submitAttendance,
          icon: Icon(Icons.save),
          label: Text(
            'Submit ${_attendanceMode == 'day' ? 'Day' : 'Period'} Attendance',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _attendanceMode == 'day'
                    ? Colors.blue[700]
                    : Colors.green[700],
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Clean up any resources here
    super.dispose();
  }
}
