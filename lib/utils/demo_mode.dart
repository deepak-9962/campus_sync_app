// Demo Mode Singleton
//
// Tracks whether the app is running in demo/explore mode.
// Screens use this to skip auth-required Supabase calls and
// show appropriate demo personas.

class DemoMode {
  static final DemoMode _instance = DemoMode._internal();
  factory DemoMode() => _instance;
  DemoMode._internal();

  bool isActive = false;
  String role = 'student'; // 'student' | 'faculty' | 'hod'

  // ── Demo persona data ──────────────────────────────────────────────────────
  static const String department = 'Computer Science and Engineering';
  static const int semester = 5;

  static final Map<String, Map<String, dynamic>> personas = {
    'student': {
      'name': 'Rahul Kumar',
      'email': 'rahul.kumar@csecollege.ac.in',
      'role': 'student',
      'isStaff': false,
      'isAdmin': false,
      'assignedDepartment': null,
    },
    'faculty': {
      'name': 'Prof. Meena Sharma',
      'email': 'meena.sharma@csecollege.ac.in',
      'role': 'staff',
      'isStaff': true,
      'isAdmin': false,
      'assignedDepartment': department,
    },
    'hod': {
      'name': 'Dr. Arun Patel',
      'email': 'arun.patel@csecollege.ac.in',
      'role': 'hod',
      'isStaff': true,
      'isAdmin': false,
      'assignedDepartment': department,
    },
  };


  Map<String, dynamic> get currentPersona => personas[role] ?? personas['student']!;
  String get displayName => currentPersona['name'] as String;
  String get email => currentPersona['email'] as String;

  void enterDemoMode({String withRole = 'student'}) {
    isActive = true;
    role = withRole;
  }

  void exitDemoMode() {
    isActive = false;
    role = 'student';
  }

  void switchRole(String newRole) {
    if (personas.containsKey(newRole)) {
      role = newRole;
    }
  }
}
