import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DepartmentSelectionScreen extends StatefulWidget {
  const DepartmentSelectionScreen({Key? key}) : super(key: key);

  @override
  State<DepartmentSelectionScreen> createState() =>
      _DepartmentSelectionScreenState();
}

class _DepartmentSelectionScreenState extends State<DepartmentSelectionScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<String> _departments = [];
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchCurrentDepartment();
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await _supabase
          .from('departments')
          .select('name')
          .order('name', ascending: true);
      if (response.isNotEmpty) {
        setState(() {
          _departments = response.map((e) => e['name'] as String).toList();
        });
      }
    } catch (e) {
      print('Error fetching departments: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  Future<void> _fetchCurrentDepartment() async {
    try {
      // Assuming there's a configuration table or similar to store the currently active department
      final response =
          await _supabase
              .from('app_settings')
              .select('current_department')
              .single();
      if (response.isNotEmpty) {
        setState(() {
          _selectedDepartment = response['current_department'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching current department: $e');
      // If no current department is set, it's fine, _selectedDepartment will remain null
    }
  }

  Future<void> _updateCurrentDepartment(String department) async {
    try {
      await _supabase.from('app_settings').upsert(
        {
          'id': 1,
          'current_department': department,
        }, // Assuming a single row with ID 1 for app settings
        onConflict: 'id',
      );
      setState(() {
        _selectedDepartment = department;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Department changed to $department')),
      );
    } catch (e) {
      print('Error updating department: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change department: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Department')),
      body:
          _departments.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final department = _departments[index];
                  return ListTile(
                    title: Text(department),
                    trailing:
                        _selectedDepartment == department
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                    onTap: () {
                      _updateCurrentDepartment(department);
                    },
                  );
                },
              ),
    );
  }
}
