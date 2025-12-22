import 'package:flutter/material.dart';

class StudentMark {
  final String name;
  final String rollNumber;
  final String subject;
  final int marks;

  StudentMark({
    required this.name,
    required this.rollNumber,
    required this.subject,
    required this.marks,
  });
}

class ExamsScreen extends StatefulWidget {
  final String department;
  final int semester;

  const ExamsScreen({
    super.key,
    required this.department,
    required this.semester,
  });

  @override
  _ExamsScreenState createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String? selectedAssessment;
  List<StudentMark> allStudentMarks = [];
  List<StudentMark> filteredMarks = [];
  Map<String, List<StudentMark>> studentMarksByRollNumber = {};
  List<String> availableRegistrations = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedRegistration;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _loadAllMarks() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // This is where you would load actual student data based on the selections
    if (selectedAssessment == 'Internal Assessment 1') {
      allStudentMarks = [
        // CSE A Students - Real data from provided table
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Theory of Computation",
          marks: 68,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Database Management Systems",
          marks: 70,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Operating Systems",
          marks: 62,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Artificial Intelligence",
          marks: 70,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Algorithm",
          marks: 80,
        ),

        StudentMark(
          name: "ABEL C JOY",
          rollNumber: "210823104002",
          subject: "Theory of Computation",
          marks: 82,
        ),
        StudentMark(
          name: "ABEL C JOY",
          rollNumber: "210823104002",
          subject: "Database Management Systems",
          marks: 54,
        ),
        StudentMark(
          name: "ABEL C JOY",
          rollNumber: "210823104002",
          subject: "Operating Systems",
          marks: 82,
        ),
        StudentMark(
          name: "ABEL C JOY",
          rollNumber: "210823104002",
          subject: "Artificial Intelligence",
          marks: 62,
        ),
        StudentMark(
          name: "ABEL C JOY",
          rollNumber: "210823104002",
          subject: "Algorithm",
          marks: 90,
        ),

        StudentMark(
          name: "ABINAYA T",
          rollNumber: "210823104003",
          subject: "Theory of Computation",
          marks: 90,
        ),
        StudentMark(
          name: "ABINAYA T",
          rollNumber: "210823104003",
          subject: "Database Management Systems",
          marks: 58,
        ),
        StudentMark(
          name: "ABINAYA T",
          rollNumber: "210823104003",
          subject: "Operating Systems",
          marks: 76,
        ),
        StudentMark(
          name: "ABINAYA T",
          rollNumber: "210823104003",
          subject: "Artificial Intelligence",
          marks: 66,
        ),
        StudentMark(
          name: "ABINAYA T",
          rollNumber: "210823104003",
          subject: "Algorithm",
          marks: 65,
        ),

        StudentMark(
          name: "ABISHA JEBAMANI K",
          rollNumber: "210823104004",
          subject: "Theory of Computation",
          marks: 84,
        ),
        StudentMark(
          name: "ABISHA JEBAMANI K",
          rollNumber: "210823104004",
          subject: "Database Management Systems",
          marks: 90,
        ),
        StudentMark(
          name: "ABISHA JEBAMANI K",
          rollNumber: "210823104004",
          subject: "Operating Systems",
          marks: 82,
        ),
        StudentMark(
          name: "ABISHA JEBAMANI K",
          rollNumber: "210823104004",
          subject: "Artificial Intelligence",
          marks: 66,
        ),
        StudentMark(
          name: "ABISHA JEBAMANI K",
          rollNumber: "210823104004",
          subject: "Algorithm",
          marks: 68,
        ),

        StudentMark(
          name: "ABISHEK PAULSON S",
          rollNumber: "210823104005",
          subject: "Theory of Computation",
          marks: 24,
        ),
        StudentMark(
          name: "ABISHEK PAULSON S",
          rollNumber: "210823104005",
          subject: "Database Management Systems",
          marks: 50,
        ),
        StudentMark(
          name: "ABISHEK PAULSON S",
          rollNumber: "210823104005",
          subject: "Operating Systems",
          marks: 76,
        ),
        StudentMark(
          name: "ABISHEK PAULSON S",
          rollNumber: "210823104005",
          subject: "Artificial Intelligence",
          marks: 40,
        ),
        StudentMark(
          name: "ABISHEK PAULSON S",
          rollNumber: "210823104005",
          subject: "Algorithm",
          marks: 55,
        ),

        StudentMark(
          name: "ABY ROSY M",
          rollNumber: "210823104006",
          subject: "Theory of Computation",
          marks: 80,
        ),
        StudentMark(
          name: "ABY ROSY M",
          rollNumber: "210823104006",
          subject: "Database Management Systems",
          marks: 88,
        ),
        StudentMark(
          name: "ABY ROSY M",
          rollNumber: "210823104006",
          subject: "Operating Systems",
          marks: 84,
        ),
        StudentMark(
          name: "ABY ROSY M",
          rollNumber: "210823104006",
          subject: "Artificial Intelligence",
          marks: 90,
        ),
        StudentMark(
          name: "ABY ROSY M",
          rollNumber: "210823104006",
          subject: "Algorithm",
          marks: 86,
        ),

        StudentMark(
          name: "AKSHAYA PRABHA M (H)",
          rollNumber: "210823104007",
          subject: "Theory of Computation",
          marks: 84,
        ),
        StudentMark(
          name: "AKSHAYA PRABHA M (H)",
          rollNumber: "210823104007",
          subject: "Database Management Systems",
          marks: 92,
        ),
        StudentMark(
          name: "AKSHAYA PRABHA M (H)",
          rollNumber: "210823104007",
          subject: "Operating Systems",
          marks: 30,
        ),
        StudentMark(
          name: "AKSHAYA PRABHA M (H)",
          rollNumber: "210823104007",
          subject: "Artificial Intelligence",
          marks: 94,
        ),
        StudentMark(
          name: "AKSHAYA PRABHA M (H)",
          rollNumber: "210823104007",
          subject: "Algorithm",
          marks: 76,
        ),

        StudentMark(
          name: "ANGELIN MARY S (H)",
          rollNumber: "210823104008",
          subject: "Theory of Computation",
          marks: 52,
        ),
        StudentMark(
          name: "ANGELIN MARY S (H)",
          rollNumber: "210823104008",
          subject: "Database Management Systems",
          marks: 80,
        ),
        StudentMark(
          name: "ANGELIN MARY S (H)",
          rollNumber: "210823104008",
          subject: "Operating Systems",
          marks: 84,
        ),
        StudentMark(
          name: "ANGELIN MARY S (H)",
          rollNumber: "210823104008",
          subject: "Artificial Intelligence",
          marks: 66,
        ),
        StudentMark(
          name: "ANGELIN MARY S (H)",
          rollNumber: "210823104008",
          subject: "Algorithm",
          marks: 84,
        ),

        StudentMark(
          name: "ANISHA SWEETY J",
          rollNumber: "210823104009",
          subject: "Theory of Computation",
          marks: 50,
        ),
        StudentMark(
          name: "ANISHA SWEETY J",
          rollNumber: "210823104009",
          subject: "Database Management Systems",
          marks: 80,
        ),
        StudentMark(
          name: "ANISHA SWEETY J",
          rollNumber: "210823104009",
          subject: "Operating Systems",
          marks: 78,
        ),
        StudentMark(
          name: "ANISHA SWEETY J",
          rollNumber: "210823104009",
          subject: "Artificial Intelligence",
          marks: 76,
        ),
        StudentMark(
          name: "ANISHA SWEETY J",
          rollNumber: "210823104009",
          subject: "Algorithm",
          marks: 71,
        ),

        StudentMark(
          name: "ANNESHARON A S",
          rollNumber: "210823104010",
          subject: "Theory of Computation",
          marks: 24,
        ),
        StudentMark(
          name: "ANNESHARON A S",
          rollNumber: "210823104010",
          subject: "Database Management Systems",
          marks: 52,
        ),
        StudentMark(
          name: "ANNESHARON A S",
          rollNumber: "210823104010",
          subject: "Operating Systems",
          marks: 72,
        ),
        StudentMark(
          name: "ANNESHARON A S",
          rollNumber: "210823104010",
          subject: "Artificial Intelligence",
          marks: 0,
        ),
        StudentMark(
          name: "ANNESHARON A S",
          rollNumber: "210823104010",
          subject: "Algorithm",
          marks: 45,
        ),

        StudentMark(
          name: "ANNIE DORAH ABEL",
          rollNumber: "210823104011",
          subject: "Theory of Computation",
          marks: 36,
        ),
        StudentMark(
          name: "ANNIE DORAH ABEL",
          rollNumber: "210823104011",
          subject: "Database Management Systems",
          marks: 28,
        ),
        StudentMark(
          name: "ANNIE DORAH ABEL",
          rollNumber: "210823104011",
          subject: "Operating Systems",
          marks: 82,
        ),
        StudentMark(
          name: "ANNIE DORAH ABEL",
          rollNumber: "210823104011",
          subject: "Artificial Intelligence",
          marks: 0,
        ),
        StudentMark(
          name: "ANNIE DORAH ABEL",
          rollNumber: "210823104011",
          subject: "Algorithm",
          marks: 0,
        ),

        StudentMark(
          name: "ANTONY MELVIN T",
          rollNumber: "210823104012",
          subject: "Theory of Computation",
          marks: 50,
        ),
        StudentMark(
          name: "ANTONY MELVIN T",
          rollNumber: "210823104012",
          subject: "Database Management Systems",
          marks: 52,
        ),
        StudentMark(
          name: "ANTONY MELVIN T",
          rollNumber: "210823104012",
          subject: "Operating Systems",
          marks: 76,
        ),
        StudentMark(
          name: "ANTONY MELVIN T",
          rollNumber: "210823104012",
          subject: "Artificial Intelligence",
          marks: 72,
        ),
        StudentMark(
          name: "ANTONY MELVIN T",
          rollNumber: "210823104012",
          subject: "Algorithm",
          marks: 31,
        ),

        StudentMark(
          name: "ARPUTHA STEPHIN A (H)",
          rollNumber: "210823104013",
          subject: "Theory of Computation",
          marks: 36,
        ),
        StudentMark(
          name: "ARPUTHA STEPHIN A (H)",
          rollNumber: "210823104013",
          subject: "Database Management Systems",
          marks: 56,
        ),
        StudentMark(
          name: "ARPUTHA STEPHIN A (H)",
          rollNumber: "210823104013",
          subject: "Operating Systems",
          marks: 76,
        ),
        StudentMark(
          name: "ARPUTHA STEPHIN A (H)",
          rollNumber: "210823104013",
          subject: "Artificial Intelligence",
          marks: 8,
        ),
        StudentMark(
          name: "ARPUTHA STEPHIN A (H)",
          rollNumber: "210823104013",
          subject: "Algorithm",
          marks: 63,
        ),

        StudentMark(
          name: "ARTHI M",
          rollNumber: "210823104014",
          subject: "Theory of Computation",
          marks: 50,
        ),
        StudentMark(
          name: "ARTHI M",
          rollNumber: "210823104014",
          subject: "Database Management Systems",
          marks: 28,
        ),
        StudentMark(
          name: "ARTHI M",
          rollNumber: "210823104014",
          subject: "Operating Systems",
          marks: 30,
        ),
        StudentMark(
          name: "ARTHI M",
          rollNumber: "210823104014",
          subject: "Artificial Intelligence",
          marks: 4,
        ),
        StudentMark(
          name: "ARTHI M",
          rollNumber: "210823104014",
          subject: "Algorithm",
          marks: 26,
        ),

        StudentMark(
          name: "ARUNACHALAM R",
          rollNumber: "210823104015",
          subject: "Theory of Computation",
          marks: 24,
        ),
        StudentMark(
          name: "ARUNACHALAM R",
          rollNumber: "210823104015",
          subject: "Database Management Systems",
          marks: 52,
        ),
        StudentMark(
          name: "ARUNACHALAM R",
          rollNumber: "210823104015",
          subject: "Operating Systems",
          marks: 62,
        ),
        StudentMark(
          name: "ARUNACHALAM R",
          rollNumber: "210823104015",
          subject: "Artificial Intelligence",
          marks: 30,
        ),
        StudentMark(
          name: "ARUNACHALAM R",
          rollNumber: "210823104015",
          subject: "Algorithm",
          marks: 50,
        ),

        StudentMark(
          name: "ASBOURN JOEL I",
          rollNumber: "210823104016",
          subject: "Theory of Computation",
          marks: 58,
        ),
        StudentMark(
          name: "ASBOURN JOEL I",
          rollNumber: "210823104016",
          subject: "Database Management Systems",
          marks: 78,
        ),
        StudentMark(
          name: "ASBOURN JOEL I",
          rollNumber: "210823104016",
          subject: "Operating Systems",
          marks: 68,
        ),
        StudentMark(
          name: "ASBOURN JOEL I",
          rollNumber: "210823104016",
          subject: "Artificial Intelligence",
          marks: 56,
        ),
        StudentMark(
          name: "ASBOURN JOEL I",
          rollNumber: "210823104016",
          subject: "Algorithm",
          marks: 78,
        ),

        StudentMark(
          name: "ASLIN BRIMA P H (H)",
          rollNumber: "210823104017",
          subject: "Theory of Computation",
          marks: 52,
        ),
        StudentMark(
          name: "ASLIN BRIMA P H (H)",
          rollNumber: "210823104017",
          subject: "Database Management Systems",
          marks: 58,
        ),
        StudentMark(
          name: "ASLIN BRIMA P H (H)",
          rollNumber: "210823104017",
          subject: "Operating Systems",
          marks: 74,
        ),
        StudentMark(
          name: "ASLIN BRIMA P H (H)",
          rollNumber: "210823104017",
          subject: "Artificial Intelligence",
          marks: 56,
        ),
        StudentMark(
          name: "ASLIN BRIMA P H (H)",
          rollNumber: "210823104017",
          subject: "Algorithm",
          marks: 80,
        ),

        StudentMark(
          name: "ASWITHA K",
          rollNumber: "210823104018",
          subject: "Theory of Computation",
          marks: 90,
        ),
        StudentMark(
          name: "ASWITHA K",
          rollNumber: "210823104018",
          subject: "Database Management Systems",
          marks: 92,
        ),
        StudentMark(
          name: "ASWITHA K",
          rollNumber: "210823104018",
          subject: "Operating Systems",
          marks: 80,
        ),
        StudentMark(
          name: "ASWITHA K",
          rollNumber: "210823104018",
          subject: "Artificial Intelligence",
          marks: 84,
        ),
        StudentMark(
          name: "ASWITHA K",
          rollNumber: "210823104018",
          subject: "Algorithm",
          marks: 92,
        ),

        StudentMark(
          name: "BABY SHALINI K",
          rollNumber: "210823104019",
          subject: "Theory of Computation",
          marks: 0,
        ),
        StudentMark(
          name: "BABY SHALINI K",
          rollNumber: "210823104019",
          subject: "Database Management Systems",
          marks: 0,
        ),
        StudentMark(
          name: "BABY SHALINI K",
          rollNumber: "210823104019",
          subject: "Operating Systems",
          marks: 0,
        ),
        StudentMark(
          name: "BABY SHALINI K",
          rollNumber: "210823104019",
          subject: "Artificial Intelligence",
          marks: 0,
        ),
        StudentMark(
          name: "BABY SHALINI K",
          rollNumber: "210823104019",
          subject: "Algorithm",
          marks: 0,
        ),

        StudentMark(
          name: "BALAMURUGAN M",
          rollNumber: "210823104020",
          subject: "Theory of Computation",
          marks: 86,
        ),
        StudentMark(
          name: "BALAMURUGAN M",
          rollNumber: "210823104020",
          subject: "Database Management Systems",
          marks: 90,
        ),
        StudentMark(
          name: "BALAMURUGAN M",
          rollNumber: "210823104020",
          subject: "Operating Systems",
          marks: 82,
        ),
        StudentMark(
          name: "BALAMURUGAN M",
          rollNumber: "210823104020",
          subject: "Artificial Intelligence",
          marks: 16,
        ),
        StudentMark(
          name: "BALAMURUGAN M",
          rollNumber: "210823104020",
          subject: "Algorithm",
          marks: 86,
        ),

        StudentMark(
          name: "BLESSING RAJA P (H)",
          rollNumber: "210823104021",
          subject: "Theory of Computation",
          marks: 50,
        ),
        StudentMark(
          name: "BLESSING RAJA P (H)",
          rollNumber: "210823104021",
          subject: "Database Management Systems",
          marks: 66,
        ),
        StudentMark(
          name: "BLESSING RAJA P (H)",
          rollNumber: "210823104021",
          subject: "Operating Systems",
          marks: 66,
        ),
        StudentMark(
          name: "BLESSING RAJA P (H)",
          rollNumber: "210823104021",
          subject: "Artificial Intelligence",
          marks: 56,
        ),
        StudentMark(
          name: "BLESSING RAJA P (H)",
          rollNumber: "210823104021",
          subject: "Algorithm",
          marks: 50,
        ),

        StudentMark(
          name: "BOAZ K",
          rollNumber: "210823104022",
          subject: "Theory of Computation",
          marks: 38,
        ),
        StudentMark(
          name: "BOAZ K",
          rollNumber: "210823104022",
          subject: "Database Management Systems",
          marks: 86,
        ),
        StudentMark(
          name: "BOAZ K",
          rollNumber: "210823104022",
          subject: "Operating Systems",
          marks: 76,
        ),
        StudentMark(
          name: "BOAZ K",
          rollNumber: "210823104022",
          subject: "Artificial Intelligence",
          marks: 24,
        ),
        StudentMark(
          name: "BOAZ K",
          rollNumber: "210823104022",
          subject: "Algorithm",
          marks: 55,
        ),

        StudentMark(
          name: "CHANDRA MOHAN C (H)",
          rollNumber: "210823104023",
          subject: "Theory of Computation",
          marks: 50,
        ),
        StudentMark(
          name: "CHANDRA MOHAN C (H)",
          rollNumber: "210823104023",
          subject: "Database Management Systems",
          marks: 60,
        ),
        StudentMark(
          name: "CHANDRA MOHAN C (H)",
          rollNumber: "210823104023",
          subject: "Operating Systems",
          marks: 70,
        ),
        StudentMark(
          name: "CHANDRA MOHAN C (H)",
          rollNumber: "210823104023",
          subject: "Artificial Intelligence",
          marks: 50,
        ),
        StudentMark(
          name: "CHANDRA MOHAN C (H)",
          rollNumber: "210823104023",
          subject: "Algorithm",
          marks: 54,
        ),

        StudentMark(
          name: "CHRISTYBAI JENCY K",
          rollNumber: "210823104024",
          subject: "Theory of Computation",
          marks: 90,
        ),
        StudentMark(
          name: "CHRISTYBAI JENCY K",
          rollNumber: "210823104024",
          subject: "Database Management Systems",
          marks: 60,
        ),
        StudentMark(
          name: "CHRISTYBAI JENCY K",
          rollNumber: "210823104024",
          subject: "Operating Systems",
          marks: 80,
        ),
        StudentMark(
          name: "CHRISTYBAI JENCY K",
          rollNumber: "210823104024",
          subject: "Artificial Intelligence",
          marks: 78,
        ),
        StudentMark(
          name: "CHRISTYBAI JENCY K",
          rollNumber: "210823104024",
          subject: "Algorithm",
          marks: 84,
        ),

        StudentMark(
          name: "DANIYEL K L (H)",
          rollNumber: "210823104025",
          subject: "Theory of Computation",
          marks: 0,
        ),
        StudentMark(
          name: "DANIYEL K L (H)",
          rollNumber: "210823104025",
          subject: "Database Management Systems",
          marks: 52,
        ),
        StudentMark(
          name: "DANIYEL K L (H)",
          rollNumber: "210823104025",
          subject: "Operating Systems",
          marks: 54,
        ),
        StudentMark(
          name: "DANIYEL K L (H)",
          rollNumber: "210823104025",
          subject: "Artificial Intelligence",
          marks: 38,
        ),
        StudentMark(
          name: "DANIYEL K L (H)",
          rollNumber: "210823104025",
          subject: "Algorithm",
          marks: 10,
        ),

        StudentMark(
          name: "DEEPA G C",
          rollNumber: "210823104026",
          subject: "Theory of Computation",
          marks: 60,
        ),
        StudentMark(
          name: "DEEPA G C",
          rollNumber: "210823104026",
          subject: "Database Management Systems",
          marks: 70,
        ),
        StudentMark(
          name: "DEEPA G C",
          rollNumber: "210823104026",
          subject: "Operating Systems",
          marks: 74,
        ),
        StudentMark(
          name: "DEEPA G C",
          rollNumber: "210823104026",
          subject: "Artificial Intelligence",
          marks: 74,
        ),
        StudentMark(
          name: "DEEPA G C",
          rollNumber: "210823104026",
          subject: "Algorithm",
          marks: 50,
        ),

        StudentMark(
          name: "DEEPAK S",
          rollNumber: "210823104027",
          subject: "Theory of Computation",
          marks: 74,
        ),
        StudentMark(
          name: "DEEPAK S",
          rollNumber: "210823104027",
          subject: "Database Management Systems",
          marks: 72,
        ),
        StudentMark(
          name: "DEEPAK S",
          rollNumber: "210823104027",
          subject: "Operating Systems",
          marks: 56,
        ),
        StudentMark(
          name: "DEEPAK S",
          rollNumber: "210823104027",
          subject: "Artificial Intelligence",
          marks: 66,
        ),
        StudentMark(
          name: "DEEPAK S",
          rollNumber: "210823104027",
          subject: "Algorithm",
          marks: 53,
        ),

        StudentMark(
          name: "DHANUSH A",
          rollNumber: "210823104028",
          subject: "Theory of Computation",
          marks: 60,
        ),
        StudentMark(
          name: "DHANUSH A",
          rollNumber: "210823104028",
          subject: "Database Management Systems",
          marks: 56,
        ),
        StudentMark(
          name: "DHANUSH A",
          rollNumber: "210823104028",
          subject: "Operating Systems",
          marks: 76,
        ),
        StudentMark(
          name: "DHANUSH A",
          rollNumber: "210823104028",
          subject: "Artificial Intelligence",
          marks: 80,
        ),
        StudentMark(
          name: "DHANUSH A",
          rollNumber: "210823104028",
          subject: "Algorithm",
          marks: 70,
        ),

        StudentMark(
          name: "DHARNESH S",
          rollNumber: "210823104029",
          subject: "Theory of Computation",
          marks: 50,
        ),
        StudentMark(
          name: "DHARNESH S",
          rollNumber: "210823104029",
          subject: "Database Management Systems",
          marks: 76,
        ),
        StudentMark(
          name: "DHARNESH S",
          rollNumber: "210823104029",
          subject: "Operating Systems",
          marks: 68,
        ),
        StudentMark(
          name: "DHARNESH S",
          rollNumber: "210823104029",
          subject: "Artificial Intelligence",
          marks: 20,
        ),
        StudentMark(
          name: "DHARNESH S",
          rollNumber: "210823104029",
          subject: "Algorithm",
          marks: 62,
        ),

        StudentMark(
          name: "DHARSHANA R",
          rollNumber: "210823104030",
          subject: "Theory of Computation",
          marks: 64,
        ),
        StudentMark(
          name: "DHARSHANA R",
          rollNumber: "210823104030",
          subject: "Database Management Systems",
          marks: 82,
        ),
        StudentMark(
          name: "DHARSHANA R",
          rollNumber: "210823104030",
          subject: "Operating Systems",
          marks: 86,
        ),
        StudentMark(
          name: "DHARSHANA R",
          rollNumber: "210823104030",
          subject: "Artificial Intelligence",
          marks: 76,
        ),
        StudentMark(
          name: "DHARSHANA R",
          rollNumber: "210823104030",
          subject: "Algorithm",
          marks: 80,
        ),

        // Continue with the rest of the students up to roll number 210823104063
        StudentMark(
          name: "KARTHIKEYAN D",
          rollNumber: "210823104063",
          subject: "Theory of Computation",
          marks: 10,
        ),
        StudentMark(
          name: "KARTHIKEYAN D",
          rollNumber: "210823104063",
          subject: "Database Management Systems",
          marks: 0,
        ),
        StudentMark(
          name: "KARTHIKEYAN D",
          rollNumber: "210823104063",
          subject: "Operating Systems",
          marks: 0,
        ),
        StudentMark(
          name: "KARTHIKEYAN D",
          rollNumber: "210823104063",
          subject: "Artificial Intelligence",
          marks: 20,
        ),
        StudentMark(
          name: "KARTHIKEYAN D",
          rollNumber: "210823104063",
          subject: "Algorithm",
          marks: 0,
        ),
      ];
    } else if (selectedAssessment == 'Internal Assessment 2') {
      allStudentMarks = [
        // Sample data for Internal Assessment 2
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Theory of Computation",
          marks: 75,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Database Management Systems",
          marks: 78,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Operating Systems",
          marks: 70,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Artificial Intelligence",
          marks: 76,
        ),
        StudentMark(
          name: "AATHI BALA KUMAR B (H)",
          rollNumber: "210823104001",
          subject: "Algorithm",
          marks: 85,
        ),
      ];
    }

    // Create a map of student marks by roll number and build unique registrations list
    studentMarksByRollNumber = {};
    availableRegistrations = [];

    for (var mark in allStudentMarks) {
      if (!studentMarksByRollNumber.containsKey(mark.rollNumber)) {
        studentMarksByRollNumber[mark.rollNumber] = [];
        availableRegistrations.add(mark.rollNumber);
      }
      studentMarksByRollNumber[mark.rollNumber]!.add(mark);
    }

    // Sort registrations for better display
    availableRegistrations.sort();

    setState(() {
      _isLoading = false;
    });
  }

  void _lookupMarks() {
    if (!_formKey.currentState!.validate()) return;

    final String regNo = _registrationController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedRegistration = null;
    });

    // Check if the registration number exists in our data
    if (studentMarksByRollNumber.containsKey(regNo)) {
      setState(() {
        _selectedRegistration = regNo;
        filteredMarks = studentMarksByRollNumber[regNo]!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'No marks found for registration number: $regNo';
        filteredMarks = [];
        _isLoading = false;
      });
    }
  }

  void _selectRegistration(String regNo) {
    _registrationController.text = regNo;
    _selectedRegistration = regNo;
    filteredMarks = studentMarksByRollNumber[regNo]!;
    setState(() {});
  }

  double _calculateAverageMarks() {
    if (filteredMarks.isEmpty) return 0;
    double total = 0;
    for (var mark in filteredMarks) {
      total += mark.marks;
    }
    return total / filteredMarks.length;
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exam Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with department and semester
              Card(
                color: colorScheme.primaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.department,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Semester ${widget.semester}',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              if (selectedAssessment == null)
                _buildAssessmentSelection()
              else
                _buildResultsLookup(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Assessment Type",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),
        _buildAssessmentCard("Internal Assessment 1", Icons.assignment),
        SizedBox(height: 16),
        _buildAssessmentCard(
          "Internal Assessment 2",
          Icons.assignment_turned_in,
        ),
      ],
    );
  }

  Widget _buildResultsLookup() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  selectedAssessment = null;
                  _selectedRegistration = null;
                  filteredMarks = [];
                  allStudentMarks = [];
                  studentMarksByRollNumber = {};
                  availableRegistrations = [];
                  _registrationController.clear();
                  _errorMessage = null;
                });
              },
            ),
            Expanded(
              child: Text(
                "$selectedAssessment Results",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Search form
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _registrationController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              labelText: 'Registration Number',
              hintText: 'Enter student registration number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.numbers),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _isLoading ? null : _lookupMarks,
              ),
            ),
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a registration number';
              }
              return null;
            },
            onFieldSubmitted: (_) => _lookupMarks(),
          ),
        ),
        SizedBox(height: 24),

        // Search button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _lookupMarks,
          icon:
              _isLoading
                  ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 3,
                    ),
                  )
                  : Icon(Icons.search),
          label: Text(
            _isLoading ? 'Searching...' : 'Look Up Results',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 24),

        // Show registration guide if no search performed yet
        if (_errorMessage == null && _selectedRegistration == null)
          _buildRegistrationGuide(),

        // Show error message if search failed
        if (_errorMessage != null)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.error.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                    SizedBox(width: 8),
                    Text(
                      'Record Not Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
                SizedBox(height: 12),
                Text(
                  'Make sure you entered the correct registration number, or try one of the available numbers below:',
                  style: TextStyle(color: colorScheme.onErrorContainer.withOpacity(0.9)),
                ),
                SizedBox(height: 16),
                _buildAvailableRegistrationsList(),
              ],
            ),
          ),

        // Show results if search was successful
        if (_selectedRegistration != null) ...[
          SizedBox(height: 24),
          _buildResultsCard(),
        ],
      ],
    );
  }

  Widget _buildRegistrationGuide() {
    if (availableRegistrations.isEmpty) {
      _loadAllMarks();
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Registration Numbers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Select a registration number from the list below:',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            SizedBox(height: 12),
            _buildAvailableRegistrationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableRegistrationsList() {
    final theme = Theme.of(context);
    
    if (availableRegistrations.isEmpty) {
      _loadAllMarks();
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: availableRegistrations.length,
        itemBuilder: (context, index) {
          final regNo = availableRegistrations[index];
          final studentData = studentMarksByRollNumber[regNo]!.first;
          return ListTile(
            dense: true,
            title: Text(regNo),
            subtitle: Text(studentData.name),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              _selectRegistration(regNo);
            },
          );
        },
      ),
    );
  }

  Widget _buildResultsCard() {
    final theme = Theme.of(context);
    final studentName = filteredMarks.first.name;
    final avgMarks = _calculateAverageMarks();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              studentName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Registration No: $_selectedRegistration',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            SizedBox(height: 24),
            _buildMarksProgress(avgMarks),
            SizedBox(height: 24),
            _buildSubjectMarksTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksProgress(double avgMarks) {
    final theme = Theme.of(context);
    
    Color progressColor;
    if (avgMarks < 60) {
      progressColor = Colors.red;
    } else if (avgMarks < 75) {
      progressColor = Colors.orange;
    } else if (avgMarks < 90) {
      progressColor = Colors.blue;
    } else {
      progressColor = Colors.green;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: avgMarks / 100),
                duration: Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder:
                    (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: avgMarks),
              duration: Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder:
                  (context, value, _) => Column(
                    children: [
                      Text(
                        '${value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        'Average Score',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: progressColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: progressColor.withOpacity(0.3)),
          ),
          child: Text(
            avgMarks < 60
                ? 'Failed! Needs improvement.'
                : avgMarks < 75
                ? 'Passed! Can improve further.'
                : avgMarks < 90
                ? 'Good performance!'
                : 'Excellent performance!',
            style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectMarksTable() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject-wise Marks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          Table(
            columnWidths: {0: FlexColumnWidth(3), 1: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 1),
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Marks',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              ...filteredMarks.map((mark) {
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 1),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(mark.subject),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getMarkColor(mark.marks),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${mark.marks}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assessment',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              Text(
                selectedAssessment ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Subjects',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              Text(
                '${filteredMarks.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Marks',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              Text(
                _calculateAverageMarks().toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(String title, IconData icon) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        setState(() {
          selectedAssessment = title;
          _loadAllMarks();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Color _getMarkColor(int marks) {
    if (marks >= 90) return Colors.green;
    if (marks >= 75) return Colors.blue;
    if (marks >= 60) return Colors.orange;
    return Colors.red;
  }

  // Helper method to handle absent (AB) cases
  int _getActualMark(String mark) {
    if (mark == 'AB') {
      return 0;
    }
    return int.tryParse(mark) ?? 0;
  }
}
