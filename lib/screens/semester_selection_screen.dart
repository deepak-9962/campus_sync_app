import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SemesterSelectionScreen extends StatefulWidget {
  const SemesterSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SemesterSelectionScreen> createState() =>
      _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<String> _semesters = [];
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _fetchSemesters();
    _fetchCurrentSemester();
  }

  Future<void> _fetchSemesters() async {
    try {
      final response = await _supabase
          .from('semesters')
          .select('name')
          .order('name', ascending: true);
      if (response.isNotEmpty) {
        setState(() {
          _semesters = response.map((e) => e['name'] as String).toList();
        });
      }
    } catch (e) {
      print('Error fetching semesters: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  Future<void> _fetchCurrentSemester() async {
    try {
      // Assuming there's a configuration table or similar to store the currently active semester
      final response =
          await _supabase
              .from('app_settings')
              .select('current_semester')
              .single();
      if (response.isNotEmpty) {
        setState(() {
          _selectedSemester = response['current_semester'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching current semester: $e');
      // If no current semester is set, it's fine, _selectedSemester will remain null
    }
  }

  Future<void> _updateCurrentSemester(String semester) async {
    try {
      await _supabase.from('app_settings').upsert(
        {
          'id': 1,
          'current_semester': semester,
        }, // Assuming a single row with ID 1 for app settings
        onConflict: 'id',
      );
      setState(() {
        _selectedSemester = semester;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Semester changed to $semester')));
    } catch (e) {
      print('Error updating semester: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to change semester: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Semester')),
      body:
          _semesters.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _semesters.length,
                itemBuilder: (context, index) {
                  final semester = _semesters[index];
                  return ListTile(
                    title: Text(semester),
                    trailing:
                        _selectedSemester == semester
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                    onTap: () {
                      _updateCurrentSemester(semester);
                    },
                  );
                },
              ),
    );
  }
}
