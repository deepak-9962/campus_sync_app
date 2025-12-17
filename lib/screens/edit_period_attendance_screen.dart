import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPeriodAttendanceScreen extends StatefulWidget {
  const EditPeriodAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<EditPeriodAttendanceScreen> createState() =>
      _EditPeriodAttendanceScreenState();
}

class _EditPeriodAttendanceScreenState
    extends State<EditPeriodAttendanceScreen> {
  final _supabase = Supabase.instance.client;

  // Filter values
  DateTime _selectedDate = DateTime.now();
  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedSection;
  String? _selectedPeriod;

  // Data
  List<Map<String, dynamic>> _departments = [
    {'code': 'CSE', 'name': 'Computer Science and Engineering'},
    {'code': 'IT', 'name': 'Information Technology'},
    {'code': 'ECE', 'name': 'Electronics and Communication Engineering'},
    {'code': 'AIDS', 'name': 'Artificial Intelligence & Data Science'},
    {'code': 'AIML', 'name': 'Artificial Intelligence & Machine Learning'},
    {'code': 'BME', 'name': 'Biomedical Engineering'},
    {'code': 'RAE', 'name': 'Robotics and Automation'},
    {'code': 'MECH', 'name': 'Mechanical Engineering'},
  ];
  List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  List<String> _sections = ['A', 'B', 'C'];
  List<String> _periods = ['1', '2', '3', '4', '5', '6'];
  List<Map<String, dynamic>> _attendanceRecords = [];
  Map<String, String> _modifiedStatuses = {};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _attendanceTaken = false;
  bool _showRecords = false;
  int _attendanceCount = 0;
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get saved department (try both keys)
      String? savedDepartment = prefs.getString('selected_department') ?? 
                                prefs.getString('admin_selected_department');
      
      // Get saved semester (try both keys)
      int? savedSemester = prefs.getInt('selected_semester') ?? 
                          prefs.getInt('admin_selected_semester');
      
      setState(() {
        // Map full department name to code
        if (savedDepartment != null) {
          final deptLower = savedDepartment.toLowerCase();
          if (deptLower.contains('computer science')) {
            _selectedDepartment = 'CSE';
          } else if (deptLower.contains('information technology')) {
            _selectedDepartment = 'IT';
          } else if (deptLower.contains('electronics')) {
            _selectedDepartment = 'ECE';
          } else if (deptLower.contains('mechanical')) {
            _selectedDepartment = 'MECH';
          } else if (deptLower.contains('biomedical')) {
            _selectedDepartment = 'BME';
          } else if (deptLower.contains('robotics')) {
            _selectedDepartment = 'RAE';
          } else if (deptLower.contains('machine learning')) {
            _selectedDepartment = 'AIML';
          } else if (deptLower.contains('data science') || deptLower.contains('artificial intelligence')) {
            _selectedDepartment = 'AIDS';
          } else {
            // Try to find matching code or name
            for (var dept in _departments) {
              if (dept['name'].toString().toLowerCase() == deptLower ||
                  dept['code'].toString().toLowerCase() == deptLower) {
                _selectedDepartment = dept['code'];
                break;
              }
            }
          }
        }
        
        // Set semester
        if (savedSemester != null && savedSemester >= 1 && savedSemester <= 8) {
          _selectedSemester = savedSemester.toString();
        }
      });
      
      debugPrint('Loaded preferences - Department: $_selectedDepartment, Semester: $_selectedSemester');
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  // Check if attendance is already taken
  Future<void> _checkAttendanceStatus() async {
    if (_selectedDepartment == null ||
        _selectedSemester == null ||
        _selectedSection == null ||
        _selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all filters')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _attendanceRecords = [];
      _attendanceTaken = false;
      _showRecords = false;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final periodNum = int.tryParse(_selectedPeriod!) ?? 1;

      // Get students from the selected department/semester/section
      final studentsResponse = await _supabase
          .from('students')
          .select('registration_no')
          .ilike('department', '%${_selectedDepartment!.toLowerCase().contains('cse') ? 'computer science' : _selectedDepartment!}%')
          .eq('current_semester', int.tryParse(_selectedSemester!) ?? 0)
          .eq('section', _selectedSection!);

      if (studentsResponse.isEmpty) {
        setState(() {
          _isLoading = false;
          _attendanceTaken = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No students found for selected filters')),
          );
        }
        return;
      }

      // Check if any attendance records exist for this date/period
      final regNos = studentsResponse.map((s) => s['registration_no']).toList();
      final attendanceCheck = await _supabase
          .from('attendance')
          .select('id, registration_no')
          .inFilter('registration_no', regNos)
          .eq('date', dateStr)
          .eq('period_number', periodNum);

      final int attendanceCount = attendanceCheck.length;
      final int totalStudents = studentsResponse.length;

      setState(() {
        _isLoading = false;
        _attendanceTaken = attendanceCount > 0;
        _attendanceCount = attendanceCount;
        _totalStudents = totalStudents;
      });

      if (_attendanceTaken && mounted) {
        // Show dialog asking if user wants to edit
        _showEditConfirmationDialog();
      } else if (!_attendanceTaken && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No attendance taken yet for this period'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking attendance status: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking attendance: $e')),
        );
      }
    }
  }

  void _showEditConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            const Text('Attendance Already Taken'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance for Period $_selectedPeriod on ${DateFormat('dd MMM yyyy').format(_selectedDate)} has already been marked.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    '$_attendanceCount / $_totalStudents students marked',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do you want to edit the attendance?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _loadAttendanceRecords();
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
      _modifiedStatuses.clear();
      _hasChanges = false;
      _showRecords = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final periodNum = int.tryParse(_selectedPeriod!) ?? 1;

      // Step 1: Get students from the selected department/semester/section
      final studentsResponse = await _supabase
          .from('students')
          .select('registration_no, student_name, section, department, current_semester')
          .ilike('department', '%${_selectedDepartment!.toLowerCase().contains('cse') ? 'computer science' : _selectedDepartment!}%')
          .eq('current_semester', int.tryParse(_selectedSemester!) ?? 0)
          .eq('section', _selectedSection!)
          .order('registration_no', ascending: true);

      if (studentsResponse.isEmpty) {
        setState(() {
          _attendanceRecords = [];
          _isLoading = false;
        });
        return;
      }

      // Step 2: Get period attendance for these students on the selected date and period
      List<Map<String, dynamic>> records = [];
      
      for (var student in studentsResponse) {
        final regNo = student['registration_no'];
        
        // Try to find attendance record for this student
        final attendanceResponse = await _supabase
            .from('attendance')
            .select('id, registration_no, date, period_number, is_present, subject_code')
            .eq('registration_no', regNo)
            .eq('date', dateStr)
            .eq('period_number', periodNum)
            .maybeSingle();

        String status = 'absent'; // Default
        String? attendanceId;
        String? subjectCode;
        
        if (attendanceResponse != null) {
          attendanceId = attendanceResponse['id'].toString();
          status = attendanceResponse['is_present'] == true ? 'present' : 'absent';
          subjectCode = attendanceResponse['subject_code'];
        }

        records.add({
          'id': attendanceId ?? 'new_$regNo',
          'registration_no': regNo,
          'date': dateStr,
          'period_number': periodNum,
          'subject_code': subjectCode,
          'status': status,
          'is_new': attendanceId == null,
          'students': {
            'name': student['student_name'] ?? 'Unknown',
            'registration_no': regNo,
          },
        });
      }

      // Sort records: absent students first, then present students
      // Within each group, maintain ascending order by registration_no
      records.sort((a, b) {
        // First sort by status (absent first)
        if (a['status'] == 'absent' && b['status'] == 'present') return -1;
        if (a['status'] == 'present' && b['status'] == 'absent') return 1;
        // Then sort by registration_no (ascending)
        return (a['registration_no'] ?? '').compareTo(b['registration_no'] ?? '');
      });

      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading period attendance: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    }
  }

  void _updateStatus(String recordId, String currentStatus) {
    // Toggle between present and absent
    String newStatus = currentStatus == 'present' ? 'absent' : 'present';

    setState(() {
      _modifiedStatuses[recordId] = newStatus;
      _hasChanges = true;
    });
  }

  String _getEffectiveStatus(Map<String, dynamic> record) {
    final recordId = record['id'].toString();
    return _modifiedStatuses[recordId] ?? record['status'] ?? 'absent';
  }

  Future<void> _saveChanges() async {
    if (_modifiedStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final periodNum = int.tryParse(_selectedPeriod!) ?? 1;
      int successCount = 0;

      for (var entry in _modifiedStatuses.entries) {
        final recordId = entry.key;
        final newStatus = entry.value;
        final isPresent = newStatus == 'present';

        // Find the record
        final record = _attendanceRecords.firstWhere(
          (r) => r['id'].toString() == recordId,
          orElse: () => {},
        );

        if (record.isEmpty) continue;

        final regNo = record['registration_no'];
        final isNew = record['is_new'] == true;

        if (isNew) {
          // For new records, we need a subject_code - skip if not available
          // In a real scenario, you'd get this from the timetable
          debugPrint('Skipping new record for $regNo - no subject code available');
          continue;
        } else {
          // Update existing record
          final numericId = int.tryParse(recordId);
          if (numericId != null) {
            await _supabase
                .from('attendance')
                .update({
                  'is_present': isPresent,
                })
                .eq('id', numericId);
            successCount++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount records updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload to show updated data
      await _loadAttendanceRecords();
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _attendanceRecords.clear();
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Period Attendance'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              children: [
                // Date Picker
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Department & Semester Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _departments.map<DropdownMenuItem<String>>((dept) {
                          return DropdownMenuItem<String>(
                            value: dept['code'].toString(),
                            child: Text(
                              dept['code'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _attendanceRecords.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSemester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _semesters.map((sem) {
                          return DropdownMenuItem(
                            value: sem,
                            child: Text('Sem $sem'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSemester = value;
                            _attendanceRecords.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Section & Period Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _sections.map((sec) {
                          return DropdownMenuItem(
                            value: sec,
                            child: Text('Section $sec'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value;
                            _attendanceRecords.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPeriod,
                        decoration: const InputDecoration(
                          labelText: 'Period',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text('Period $period'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPeriod = value;
                            _attendanceRecords.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Check Attendance Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkAttendanceStatus,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Check Attendance'),
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

          // Attendance Status Card (shown after checking)
          if (_attendanceTaken && !_showRecords)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Already Taken',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Period $_selectedPeriod • ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$_attendanceCount',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            const Text('Marked'),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              '$_totalStudents',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Text('Total'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadAttendanceRecords,
                      icon: const Icon(Icons.edit),
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

          // Legend (only show when records are displayed)
          if (_showRecords)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem('Present', Colors.green, Icons.check_circle),
                _legendItem('Absent', Colors.red, Icons.cancel),
              ],
            ),
          ),

          // Instructions
          if (_showRecords && _attendanceRecords.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue[50],
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap on a student to toggle status: Present <-> Absent',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Attendance List
          if (_showRecords)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select filters and tap "Check Attendance"',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _attendanceRecords.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final record = _attendanceRecords[index];
                          final student = record['students'] ?? {};
                          final recordId = record['id'].toString();
                          final status = _getEffectiveStatus(record);
                          final isModified = _modifiedStatuses.containsKey(recordId);
                          final isNew = record['is_new'] == true;

                          return Card(
                            elevation: isModified ? 4 : 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: isModified
                                  ? BorderSide(color: _getStatusColor(status), width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              onTap: isNew ? null : () => _updateStatus(recordId, status),
                              leading: CircleAvatar(
                                backgroundColor: isNew ? Colors.grey : _getStatusColor(status),
                                child: Icon(
                                  isNew ? Icons.help_outline : _getStatusIcon(status),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                student['name'] ?? 'Unknown Student',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reg No: ${student['registration_no'] ?? 'N/A'}'),
                                  if (record['subject_code'] != null)
                                    Text(
                                      'Subject: ${record['subject_code']}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isNew ? Colors.grey : _getStatusColor(status)).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isNew ? Colors.grey : _getStatusColor(status)),
                                    ),
                                    child: Text(
                                      isNew ? 'NO RECORD' : status.toUpperCase(),
                                      style: TextStyle(
                                        color: isNew ? Colors.grey : _getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  if (isModified)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Modified',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Summary Bar
          if (_showRecords && _attendanceRecords.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(
                    'Present',
                    _attendanceRecords
                        .where((r) => _getEffectiveStatus(r) == 'present')
                        .length,
                    Colors.green,
                  ),
                  _summaryItem(
                    'Absent',
                    _attendanceRecords
                        .where((r) => _getEffectiveStatus(r) == 'absent')
                        .length,
                    Colors.red,
                  ),
                  _summaryItem(
                    'No Record',
                    _attendanceRecords
                        .where((r) => r['is_new'] == true)
                        .length,
                    Colors.grey,
                  ),
                ],
              ),
            ),

          // Initial state - prompt to check attendance
          if (!_showRecords && !_attendanceTaken && !_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Select filters and check attendance',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Check Attendance" to see if attendance is taken',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _summaryItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}
