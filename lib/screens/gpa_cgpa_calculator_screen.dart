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
    'ME Computer Science Engineering', // Added ME CSE
  ];
  // Adjust semester options based on selected department later if needed,
  // for now, keep 8 as max, but ME CSE only uses 1-3 based on images.
  final List<String> _semesterOptions = List.generate(
    8, // Keep 8 for now, UI logic handles available semesters per dept
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
        ),
        SubjectData(
          code: 'CS3391',
          name: 'Object Oriented Programming',
          credits: 3,
        ),
        SubjectData(
          code: 'CD3281',
          name: 'Data Structures and Algorithms Laboratory',
          credits: 2,
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
        SubjectData(code: 'IT3401', name: 'Web Essentials', credits: 4),
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
        ),
        SubjectData(code: 'CS3551', name: 'Distributed Computing', credits: 3),
        SubjectData(
          code: 'CS3691',
          name: 'Embedded Systems and IoT',
          credits: 4,
        ),
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
        ),
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
        ),
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
      '1': [
        SubjectData(
          code: 'HS3151',
          name: 'Professional English - I',
          credits: 3,
        ), // Corrected code based on CSE/IT
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
        SubjectData(
          code: 'GE3172',
          name: 'English Laboratory',
          credits: 1,
        ), // Skill Based
        // IP3151 Induction Programme has 0 credits, excluded
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
          code: 'PH3251',
          name: 'Physics for Information Science',
          credits: 3,
        ), // Code from image
        SubjectData(
          code: 'BE3251',
          name: 'Basic Electrical and Electronics Engineering',
          credits: 3,
        ),
        SubjectData(code: 'AD3251', name: 'Data Structures Design', credits: 3),
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
          code: 'AD3271',
          name: 'Data Structures Design Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'GE3272',
          name: 'Communication Laboratory / Foreign Language',
          credits: 2,
        ), // Skill Based
        SubjectData(
          code: 'NCC1',
          name: 'NCC Credit Course Level 1',
          credits: 0,
        ), // Non-CGPA
      ],
      '3': [
        SubjectData(code: 'MA3354', name: 'Discrete Mathematics', credits: 4),
        SubjectData(
          code: 'CS3351',
          name: 'Digital Principles and Computer Organization',
          credits: 4,
        ),
        SubjectData(
          code: 'AD3391',
          name: 'Database Design and Management',
          credits: 3,
        ),
        SubjectData(
          code: 'AD3351',
          name: 'Design and Analysis of Algorithms',
          credits: 4,
        ),
        SubjectData(
          code: 'AD3301',
          name: 'Data Exploration and Visualization',
          credits: 4,
        ),
        SubjectData(
          code: 'AL3391',
          name: 'Artificial Intelligence',
          credits: 3,
        ),
        SubjectData(
          code: 'AD3381',
          name: 'Database Design and Management Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'AD3311',
          name: 'Artificial Intelligence Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'GE3361',
          name: 'Professional Development',
          credits: 1,
        ), // Skill Based
      ],
      '4': [
        SubjectData(
          code: 'MA3391',
          name: 'Probability and Statistics',
          credits: 4,
        ),
        SubjectData(code: 'AL3452', name: 'Operating Systems', credits: 4),
        SubjectData(code: 'AL3451', name: 'Machine Learning', credits: 3),
        SubjectData(
          code: 'AD3491',
          name: 'Fundamentals of Data Science and Analytics',
          credits: 3,
        ),
        SubjectData(code: 'CS3591', name: 'Computer Networks', credits: 4),
        SubjectData(
          code: 'GE3451',
          name: 'Environmental Sciences and Sustainability',
          credits: 2,
        ),
        SubjectData(
          code: 'AD3411',
          name: 'Data Science and Analytics Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'AD3461',
          name: 'Machine Learning Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'NCC2',
          name: 'NCC Credit Course Level 2',
          credits: 0,
        ), // Non-CGPA
      ],
      '5': [
        SubjectData(code: 'AD3501', name: 'Deep Learning', credits: 3),
        SubjectData(
          code: 'CW3551',
          name: 'Data and Information Security',
          credits: 3,
        ),
        SubjectData(code: 'CS3551', name: 'Distributed Computing', credits: 3),
        SubjectData(code: 'CCS334', name: 'Big Data Analytics', credits: 4),
        SubjectData(
          code: 'PE_AIDS_I',
          name: 'Professional Elective I',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_AIDS_II',
          name: 'Professional Elective II',
          credits: 3,
        ),
        SubjectData(
          code: 'AD3511',
          name: 'Deep Learning Laboratory',
          credits: 2,
        ),
        SubjectData(code: 'AD3512', name: 'Summer internship', credits: 2),
        SubjectData(
          code: 'MC_AIDS_I',
          name: 'Mandatory Course-I',
          credits: 0,
        ), // Non-credit
      ],
      '6': [
        SubjectData(
          code: 'CS3691',
          name: 'Embedded Systems and IoT',
          credits: 4,
        ),
        SubjectData(code: 'OE_AIDS_I', name: 'Open Elective – I', credits: 3),
        SubjectData(
          code: 'PE_AIDS_III',
          name: 'Professional Elective III',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_AIDS_IV',
          name: 'Professional Elective IV',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_AIDS_V',
          name: 'Professional Elective V',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_AIDS_VI',
          name: 'Professional Elective VI',
          credits: 3,
        ),
        SubjectData(
          code: 'MC_AIDS_II',
          name: 'Mandatory Course-II',
          credits: 0,
        ), // Non-credit
        SubjectData(
          code: 'NCC3',
          name: 'NCC Credit Course Level 3',
          credits: 0,
        ), // Non-CGPA
      ],
      '7': [
        // Assuming Sem 7/8 courses are taken in Sem 7 if no internship
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(
          code: 'MGMT_ELEC_AIDS',
          name: 'Elective - Management',
          credits: 3,
        ),
        SubjectData(code: 'OE_AIDS_II', name: 'Open Elective – II', credits: 3),
        SubjectData(
          code: 'OE_AIDS_III',
          name: 'Open Elective – III',
          credits: 3,
        ),
        SubjectData(code: 'OE_AIDS_IV', name: 'Open Elective – IV', credits: 3),
        // Internship note handled by user choice, not pre-filled data structure difference between 7 & 8
      ],
      '8': [
        // Assuming Sem 7/8 courses are taken in Sem 8 if internship in Sem 7
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(
          code: 'MGMT_ELEC_AIDS',
          name: 'Elective - Management',
          credits: 3,
        ),
        SubjectData(code: 'OE_AIDS_II', name: 'Open Elective – II', credits: 3),
        SubjectData(
          code: 'OE_AIDS_III',
          name: 'Open Elective – III',
          credits: 3,
        ),
        SubjectData(code: 'OE_AIDS_IV', name: 'Open Elective – IV', credits: 3),
        // Actual Sem 8 might just be a project, but data reflects course possibility
      ],
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
      '1': [
        SubjectData(
          code: 'HS3152',
          name: 'Professional English - I',
          credits: 3,
        ), // Code from image
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
        SubjectData(
          code: 'GE3172',
          name: 'English Laboratory',
          credits: 1,
        ), // Skill Based
        // IP3151 Induction Programme has 0 credits, excluded
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
          code: 'BM3251',
          name: 'Biosciences for Medical Engineering',
          credits: 3,
        ),
        SubjectData(
          code: 'BE3251',
          name: 'Basic Electrical and Electronics Engineering',
          credits: 3,
        ),
        SubjectData(code: 'BM3252', name: 'Medical Physics', credits: 3),
        SubjectData(code: 'GE3251', name: 'Engineering Graphics', credits: 4),
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
        SubjectData(code: 'BM3271', name: 'Biosciences Laboratory', credits: 2),
        SubjectData(
          code: 'GE3272',
          name: 'Communication Laboratory / Foreign Language',
          credits: 2,
        ), // Skill Based
        SubjectData(
          code: 'NCC1_BME',
          name: 'NCC Credit Course Level 1',
          credits: 0,
        ), // Non-CGPA
      ],
      '3': [
        SubjectData(
          code: 'MA3351',
          name: 'Transforms and Partial Differential Equations',
          credits: 4,
        ), // Code from image
        SubjectData(
          code: 'BM3353',
          name: 'Fundamentals of Electronic Devices and Circuits',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3301',
          name: 'Sensors and Measurements',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3352',
          name: 'Electric Circuit Analysis',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3351',
          name: 'Anatomy and Human Physiology',
          credits: 4,
        ),
        SubjectData(
          code: 'CS3391',
          name: 'Object oriented programming',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3361',
          name: 'Fundamentals of Electronic Devices and Circuits Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'BM3311',
          name: 'Sensors and Measurements Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'CS3381',
          name: 'Object oriented programming Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'GE3361',
          name: 'Professional Development',
          credits: 1,
        ), // Skill Based
      ],
      '4': [
        SubjectData(
          code: 'MA3355',
          name: 'Random Processes and Linear Algebra',
          credits: 4,
        ), // Code from image
        SubjectData(
          code: 'BM3491',
          name: 'Biomedical Instrumentation',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3402',
          name: 'Analog and Digital Integrated Circuits',
          credits: 3,
        ),
        SubjectData(code: 'BM3451', name: 'Bio Control Systems', credits: 3),
        SubjectData(code: 'BM3401', name: 'Signal Processing', credits: 4),
        SubjectData(
          code: 'GE3451',
          name: 'Environmental Sciences and Sustainability',
          credits: 2,
        ),
        SubjectData(
          code: 'BM3411',
          name: 'Biomedical Instrumentation Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'BM3412',
          name: 'Analog and Digital Integrated Circuits Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'NCC2_BME',
          name: 'NCC Credit Course Level 2',
          credits: 0,
        ), // Non-CGPA
      ],
      '5': [
        SubjectData(
          code: 'BM3551',
          name: 'Embedded Systems and IoMT',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3591',
          name: 'Diagnostic and Therapeutic Equipment',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_BME_I',
          name: 'Professional Elective I',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_BME_II',
          name: 'Professional Elective II',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_BME_III',
          name: 'Professional Elective III',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3562',
          name: 'Embedded systems and IOMT Laboratory',
          credits: 1.5,
        ),
        SubjectData(
          code: 'BM3561',
          name: 'Diagnostic and Therapeutic Equipment Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'MC_BME_I',
          name: 'Mandatory Course-I',
          credits: 0,
        ), // Non-credit
      ],
      '6': [
        SubjectData(
          code: 'CS3491',
          name: 'Artificial Intelligence and Machine Learning',
          credits: 4,
        ),
        SubjectData(
          code: 'BM3651',
          name: 'Fundamentals of Healthcare Analytics',
          credits: 3,
        ),
        SubjectData(
          code: 'BM3652',
          name: 'Medical Image Processing',
          credits: 4,
        ),
        SubjectData(code: 'OE_BME_I', name: 'Open Elective – I', credits: 3),
        SubjectData(
          code: 'PE_BME_IV',
          name: 'Professional Elective IV',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_BME_V',
          name: 'Professional Elective V',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_BME_VI',
          name: 'Professional Elective VI',
          credits: 3,
        ),
        SubjectData(
          code: 'MC_BME_II',
          name: 'Mandatory Course-II',
          credits: 0,
        ), // Non-credit
        SubjectData(
          code: 'NCC3_BME',
          name: 'NCC Credit Course Level 3',
          credits: 0,
        ), // Non-CGPA
      ],
      '7': [
        // Assuming Sem 7/8 courses are taken in Sem 7 if no internship
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(
          code: 'MGMT_ELEC_BME',
          name: 'Management – Elective',
          credits: 3,
        ),
        SubjectData(code: 'OE_BME_II', name: 'Open Elective – II', credits: 3),
        SubjectData(
          code: 'OE_BME_III',
          name: 'Open Elective – III',
          credits: 3,
        ),
        SubjectData(code: 'OE_BME_IV', name: 'Open Elective – IV', credits: 3),
        SubjectData(code: 'BM3711', name: 'Hospital Training', credits: 2),
      ],
      '8': [
        // Assuming Sem 7/8 courses are taken in Sem 8 if internship in Sem 7
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(
          code: 'MGMT_ELEC_BME',
          name: 'Management – Elective',
          credits: 3,
        ),
        SubjectData(code: 'OE_BME_II', name: 'Open Elective – II', credits: 3),
        SubjectData(
          code: 'OE_BME_III',
          name: 'Open Elective – III',
          credits: 3,
        ),
        SubjectData(code: 'OE_BME_IV', name: 'Open Elective – IV', credits: 3),
        // Hospital training likely done in Sem 7, Sem 8 might be project work (not explicitly shown)
      ],
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
        SubjectData(
          code: 'GE3172',
          name: 'English Laboratory',
          credits: 1,
        ), // Skill Based
        // IP3151 Induction Programme has 0 credits, excluded
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
          code: 'PH3251',
          name: 'Materials Science',
          credits: 3,
        ), // Code from image
        SubjectData(
          code: 'BE3251',
          name: 'Basic Electrical and Electronics Engineering',
          credits: 3,
        ),
        SubjectData(code: 'GE3251', name: 'Engineering Graphics', credits: 4),
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
          code: 'BE3271',
          name: 'Basic Electrical and Electronics Engineering Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'GE3272',
          name: 'Communication Laboratory / Foreign Language',
          credits: 2,
        ), // Skill Based
        SubjectData(
          code: 'NCC1_MECH',
          name: 'NCC Credit Course Level 1',
          credits: 0,
        ), // Non-CGPA
      ],
      '3': [
        SubjectData(
          code: 'MA3351',
          name: 'Transforms and Partial Differential Equations',
          credits: 4,
        ),
        SubjectData(code: 'ME3351', name: 'Engineering Mechanics', credits: 3),
        SubjectData(
          code: 'ME3391',
          name: 'Engineering Thermodynamics',
          credits: 3,
        ),
        SubjectData(
          code: 'CE3391',
          name: 'Fluid Mechanics and Machinery',
          credits: 4,
        ),
        SubjectData(
          code: 'ME3392',
          name: 'Engineering Materials and Metallurgy',
          credits: 3,
        ),
        SubjectData(
          code: 'ME3393',
          name: 'Manufacturing Processes',
          credits: 3,
        ),
        SubjectData(
          code: 'ME3381',
          name: 'Computer Aided Machine Drawing',
          credits: 2,
        ),
        SubjectData(
          code: 'ME3382',
          name: 'Manufacturing Technology Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'GE3361',
          name: 'Professional Development',
          credits: 1,
        ), // Skill Based
      ],
      '4': [
        SubjectData(code: 'ME3491', name: 'Theory of Machines', credits: 3),
        SubjectData(code: 'ME3451', name: 'Thermal Engineering', credits: 4),
        SubjectData(
          code: 'ME3492',
          name: 'Hydraulics and Pneumatics',
          credits: 3,
        ),
        SubjectData(
          code: 'ME3493',
          name: 'Manufacturing Technology',
          credits: 3,
        ),
        SubjectData(code: 'CE3491', name: 'Strength of Materials', credits: 3),
        SubjectData(
          code: 'GE3451',
          name: 'Environmental Sciences and Sustainability',
          credits: 2,
        ),
        SubjectData(
          code: 'CE3481',
          name: 'Strength of Materials and Fluid Machinery Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'ME3461',
          name: 'Thermal Engineering Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'NCC2_MECH',
          name: 'NCC Credit Course Level 2',
          credits: 0,
        ), // Non-CGPA
      ],
      '5': [
        SubjectData(
          code: 'ME3591',
          name: 'Design of Machine Elements',
          credits: 4,
        ),
        SubjectData(
          code: 'ME3592',
          name: 'Metrology and Measurements',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECH_I',
          name: 'Professional Elective I',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECH_II',
          name: 'Professional Elective II',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECH_III',
          name: 'Professional Elective III',
          credits: 3,
        ),
        SubjectData(
          code: 'ME3511',
          name: 'Summer Internship',
          credits: 1,
        ), // Note: 2 weeks, 1 credit
        SubjectData(
          code: 'ME3581',
          name: 'Metrology and Dynamics Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'MC_MECH_I',
          name: 'Mandatory Course-I',
          credits: 0,
        ), // Non-credit
      ],
      '6': [
        SubjectData(code: 'ME3691', name: 'Heat and Mass Transfer', credits: 4),
        SubjectData(
          code: 'PE_MECH_IV',
          name: 'Professional Elective IV',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECH_V',
          name: 'Professional Elective V',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECH_VI',
          name: 'Professional Elective VI',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECH_VII',
          name: 'Professional Elective VII',
          credits: 3,
        ),
        SubjectData(code: 'OE_MECH_I', name: 'Open Elective – I', credits: 3),
        SubjectData(code: 'ME3681', name: 'CAD/CAM Laboratory', credits: 2),
        SubjectData(
          code: 'ME3682',
          name: 'Heat Transfer Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'MC_MECH_II',
          name: 'Mandatory Course-II',
          credits: 0,
        ), // Non-credit
        SubjectData(
          code: 'NCC3_MECH',
          name: 'NCC Credit Course Level 3',
          credits: 0,
        ), // Non-CGPA
      ],
      '7': [
        // Assuming Sem 7/8 courses are taken in Sem 7 if no internship
        SubjectData(code: 'ME3791', name: 'Mechatronics and IoT', credits: 3),
        SubjectData(
          code: 'ME3792',
          name: 'Computer Integrated Manufacturing',
          credits: 3,
        ),
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(code: 'GE3792', name: 'Industrial Management', credits: 3),
        SubjectData(code: 'OE_MECH_II', name: 'Open Elective – II', credits: 3),
        SubjectData(
          code: 'OE_MECH_III',
          name: 'Open Elective – III',
          credits: 3,
        ),
        SubjectData(code: 'OE_MECH_IV', name: 'Open Elective – IV', credits: 3),
        SubjectData(
          code: 'ME3781',
          name: 'Mechatronics and IoT Laboratory',
          credits: 2,
        ),
        SubjectData(
          code: 'ME3711',
          name: 'Summer Internship',
          credits: 1,
        ), // Note: 1 credit
      ],
      '8': [
        // Assuming Sem 7/8 courses are taken in Sem 8 if internship in Sem 7
        SubjectData(code: 'ME3791', name: 'Mechatronics and IoT', credits: 3),
        SubjectData(
          code: 'ME3792',
          name: 'Computer Integrated Manufacturing',
          credits: 3,
        ),
        SubjectData(
          code: 'GE3791',
          name: 'Human Values and Ethics',
          credits: 2,
        ),
        SubjectData(code: 'GE3792', name: 'Industrial Management', credits: 3),
        SubjectData(code: 'OE_MECH_II', name: 'Open Elective – II', credits: 3),
        SubjectData(
          code: 'OE_MECH_III',
          name: 'Open Elective – III',
          credits: 3,
        ),
        SubjectData(code: 'OE_MECH_IV', name: 'Open Elective – IV', credits: 3),
        SubjectData(
          code: 'ME3781',
          name: 'Mechatronics and IoT Laboratory',
          credits: 2,
        ),
        // Summer internship likely done in Sem 7, Sem 8 might be project work (not explicitly shown)
      ],
    },
    'ME Computer Science Engineering': {
      '1': [
        SubjectData(
          code: 'MA4151',
          name:
              'Applied Probability and Statistics for Computer Science Engineers',
          credits: 4,
        ),
        SubjectData(
          code: 'RM4151',
          name: 'Research Methodology and IPR',
          credits: 2,
        ),
        SubjectData(
          code: 'CP4151',
          name: 'Advanced Data Structures and Algorithms',
          credits: 3,
        ),
        SubjectData(code: 'CP4152', name: 'Database Practices', credits: 3),
        SubjectData(code: 'CP4153', name: 'Network Technologies', credits: 3),
        SubjectData(
          code: 'CP4154',
          name: 'Principles of Programming Languages',
          credits: 3,
        ),
        SubjectData(
          code: 'AC_I',
          name: 'Audit Course – I',
          credits: 0,
        ), // Audit Course
        SubjectData(
          code: 'CP4161',
          name: 'Advanced Data Structures and Algorithms Laboratory',
          credits: 2,
        ),
      ],
      '2': [
        SubjectData(code: 'CP4291', name: 'Internet of Things', credits: 4),
        SubjectData(
          code: 'CP4292',
          name: 'Multicore Architecture and Programming',
          credits: 4,
        ),
        SubjectData(code: 'CP4252', name: 'Machine Learning', credits: 4),
        SubjectData(
          code: 'SE4151',
          name: 'Advanced Software Engineering',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECSE_I',
          name: 'Professional Elective I',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECSE_II',
          name: 'Professional Elective II',
          credits: 3,
        ),
        SubjectData(
          code: 'AC_II',
          name: 'Audit Course – II',
          credits: 0,
        ), // Audit Course
        SubjectData(
          code: 'CP4211',
          name: 'Term Paper Writing and seminar',
          credits: 1,
        ),
        SubjectData(
          code: 'CP4212',
          name: 'Software Engineering Laboratory',
          credits: 1,
        ),
      ],
      '3': [
        SubjectData(code: 'CP4391', name: 'Security Practices', credits: 3),
        SubjectData(
          code: 'PE_MECSE_III',
          name: 'Professional Elective III',
          credits: 3,
        ),
        SubjectData(
          code: 'PE_MECSE_IV',
          name: 'Professional Elective IV',
          credits: 4,
        ),
        SubjectData(code: 'OE_MECSE', name: 'Open Elective', credits: 3),
        SubjectData(code: 'CP4311', name: 'Project Work I', credits: 6),
      ],
      // Semester 4 is typically Project Work II for ME, not shown in images.
      '4': [
        SubjectData(
          code: 'PROJECT_II',
          name: 'Project Work II',
          credits: 12,
        ), // Placeholder for typical Sem 4 ME Project
      ],
      '5': [], // Keep empty for consistency
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
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      // AppBar will use appBarTheme from main.dart
      appBar: AppBar(
        title: Text('GPA & CGPA Calculator'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary, // Active tab text color
          unselectedLabelColor:
              theme.textTheme.bodyMedium?.color, // Inactive tab text color
          indicatorColor: theme.colorScheme.primary, // Indicator color
          tabs: [Tab(text: 'GPA Calculator'), Tab(text: 'CGPA Calculator')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGpaCalculatorTab(theme),
          _buildCgpaCalculatorTab(theme),
        ],
      ),
    );
  }

  Widget _buildGpaCalculatorTab(ThemeData theme) {
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
            ), // Uses global InputDecorationTheme
            dropdownColor: theme.cardColor,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              
            ),
            iconEnabledColor: theme.iconTheme.color,
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
            ), // Uses global InputDecorationTheme
            dropdownColor: theme.cardColor,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              
            ),
            iconEnabledColor: theme.iconTheme.color,
          ),
          SizedBox(height: 16),
          Text(
            _subjectEntries.isEmpty &&
                    (_departmentSemesterSubjectsData[_selectedDepartment]?[_selectedGpaSemester]
                            ?.isEmpty ??
                        true)
                ? 'No subjects pre-filled for $_selectedDepartment - Semester $_selectedGpaSemester. Add subjects manually.'
                : 'Subjects for $_selectedDepartment - Semester $_selectedGpaSemester:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _subjectEntries.length,
            itemBuilder:
                (context, index) => _buildSubjectInputRow(index, theme),
          ),
          SizedBox(height: 10),
          TextButton.icon(
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Add Subject',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onPressed: _addSubjectEntry,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            // Will use global ElevatedButtonTheme
            onPressed: _subjectEntries.isEmpty ? null : _calculateGpa,
            child: Text('Calculate GPA'),
          ),
          SizedBox(height: 20),
          if (_calculatedGpa > 0 || _subjectEntries.isNotEmpty)
            Card(
              // Will use global CardTheme
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Calculated GPA:', style: theme.textTheme.titleLarge),
                    SizedBox(height: 8),
                    Text(
                      _calculatedGpa.toStringAsFixed(2),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSubjectInputRow(int index, ThemeData theme) {
    final entry = _subjectEntries[index];
    return Card(
      // Will use global CardTheme
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[${entry.code}] ${entry.name}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    ), // Uses global InputDecorationTheme
                    dropdownColor: theme.cardColor,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      
                    ),
                    iconEnabledColor: theme.iconTheme.color,
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
                    ), // Uses global InputDecorationTheme
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      
                    ),
                    cursorColor: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _removeSubjectEntry(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCgpaCalculatorTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter GPA and Total Credits for Each Semester:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _semesterEntries.length,
            itemBuilder:
                (context, index) => _buildSemesterInputRow(index, theme),
          ),
          SizedBox(height: 10),
          TextButton.icon(
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Add Semester',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onPressed: _addSemesterEntry,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            // Will use global ElevatedButtonTheme
            onPressed: _semesterEntries.isEmpty ? null : _calculateCgpa,
            child: Text('Calculate CGPA'),
          ),
          SizedBox(height: 20),
          if (_calculatedCgpa > 0 || _semesterEntries.isNotEmpty)
            Card(
              // Will use global CardTheme
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Calculated CGPA:', style: theme.textTheme.titleLarge),
                    SizedBox(height: 8),
                    Text(
                      _calculatedCgpa.toStringAsFixed(2),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSemesterInputRow(int index, ThemeData theme) {
    final entry = _semesterEntries[index];
    return Card(
      // Will use global CardTheme
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
                decoration: InputDecoration(
                  labelText: 'Semester GPA',
                ), // Uses global InputDecorationTheme
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  
                ),
                cursorColor: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: entry.creditsController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total Credits',
                ), // Uses global InputDecorationTheme
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  
                ),
                cursorColor: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.remove_circle, color: theme.colorScheme.error),
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
