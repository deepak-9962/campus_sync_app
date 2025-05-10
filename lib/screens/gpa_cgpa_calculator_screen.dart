import 'package:flutter/material.dart';

class GpaCgpaCalculatorScreen extends StatefulWidget {
  final String? initialDepartment;
  final String? initialSemester;

  const GpaCgpaCalculatorScreen({
    super.key,
    this.initialDepartment,
    this.initialSemester,
  });

  @override
  _GpaCgpaCalculatorScreenState createState() =>
      _GpaCgpaCalculatorScreenState();
}

class _GpaCgpaCalculatorScreenState extends State<GpaCgpaCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedDepartment;
  late String _selectedGpaSemester;

  final List<String> _departmentOptions = [
    'Artificial Intelligence & Data Science',
    'Artificial Intelligence & Machine Learning',
    'Biomedical Engineering',
    'Computer Science and Engineering',
    'Electronics and Communication Engineering',
    'Information Technology',
    'Robotics and Automation',
    'Mechanical Engineering',
  ];
  final List<String> _semesterOptions = List.generate(
    8,
    (index) => (index + 1).toString(),
  );

  List<SubjectEntry> _subjectEntries = [];
  double _calculatedGpa = 0.0;

  final Map<String, Map<String, List<SubjectData>>>
  _departmentSemesterSubjectsData = {
    'Computer Science and Engineering': {
      '1': [
        SubjectData(
          code: 'HS3152',
          name: 'Professional English - I',
          credits: 3,
        ),
        SubjectData(code: 'MA3151', name: 'Matrices and Calculus', credits: 4),
        SubjectData(code: 'PH3151', name: 'Engineering Physics', credits: 3),
        SubjectData(code: 'CY3151', name: 'Engineering Chemistry', credits: 3),
        SubjectData(
          code: 'GE3151',
          name: 'Problem Solving and Python Programming',
          credits: 3,
        ),
        SubjectData(
          code: 'GE3152',
          name: 'தமிழர் மரபு /Heritage of Tamils',
          credits: 1,
        ),
        SubjectData(
          code: 'GE3171',
          name: 'Problem Solving and Python Programming Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'BS3171',
          name: 'Physics and Chemistry Laboratory',
          credits: 2,
        ),
        SubjectData(code: 'GE3172', name: 'English Laboratory', credits: 1),
      ],
      '2': [
        SubjectData(
          code: 'HS3252',
          name: 'Professional English - II',
          credits: 2,
        ),
        SubjectData(
          code: 'MA3251',
          name: 'Statistics and Numerical Methods',
          credits: 4,
        ),
        SubjectData(
          code: 'PH3256',
          name: 'Physics for Information Science',
          credits: 3,
        ),
        SubjectData(
          code: 'BE3251',
          name: 'Basic Electrical and Electronics Engineering',
          credits: 3,
        ),
        SubjectData(code: 'GE3251', name: 'Engineering Graphics', credits: 4),
        SubjectData(code: 'CS3251', name: 'Programming in C', credits: 3),
        SubjectData(
          code: 'GE3252',
          name: 'தமிழரும் தொழில்நுட்பமும் /Tamils and Technology',
          credits: 1,
        ),
        SubjectData(
          code: 'GE3271',
          name: 'Engineering Practices Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'CS3271',
          name: 'Programming in C Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'GE3272',
          name: 'Communication Laboratory / Foreign Language',
          credits: 2,
        ),
      ],
      '3': [
        SubjectData(code: 'MA3354', name: 'Discrete Mathematics', credits: 4),
        SubjectData(
          code: 'CS3351',
          name: 'Digital Principles and Computer Organization',
          credits: 4,
        ),
        SubjectData(
          code: 'CS3352',
          name: 'Foundations of Data Science',
          credits: 3,
        ),
        SubjectData(code: 'CS3301', name: 'Data Structures', credits: 3),
        SubjectData(
          code: 'CS3391',
          name: 'Object Oriented Programming',
          credits: 3,
        ),
        SubjectData(
          code: 'CS3311',
          name: 'Data Structures Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'CS3381',
          name: 'Object Oriented Programming Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'CS3361',
          name: 'Data Science Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'GE3361',
          name: 'Professional Development',
          credits: 1,
        ),
      ],
      '4': [
        SubjectData(code: 'CS3452', name: 'Theory of Computation', credits: 3),
        SubjectData(
          code: 'CS3491',
          name: 'Artificial Intelligence and Machine Learning',
          credits: 4,
        ),
        SubjectData(
          code: 'CS3492',
          name: 'Database Management Systems',
          credits: 3,
        ),
        SubjectData(code: 'CS3401', name: 'Algorithms', credits: 4),
        SubjectData(
          code: 'CS3451',
          name: 'Introduction to Operating Systems',
          credits: 3,
        ),
        SubjectData(
          code: 'GE3451',
          name: 'Environmental Sciences and Sustainability',
          credits: 2,
        ),
        SubjectData(
          code: 'CS3461',
          name: 'Operating Systems Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'CS3481',
          name: 'Database Management Systems Laboratory',
          credits: 1.5,
        ),
      ],
      '5': [
        SubjectData(code: 'CS3591', name: 'Computer Networks', credits: 4),
        SubjectData(code: 'CS3501', name: 'Compiler Design', credits: 4),
        SubjectData(
          code: 'CB3491',
          name: 'Cryptography and Cyber Security',
          credits: 3,
        ),
        SubjectData(code: 'CS3551', name: 'Distributed Computing', credits: 3),
        SubjectData(code: 'PE_I', name: 'Professional Elective I', credits: 3),
        SubjectData(
          code: 'PE_II',
          name: 'Professional Elective II',
          credits: 3,
        ),
      ],
      '6': [
        SubjectData(
          code: 'CCS356',
          name: 'Object Oriented Software Engineering',
          credits: 4,
        ),
        SubjectData(
          code: 'CS3691',
          name: 'Embedded Systems and IoT',
          credits: 4,
        ),
        SubjectData(code: 'OE_I', name: 'Open Elective – I', credits: 3),
        SubjectData(
          code: 'PE_III',
          name: 'Professional Elective III',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_IV',
          name: 'Professional Elective IV',
          credits: 3,
        ),
        SubjectData(code: 'PE_V', name: 'Professional Elective V', credits: 3),
        SubjectData(
          code: 'PE_VI',
          name: 'Professional Elective VI',
          credits: 3,
        ),
      ],
      '7': [
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(
          code: 'MGMT_ELEC',
          name: 'Elective - Management',
          credits: 3,
        ),
        SubjectData(code: 'OE_II', name: 'Open Elective – II', credits: 3),
        SubjectData(code: 'OE_III', name: 'Open Elective – III', credits: 3),
        SubjectData(code: 'OE_IV', name: 'Open Elective – IV', credits: 3),
        SubjectData(code: 'CS3711', name: 'Summer internship', credits: 2),
      ],
      '8': [
        SubjectData(
          code: 'CS3811',
          name: 'Project Work/Internship',
          credits: 10,
        ),
      ],
    },
    'Information Technology': {
      '1': [
        SubjectData(
          code: 'HS3152',
          name: 'Professional English - I',
          credits: 3,
        ),
        SubjectData(code: 'MA3151', name: 'Matrices and Calculus', credits: 4),
        SubjectData(code: 'PH3151', name: 'Engineering Physics', credits: 3),
        SubjectData(code: 'CY3151', name: 'Engineering Chemistry', credits: 3),
        SubjectData(
          code: 'GE3151',
          name: 'Problem Solving and Python Programming',
          credits: 3,
        ),
        SubjectData(
          code: 'GE3152',
          name: 'தமிழர் மரபு /Heritage of Tamils',
          credits: 1,
        ),
        SubjectData(
          code: 'GE3171',
          name: 'Problem Solving and Python Programming Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'BS3171',
          name: 'Physics and Chemistry Laboratory',
          credits: 2,
        ),
        SubjectData(code: 'GE3172', name: 'English Laboratory', credits: 1),
      ],
      '2': [
        SubjectData(
          code: 'HS3252',
          name: 'Professional English - II',
          credits: 2,
        ),
        SubjectData(
          code: 'MA3251',
          name: 'Statistics and Numerical Methods',
          credits: 4,
        ),
        SubjectData(
          code: 'PH3256',
          name: 'Physics for Information Science',
          credits: 3,
        ),
        SubjectData(
          code: 'BE3251',
          name: 'Basic Electrical and Electronics Engineering',
          credits: 3,
        ),
        SubjectData(code: 'GE3251', name: 'Engineering Graphics', credits: 4),
        SubjectData(code: 'CS3251', name: 'Programming in C', credits: 3),
        SubjectData(
          code: 'GE3252',
          name: 'தமிழரும் தொழில்நுட்பமும் /Tamils and Technology',
          credits: 1,
        ),
        SubjectData(
          code: 'GE3271',
          name: 'Engineering Practices Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'CS3271',
          name: 'Programming in C Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'GE3272',
          name: 'Communication Laboratory / Foreign Language',
          credits: 2,
        ),
      ],
      '3': [
        SubjectData(code: 'MA3354', name: 'Discrete Mathematics', credits: 4),
        SubjectData(
          code: 'CS3351',
          name: 'Digital Principles and Computer Organization',
          credits: 4,
        ),
        SubjectData(
          code: 'CS3352',
          name: 'Foundations of Data Science',
          credits: 3,
        ),
        SubjectData(
          code: 'CD3291',
          name: 'Data Structures and Algorithms',
          credits: 3,
        ), // IT specific
        SubjectData(
          code: 'CS3391',
          name: 'Object Oriented Programming',
          credits: 3,
        ),
        SubjectData(
          code: 'CD3281',
          name: 'Data Structures and Algorithms Laboratory',
          credits: 2,
        ), // IT specific
        SubjectData(
          code: 'CS3381',
          name: 'Object Oriented Programming Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'CS3361',
          name: 'Data Science Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'GE3361',
          name: 'Professional Development',
          credits: 1,
        ),
      ],
      '4': [
        SubjectData(code: 'CS3452', name: 'Theory of Computation', credits: 3),
        SubjectData(
          code: 'CS3491',
          name: 'Artificial Intelligence and Machine Learning',
          credits: 4,
        ),
        SubjectData(
          code: 'CS3492',
          name: 'Database Management Systems',
          credits: 3,
        ),
        SubjectData(
          code: 'IT3401',
          name: 'Web Essentials',
          credits: 4,
        ), // IT specific
        SubjectData(
          code: 'CS3451',
          name: 'Introduction to Operating Systems',
          credits: 3,
        ),
        SubjectData(
          code: 'GE3451',
          name: 'Environmental Sciences and Sustainability',
          credits: 2,
        ),
        SubjectData(
          code: 'CS3461',
          name: 'Operating Systems Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'CS3481',
          name: 'Database Management Systems Laboratory',
          credits: 1.5,
        ),
      ],
      '5': [
        SubjectData(code: 'CS3591', name: 'Computer Networks', credits: 4),
        SubjectData(
          code: 'IT3501',
          name: 'Full Stack Web Development',
          credits: 3,
        ), // IT specific
        SubjectData(code: 'CS3551', name: 'Distributed Computing', credits: 3),
        SubjectData(
          code: 'CS3691',
          name: 'Embedded Systems and IoT',
          credits: 4,
        ), // Note: This is CS3691, might be an elective or core for IT
        SubjectData(
          code: 'PE_IT_I',
          name: 'Professional Elective I (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_IT_II',
          name: 'Professional Elective II (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'IT3511',
          name: 'Full Stack Web Development Laboratory',
          credits: 2,
        ), // IT specific
      ],
      '6': [
        SubjectData(
          code: 'CCS356',
          name: 'Object Oriented Software Engineering',
          credits: 4,
        ),
        SubjectData(
          code: 'OE_IT_I',
          name: 'Open Elective – I (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_IT_III',
          name: 'Professional Elective III (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_IT_IV',
          name: 'Professional Elective IV (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_IT_V',
          name: 'Professional Elective V (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_IT_VI',
          name: 'Professional Elective VI (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'IT3681',
          name: 'Mobile Applications Development Laboratory',
          credits: 1.5,
        ), // IT specific
      ],
      '7': [
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(
          code: 'MGMT_ELEC_IT',
          name: 'Elective - Management (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'OE_IT_II',
          name: 'Open Elective – II (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'OE_IT_III',
          name: 'Open Elective – III (IT)',
          credits: 3,
        ),
        SubjectData(
          code: 'OE_IT_IV',
          name: 'Open Elective – IV (IT)',
          credits: 3,
        ),
        SubjectData(code: 'IT3711', name: 'Summer internship', credits: 2),
      ],
      '8': [
        SubjectData(
          code: 'IT3811',
          name: 'Project Work/Internship',
          credits: 10,
        ),
      ],
    },
    'Artificial Intelligence & Data Science': {
      '1': [],
      '2': [],
      '3': [],
      '4': [],
      '5': [],
      '6': [],
      '7': [],
      '8': [],
    },
    'Artificial Intelligence & Machine Learning': {
      '1': [],
      '2': [],
      '3': [],
      '4': [],
      '5': [],
      '6': [],
      '7': [],
      '8': [],
    },
    'Biomedical Engineering': {
      '1': [],
      '2': [],
      '3': [],
      '4': [],
      '5': [],
      '6': [],
      '7': [],
      '8': [],
    },
    'Electronics and Communication Engineering': {
      '1': [],
      '2': [],
      '3': [],
      '4': [],
      '5': [],
      '6': [],
      '7': [],
      '8': [],
    },
    'Robotics and Automation': {
      '1': [],
      '2': [],
      '3': [],
      '4': [],
      '5': [],
      '6': [],
      '7': [],
      '8': [],
    },
    'Mechanical Engineering': {
      '1': [],
      '2': [],
      '3': [],
      '4': [],
      '5': [],
      '6': [],
      '7': [],
      '8': [],
    },
  };

  List<SemesterEntry> _semesterEntries = [SemesterEntry(gpa: 0.0, credits: 0)];
  double _calculatedCgpa = 0.0;

  final Map<String, double> _gradePoints = {
    'O': 10.0,
    'A+': 9.0,
    'A': 8.0,
    'B+': 7.0,
    'B': 6.0,
    'C': 5.0,
    'RA': 0.0,
  };
  final List<String> _gradeOptions = ['O', 'A+', 'A', 'B+', 'B', 'C', 'RA'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDepartment =
        widget.initialDepartment ?? 'Computer Science and Engineering';
    _selectedGpaSemester = widget.initialSemester ?? '1';

    if (!_departmentOptions.contains(_selectedDepartment)) {
      _selectedDepartment = 'Computer Science and Engineering';
    }
    if (!_semesterOptions.contains(_selectedGpaSemester)) {
      _selectedGpaSemester = '1';
    }
    _loadSubjectsForSelectedSemester();
  }

  void _loadSubjectsForSelectedSemester() {
    for (var entry in _subjectEntries) {
      entry.creditsController.dispose();
    }
    _subjectEntries.clear();
    final departmentData =
        _departmentSemesterSubjectsData[_selectedDepartment] ?? {};
    final subjectsData = departmentData[_selectedGpaSemester] ?? [];
    setState(() {
      _subjectEntries =
          subjectsData
              .map(
                (data) => SubjectEntry(
                  code: data.code,
                  name: data.name,
                  grade: 'O',
                  credits: data.credits,
                ),
              )
              .toList();
      _calculatedGpa = 0.0;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectEntries.forEach((entry) => entry.creditsController.dispose());
    _semesterEntries.forEach((entry) {
      entry.gpaController.dispose();
      entry.creditsController.dispose();
    });
    super.dispose();
  }

  void _addSubjectEntry() {
    setState(() {
      _subjectEntries.add(
        SubjectEntry(
          code: 'Custom',
          name: 'New Subject',
          grade: 'O',
          credits: 0,
        ),
      );
    });
  }

  void _removeSubjectEntry(int index) {
    setState(() {
      _subjectEntries[index].creditsController.dispose();
      _subjectEntries.removeAt(index);
      _calculateGpa();
    });
  }

  void _calculateGpa() {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var entry in _subjectEntries) {
      final credits = double.tryParse(entry.creditsController.text) ?? 0;
      if (credits < 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Credits must be positive.')));
        setState(() => _calculatedGpa = 0.0);
        return;
      }
      totalPoints += (_gradePoints[entry.grade] ?? 0.0) * credits;
      totalCredits += credits;
    }
    setState(() {
      _calculatedGpa = totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
    });
  }

  void _addSemesterEntry() {
    setState(() {
      _semesterEntries.add(SemesterEntry(gpa: 0.0, credits: 0));
    });
  }

  void _removeSemesterEntry(int index) {
    setState(() {
      _semesterEntries[index].gpaController.dispose();
      _semesterEntries[index].creditsController.dispose();
      _semesterEntries.removeAt(index);
      _calculateCgpa();
    });
  }

  void _calculateCgpa() {
    double totalWeightedGpa = 0;
    double totalCredits = 0;
    for (var entry in _semesterEntries) {
      final gpa = double.tryParse(entry.gpaController.text) ?? 0.0;
      final credits = double.tryParse(entry.creditsController.text) ?? 0;
      if (gpa < 0 || gpa > 10 || credits < 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid GPA or credits.')));
        setState(() => _calculatedCgpa = 0.0);
        return;
      }
      totalWeightedGpa += gpa * credits;
      totalCredits += credits;
    }
    setState(() {
      _calculatedCgpa =
          totalCredits == 0 ? 0.0 : totalWeightedGpa / totalCredits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPA & CGPA Calculator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'GPA Calculator'), Tab(text: 'CGPA Calculator')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGpaCalculatorTab(), _buildCgpaCalculatorTab()],
      ),
    );
  }

  Widget _buildGpaCalculatorTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedDepartment,
            items:
                _departmentOptions
                    .map(
                      (String department) => DropdownMenuItem<String>(
                        value: department,
                        child: Text(
                          department,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDepartment = newValue;
                  _loadSubjectsForSelectedSemester();
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Select Department',
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGpaSemester,
            items:
                _semesterOptions
                    .map(
                      (String semester) => DropdownMenuItem<String>(
                        value: semester,
                        child: Text('Semester $semester'),
                      ),
                    )
                    .toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGpaSemester = newValue;
                  _loadSubjectsForSelectedSemester();
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Select Semester',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _subjectEntries.isEmpty &&
                    (_departmentSemesterSubjectsData[_selectedDepartment]?[_selectedGpaSemester]
                            ?.isEmpty ??
                        true)
                ? 'No subjects pre-filled for $_selectedDepartment - Semester $_selectedGpaSemester. Add subjects manually.'
                : 'Subjects for $_selectedDepartment - Semester $_selectedGpaSemester:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _subjectEntries.length,
            itemBuilder: (context, index) => _buildSubjectInputRow(index),
          ),
          SizedBox(height: 10),
          TextButton.icon(
            icon: Icon(Icons.add_circle_outline),
            label: Text('Add Subject'),
            onPressed: _addSubjectEntry,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _subjectEntries.isEmpty ? null : _calculateGpa,
            child: Text('Calculate GPA'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          SizedBox(height: 20),
          if (_calculatedGpa > 0 || _subjectEntries.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Calculated GPA:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _calculatedGpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectInputRow(int index) {
    final entry = _subjectEntries[index];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[${entry.code}] ${entry.name}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: entry.grade,
                    items:
                        _gradeOptions
                            .map(
                              (String grade) => DropdownMenuItem<String>(
                                value: grade,
                                child: Text(grade),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (String? newValue) =>
                            setState(() => entry.grade = newValue!),
                    decoration: InputDecoration(
                      labelText: 'Grade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.creditsController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Credits',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeSubjectEntry(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCgpaCalculatorTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter GPA and Total Credits for Each Semester:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _semesterEntries.length,
            itemBuilder: (context, index) => _buildSemesterInputRow(index),
          ),
          SizedBox(height: 10),
          TextButton.icon(
            icon: Icon(Icons.add_circle_outline),
            label: Text('Add Semester'),
            onPressed: _addSemesterEntry,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _semesterEntries.isEmpty ? null : _calculateCgpa,
            child: Text('Calculate CGPA'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          SizedBox(height: 20),
          if (_calculatedCgpa > 0 || _semesterEntries.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Calculated CGPA:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _calculatedCgpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSemesterInputRow(int index) {
    final entry = _semesterEntries[index];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: entry.gpaController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Semester GPA'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: entry.creditsController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Total Credits'),
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeSemesterEntry(index),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectEntry {
  String code;
  String name;
  String grade;
  TextEditingController creditsController;

  SubjectEntry({
    required this.code,
    required this.name,
    required this.grade,
    required double credits,
  }) : creditsController = TextEditingController(
         text: credits > 0 ? credits.toString() : (credits == 0 ? '0' : ''),
       );
}

class SemesterEntry {
  TextEditingController gpaController;
  TextEditingController creditsController;

  SemesterEntry({required double gpa, required double credits})
    : gpaController = TextEditingController(
        text: gpa > 0 ? gpa.toStringAsFixed(2) : '',
      ),
      creditsController = TextEditingController(
        text: credits > 0 ? credits.toString() : '',
      );
}

class SubjectData {
  final String code;
  final String name;
  final double credits;

  SubjectData({required this.code, required this.name, required this.credits});
}
