import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'daily_attendance_screen.dart';
import 'package:intl/intl.dart';

class StaffAttendanceScreen extends StatefulWidget {
  final String department;
  final int semester;

  const StaffAttendanceScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  _StaffAttendanceScreenState createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  String? selectedSection;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<Map<String, dynamic>> students = [];
  Map<String, bool> attendance = {};

  final List<String> sections = ['A', 'B'];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (selectedSection == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final service = AttendanceService();
      final allStudents = await service.getAllRegistrationNumbers();
      final filtered =
          allStudents
              .where(
                (s) =>
                    s['department'] == widget.department &&
                    s['semester'] == widget.semester &&
                    s['section'] == selectedSection,
              )
              .toList();

      setState(() {
        students = filtered;
        attendance = {
          for (var s in filtered) s['registration_no'] as String: true,
        };
        isLoading = false;
      });
    } catch (e) {
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

  void _submitAttendance() {
    // Here you would typically save to database
    final presentCount = attendance.values.where((v) => v).length;
    final absentCount = attendance.values.where((v) => !v).length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance submitted for ${DateFormat('dd MMM yyyy').format(selectedDate)}\n'
          'Section $selectedSection: $presentCount present, $absentCount absent',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Attendance - ${widget.department}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header section with controls
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semester ${widget.semester}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
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

                // Date selection
                Row(
                  children: [
                    Text(
                      'Date: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    IconButton(
                      icon: Icon(Icons.calendar_today, size: 20),
                      onPressed: _selectDate,
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
                selectedSection == null
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
                            'Please select a section to view students',
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

                        // Students list
                        Expanded(
                          child: ListView.separated(
                            itemCount: students.length,
                            separatorBuilder: (_, __) => Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final student = students[idx];
                              final reg = student['registration_no'] as String;
                              final name = student['student_name'] as String;
                              final present = attendance[reg] ?? true;

                              return ListTile(
                                leading: CircleAvatar(
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
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  reg,
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: Switch(
                                  value: present,
                                  onChanged: (val) {
                                    setState(() {
                                      attendance[reg] = val;
                                    });
                                  },
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.red,
                                ),
                                tileColor:
                                    present ? Colors.green[50] : Colors.red[50],
                              );
                            },
                          ),
                        ),

                        // Submit button
                        Container(
                          padding: EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            onPressed: _submitAttendance,
                            icon: Icon(Icons.save),
                            label: Text('Submit Attendance'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
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
