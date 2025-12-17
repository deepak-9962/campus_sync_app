import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient client;

  DatabaseService(this.client);

  Future<void> fetchData() async {
    // Logic to fetch data from the database
  }

  Future<void> saveData(Map<String, dynamic> data) async {
    // Logic to save data to the database
  }
}
