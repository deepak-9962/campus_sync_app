import 'package:flutter/material.dart';
import '../services/marks_service.dart';
import '../services/exam_service.dart';

/// Utility class to insert DBMS marks data
class DBMSDataInserter {
  final MarksService _marksService = MarksService();
  final ExamService _examService = ExamService();

  // Student data mapping
  static const Map<String, String> studentNames = {
    '210823104001': 'AATHI BALA KUMAR B',
    '210823104002': 'ABEL C JOY',
    '210823104003': 'ABINAYA T',
    '210823104004': 'ABISHA JEBAMANI K',
    '210823104005': 'ABISHEK PAULSON S',
    '210823104006': 'ABY ROSY M',
    '210823104007': 'AKSHAYA PRABHA M',
    '210823104008': 'ANGELIN MARY S',
    '210823104009': 'ANISHA SWEETY J',
    '210823104010': 'ANNESHARON A S',
    '210823104011': 'ANNIE DORAH ABEL',
    '210823104012': 'ANTONY MELVIN T',
    '210823104013': 'ARPUTHA STEPHIN A',
    '210823104014': 'ARTHI M',
    '210823104015': 'ARUNACHALAM R',
    '210823104016': 'ASBOURN JOEL I',
    '210823104017': 'ASLIN BRIMA P H',
    '210823104018': 'ASWITHA K',
    '210823104019': 'BABY SHALINI K',
    '210823104020': 'BALAMURUGAN M',
    '210823104021': 'BLESSING RAJA P',
    '210823104022': 'BOAZ K',
    '210823104023': 'CHANDRA MOHAN C',
    '210823104024': 'CHRISTYBAI JENCY K',
    '210823104025': 'DANIYEL K L',
    '210823104026': 'DEEPA G C',
    '210823104027': 'DEEPAK S',
    '210823104028': 'DHANUSH A',
    '210823104029': 'DHARNESH S',
    '210823104030': 'DHARSHANA R',
    '210823104031': 'DHEEKSHA B',
    '210823104032': 'DHIVIYESH J',
    '210823104033': 'DON SINTO SAJI',
    '210823104034': 'EASWARAMURTHY P',
    '210823104035': 'ELANGO B',
    '210823104036': 'ELAVARASEN S K',
    '210823104037': 'ENOCH M',
    '210823104038': 'GAYATHRI K',
    '210823104039': 'GAYATHRI Kumar',
    '210823104040': 'GOKULAKRISHNAN S',
    '210823104041': 'GOWTHAM A',
    '210823104042': 'HAAKASH A',
    '210823104043': 'HARIHARAN D',
    '210823104044': 'HARIPRIYA V S',
    '210823104046': 'HEMALATHA S',
    '210823104047': 'HEMAVATHI A',
    '210823104048': 'INDIRESH D',
    '210823104049': 'ISAI RAMYA G',
    '210823104050': 'JACOB ADISH MOSES A',
    '210823104051': 'JAFFI JOANNA F',
    '210823104052': 'JAKIN K',
    '210823104053': 'JAYACHITRA B',
    '210823104054': 'JEBARSON P',
    '210823104055': 'JEBIN JEBARAJ D',
    '210823104057': 'JENIFER POOMANI J',
    '210823104058': 'JESSICA M',
    '210823104059': 'JOHN WESLY S',
    '210823104060': 'JOSELIN SARANISHA D',
    '210823104061': 'KARTHIKAISELVI P',
    '210823104062': 'KARTHIKEYAN D',
    '210823104063': 'KARTHIKEYAN D',
  };

  // Marks data (null represents AB/Absent)
  static const Map<String, int?> marksData = {
    '210823104001': 54,
    '210823104002': 66,
    '210823104003': 72,
    '210823104004': 52,
    '210823104005': 18,
    '210823104006': 74,
    '210823104007': 50,
    '210823104008': 56,
    '210823104009': 70,
    '210823104010': null, // AB
    '210823104011': 84,
    '210823104012': 52,
    '210823104013': 68,
    '210823104014': 26,
    '210823104015': 12,
    '210823104016': 54,
    '210823104017': 42,
    '210823104018': 86,
    '210823104019': null, // AB
    '210823104020': 64,
    '210823104021': 56,
    '210823104022': 64,
    '210823104023': 54,
    '210823104024': 60,
    '210823104025': 36,
    '210823104026': 36,
    '210823104027': 36,
    '210823104028': 56,
    '210823104029': 62,
    '210823104030': 66,
    '210823104031': 34,
    '210823104032': 60,
    '210823104033': 52,
    '210823104034': 40,
    '210823104035': 28,
    '210823104036': null, // AB
    '210823104037': 56,
    '210823104038': 36,
    '210823104039': 68,
    '210823104040': 52,
    '210823104041': 32,
    '210823104042': null, // AB
    '210823104043': 26,
    '210823104044': 74,
    '210823104046': null, // AB
    '210823104047': 50,
    '210823104048': 42,
    '210823104049': 34,
    '210823104050': null, // AB
    '210823104051': 34,
    '210823104052': 68,
    '210823104053': 80,
    '210823104054': 46,
    '210823104055': null, // AB
    '210823104057': 18,
    '210823104058': 52,
    '210823104059': 34,
    '210823104060': 72,
    '210823104061': 36,
    '210823104062': 30,
    '210823104063': 2,
  };

