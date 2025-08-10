import 'package:flutter/material.dart';
import '../services/student_data_service.dart';
import '../services/attendance_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // added for period lock

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
  String _sortBy = 'student_name'; // registration_no, student_name
  bool _sortAscending = true;

  // Add local mode that can be toggled in-screen
  late String _attendanceMode; // 'day' or 'period'

  final List<String> sections = ['A', 'B'];
  final List<int> periods = [1, 2, 3, 4, 5, 6];
  final StudentDataService _studentDataService = StudentDataService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _attendanceMode =
        widget.attendanceType; // initialize from initial route param
    _setupDatabase();
  }

  Future<void> _setupDatabase() async {
    // Setup students table and data
    await _studentDataService.setupStudentsTable();
    await _loadSubjects();
    await _loadSchedule();
    if (selectedSection != null) {
      _loadStudents();
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final subjectsList = await _attendanceService.getSubjects(
        department: widget.department,
        semester: widget.semester,
      );
      setState(() {
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
      setState(() {
        schedule = scheduleList;
      });
    } catch (e) {
      print('Error loading schedule: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (selectedSection == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      print(
        'Loading students for department: ${widget.department}, semester: ${widget.semester}, section: $selectedSection',
      );

      // Use the student data service to get students
      final students = await _studentDataService.getStudentsBySection(
        department: widget.department,
        semester: widget.semester,
        section: selectedSection!,
      );

      print('Loaded ${students.length} students: $students');

      setState(() {
        this.students = students;
        attendance = {
          for (var s in students) s['registration_no'] as String: true,
        };
        isLoading = false;
      });

      // Sort students after loading
      _sortStudents();
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
    }
  }

  void _selectSection(String section) {
    setState(() {
      selectedSection = section;
    });
    _loadStudents();
  }

  void _sortStudents() {
    setState(() {
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
    setState(() {
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
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _markAll(bool present) {
    setState(() {
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
      if (students.isEmpty ||
          selectedSubject == null ||
          selectedPeriod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select subject and period')),
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

    setState(() {
      isLoading = true;
    });
    try {
      bool success = true;
      for (final student in students) {
        final reg = student['registration_no'] as String;
        final present = attendance[reg] ?? true;
        dynamic result;
        if (_attendanceMode == 'period') {
          result = await _attendanceService.markPeriodAttendance(
            registrationNo: reg,
            subjectCode: selectedSubject!,
            periodNumber: selectedPeriod!,
            isPresent: present,
            date: selectedDate,
          );
        } else {
          result = await _attendanceService.markDayAttendance(
            registrationNo: reg,
            isPresent: present,
            date: selectedDate,
          );
        }
        if (!result) {
          success = false;
          break;
        }
      }
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _attendanceMode == 'period'
                  ? 'Period $selectedPeriod attendance submitted for $selectedSubject\n${DateFormat('dd MMM yyyy').format(selectedDate)} - Section $selectedSection'
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
      setState(() {
        isLoading = false;
      });
    }
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
                          setState(() {
                            _attendanceMode = 'day';
                            // Reset subject/period when switching to day
                            selectedSubject = null;
                            selectedPeriod = null;
                          });
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
                          setState(() {
                            _attendanceMode = 'period';
                          });
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

                // Subject selection (only for period attendance)
                if (_attendanceMode == 'period') ...[
                  Text(
                    'Select Subject:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  if (subjects.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            subjects.map((subject) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    subject['subject_name'] ??
                                        subject['subject_code'],
                                  ),
                                  selected:
                                      selectedSubject ==
                                      subject['subject_code'],
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedSubject =
                                            subject['subject_code'];
                                      });
                                    }
                                  },
                                  selectedColor: Colors.green[200],
                                ),
                              );
                            }).toList(),
                      ),
                    )
                  else
                    Text('No subjects available for this department/semester'),

                  SizedBox(height: 12),

                  // Period selection (only for period attendance)
                  Text(
                    'Select Period:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children:
                        periods.map((period) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('Period $period'),
                              selected: selectedPeriod == period,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedPeriod = period;
                                  });
                                }
                              },
                              selectedColor: Colors.orange[200],
                            ),
                          );
                        }).toList(),
                  ),

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

          // Students list
          Expanded(
            child:
                (_attendanceMode == 'period'
                        ? (selectedSection == null ||
                            selectedSubject == null ||
                            selectedPeriod == null)
                        : (selectedSection == null))
                    ? Center(
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
                                ? 'Please select section, subject, and period to view students'
                                : 'Please select a section to view students',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : isLoading
                    ? Center(child: CircularProgressIndicator())
                    : students.isEmpty
                    ? Center(
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
                    )
                    : Column(
                      children: [
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
                          color: Colors.blue[50],
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sorted by: ${_sortBy == 'registration_no' ? 'Registration Number' : 'Student Name'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                _sortAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              Spacer(),
                              Text(
                                '${students.length} students',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Students list
                        Expanded(
                          child: ListView.separated(
                            itemCount: students.length,
                            separatorBuilder: (_, __) => Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final student = students[idx];
                              final reg = student['registration_no'] as String;
                              final present = attendance[reg] ?? true;

                              // Generate a meaningful student name if not available
                              String studentName =
                                  student['student_name'] as String? ??
                                  _generateStudentName(reg, idx);

                              return ListTile(
                                onTap: () {
                                  setState(() {
                                    attendance[reg] = !present;
                                  });
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minVerticalPadding: 12,
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      present
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color:
                                          present
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'Reg: $reg',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Transform.scale(
                                  scale: 1.25, // enlarge switch for easier tap
                                  child: Switch(
                                    value: present,
                                    onChanged: (val) {
                                      setState(() {
                                        attendance[reg] = val;
                                      });
                                    },
                                    activeColor: Colors.white,
                                    activeTrackColor: Colors.green,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Colors.red,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                tileColor:
                                    present ? Colors.green[50] : Colors.red[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                        ),

                        // Submit button
                        Container(
                          padding: EdgeInsets.all(16),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
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
}
