import 'package:flutter/material.dart';
import '../services/exam_service.dart';
import '../services/marks_service.dart';
import '../services/student_data_service.dart';

class MarksManagementScreen extends StatefulWidget {
  final String department;
  final int semester;

  const MarksManagementScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  State<MarksManagementScreen> createState() => _MarksManagementScreenState();
}

class _MarksManagementScreenState extends State<MarksManagementScreen> {
  final ExamService _examService = ExamService();
  final MarksService _marksService = MarksService();
  final StudentDataService _studentService = StudentDataService();

  List<Map<String, dynamic>> exams = [];
  List<Map<String, dynamic>> students = [];
  Map<String, TextEditingController> markControllers = {};
  String? selectedExamId;
  String selectedSubject = 'Mathematics';
  bool isLoading = false;

  final List<String> subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Computer Science',
    'English',
    'Engineering Graphics',
    'Data Structures',
    'Database Management',
    'Software Engineering',
    'Computer Networks',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Dispose all text controllers
    markControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final examsList = await _examService.getExamsByDepartmentAndSemester(
        department: widget.department,
        semester: widget.semester,
      );

      final studentsList = await _studentService
          .getStudentsByDepartmentAndSemester(
            department: widget.department,
            semester: widget.semester,
          );

      setState(() {
        exams = examsList;
        students = studentsList;
        if (exams.isNotEmpty && selectedExamId == null) {
          selectedExamId = exams.first['id'];
        }

        // Initialize text controllers for each student
        markControllers.clear();
        for (var student in students) {
          markControllers[student['registration_no']] = TextEditingController();
        }
      });

      // Load existing marks if exam and subject are selected
      if (selectedExamId != null) {
        await _loadExistingMarks();
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $error')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadExistingMarks() async {
    if (selectedExamId == null) return;

    try {
      final existingMarks = await _marksService.getExamMarksBySubject(
        examId: selectedExamId!,
        subject: selectedSubject,
      );

      // Update text controllers with existing marks
      for (var mark in existingMarks) {
        final regNo = mark['registration_no'];
        if (markControllers.containsKey(regNo)) {
          markControllers[regNo]!.text = mark['mark'].toString();
        }
      }
    } catch (error) {
      print('Error loading existing marks: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marks Management'),
            Text(
              '${widget.department} - Semester ${widget.semester}',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _showCreateExamDialog),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildExamSelector(),
                  _buildSubjectSelector(),
                  Expanded(child: _buildStudentsList()),
                  _buildSaveButton(),
                ],
              ),
    );
  }

  Widget _buildExamSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Exam:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedExamId,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                exams.map<DropdownMenuItem<String>>((exam) {
                  return DropdownMenuItem<String>(
                    value: exam['id'] as String,
                    child: Text(exam['name'] as String),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() => selectedExamId = value);
              _loadExistingMarks();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedSubject,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                subjects.map<DropdownMenuItem<String>>((subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() => selectedSubject = value!);
              _loadExistingMarks();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No students found for this department and semester.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentMarkCard(student);
      },
    );
  }

  Widget _buildStudentMarkCard(Map<String, dynamic> student) {
    final regNo = student['registration_no'];
    final controller = markControllers[regNo]!;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reg: $regNo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Section: ${student['section']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Mark',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixText: '/ 100',
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  // Validate input
                  final mark = int.tryParse(value);
                  if (mark != null && (mark < 0 || mark > 100)) {
                    controller.text = '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mark must be between 0 and 100')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: selectedExamId != null ? _saveMarks : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Save Marks', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _saveMarks() async {
    if (selectedExamId == null) return;

    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> marksList = [];

      for (var student in students) {
        final regNo = student['registration_no'];
        final markText = markControllers[regNo]!.text.trim();

        if (markText.isNotEmpty) {
          final mark = int.tryParse(markText);
          if (mark != null && mark >= 0 && mark <= 100) {
            marksList.add({
              'registration_no': regNo,
              'exam_id': selectedExamId,
              'subject': selectedSubject,
              'mark': mark,
              'out_of': 100,
            });
          }
        }
      }

      if (marksList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter at least one valid mark')),
        );
        return;
      }

      final success = await _marksService.bulkInsertMarks(marksList);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved ${marksList.length} marks!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save marks');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving marks: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showCreateExamDialog() {
    final nameController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Create New Exam'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Exam Name',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Model Exam 3',
                        ),
                      ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              Duration(days: 30),
                            ),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today),
                              SizedBox(width: 8),
                              Text(
                                selectedDate?.toString().split(' ')[0] ??
                                    'Select exam date',
                                style: TextStyle(
                                  color:
                                      selectedDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isNotEmpty) {
                          final success = await _examService.createExam(
                            name: nameController.text.trim(),
                            department: widget.department,
                            semester: widget.semester,
                            date: selectedDate,
                          );

                          if (success != null) {
                            Navigator.pop(context);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exam created successfully!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error creating exam')),
                            );
                          }
                        }
                      },
                      child: Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }
}