  /// Insert DBMS exam and marks data
  Future<bool> insertDBMSData() async {
    try {
      // Step 1: Create the exam
      final examId = await _examService.createExam(
        name: 'Database Management System Exam',
        date: DateTime(2025, 7, 30),
        department: 'computer science and engineering',
        semester: 5,
      );

      if (examId == null) {
        print('Failed to create exam');
        return false;
      }

      // Step 2: Prepare marks data for bulk insertion
      List<Map<String, dynamic>> marksList = [];

      marksData.forEach((regNo, mark) {
        marksList.add({
          'registration_no': regNo,
          'exam_id': examId,
          'subject': 'Database Management System',
          'mark': mark, // null for absent students
          'out_of': 100,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      });

      // Step 3: Bulk insert marks
      final success = await _marksService.bulkInsertMarks(marksList);

      if (success) {
        print('Successfully inserted ${marksList.length} DBMS marks records');
        return true;
      } else {
        print('Failed to insert marks data');
        return false;
      }
    } catch (error) {
      print('Error inserting DBMS data: $error');
      return false;
    }
  }

  /// Get summary of inserted data
  Future<void> printSummary() async {
    final stats = await _marksService.getSubjectStatistics(
      'Database Management System',
    );

    print('\n=== DBMS Marks Summary ===');
    print('Total Students: ${stats['totalStudents']}');
    print('Students with Marks: ${stats['studentsWithMarks']}');
    print('Absent Students: ${stats['absentStudents']}');
    print('Average Mark: ${stats['averageMark']?.toStringAsFixed(2)}');
    print('Highest Mark: ${stats['highestMark']}');
    print('Lowest Mark: ${stats['lowestMark']}');
    print('Pass Count: ${stats['passCount']}');
    print('Fail Count: ${stats['failCount']}');
    print('Pass Percentage: ${stats['passPercentage']?.toStringAsFixed(2)}%');
    print('========================\n');
  }
}

/// Example usage widget
class DBMSDataInsertionScreen extends StatefulWidget {
  const DBMSDataInsertionScreen({super.key});

  @override
  State<DBMSDataInsertionScreen> createState() =>
      _DBMSDataInsertionScreenState();
}

class _DBMSDataInsertionScreenState extends State<DBMSDataInsertionScreen> {
  final DBMSDataInserter _inserter = DBMSDataInserter();
  bool _isInserting = false;
  String _message = '';

  Future<void> _insertData() async {
    setState(() {
      _isInserting = true;
      _message = 'Inserting DBMS marks data...';
    });

    try {
      final success = await _inserter.insertDBMSData();

      if (success) {
        await _inserter.printSummary();
        setState(() {
          _message = 'Successfully inserted DBMS marks data for all students!';
        });
      } else {
        setState(() {
          _message = 'Failed to insert DBMS marks data. Please check the logs.';
        });
      }
    } catch (error) {
      setState(() {
        _message = 'Error: $error';
      });
    } finally {
      setState(() => _isInserting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DBMS Data Insertion'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database Management System Marks',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will insert marks for ${DBMSDataInserter.marksData.length} students.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Absent students (AB) will have null marks.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isInserting ? null : _insertData,
              icon:
                  _isInserting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.upload),
              label: Text(_isInserting ? 'Inserting...' : 'Insert DBMS Marks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            if (_message.isNotEmpty)
              Card(
                color:
                    _message.contains('Successfully')
                        ? Colors.green[50]
                        : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color:
                          _message.contains('Successfully')
                              ? Colors.green[700]
                              : Colors.red[700],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
