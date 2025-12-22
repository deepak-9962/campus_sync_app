import 'package:flutter/material.dart';
import '../services/marks_service.dart';

class StudentMarksScreen extends StatefulWidget {
  final String registrationNo;

  const StudentMarksScreen({Key? key, required this.registrationNo})
    : super(key: key);

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen> {
  final MarksService _marksService = MarksService();
  List<Map<String, dynamic>> marks = [];
  Map<String, dynamic> performanceSummary = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentMarks();
  }

  Future<void> _loadStudentMarks() async {
    try {
      final studentMarks = await _marksService.getStudentMarks(
        widget.registrationNo,
      );
      final summary = await _marksService.getStudentPerformanceSummary(
        widget.registrationNo,
      );

      setState(() {
        marks = studentMarks;
        performanceSummary = summary;
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading marks: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Marks'),
            Text(
              'Reg: ${widget.registrationNo}',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : marks.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  _buildPerformanceSummary(),
                  Expanded(child: _buildMarksList()),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
          SizedBox(height: 16),
          Text(
            'No marks found for this student.',
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.6)),
          ),
          SizedBox(height: 8),
          Text(
            'Marks will appear here once they are entered.',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    if (performanceSummary.isEmpty) return SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Exams',
                  performanceSummary['totalExams'].toString(),
                  Icons.assignment,
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Average %',
                  '${performanceSummary['averagePercentage'].toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Highest',
                  performanceSummary['highestMark'].toString(),
                  Icons.star,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Lowest',
                  performanceSummary['lowestMark'].toString(),
                  Icons.arrow_downward,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMarksList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: marks.length,
      itemBuilder: (context, index) {
        final mark = marks[index];
        final percentage = (mark['mark'] / mark['out_of'] * 100)
            .toStringAsFixed(1);
        final examName = mark['exams']['name'];

        // Color based on percentage
        Color cardColor = Colors.green.shade50;
        Color borderColor = Colors.green.shade200;
        if (double.parse(percentage) < 60) {
          cardColor = Colors.red.shade50;
          borderColor = Colors.red.shade200;
        } else if (double.parse(percentage) < 75) {
          cardColor = Colors.orange.shade50;
          borderColor = Colors.orange.shade200;
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                mark['subject'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(examName, style: TextStyle(fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                    'Date: ${mark['exams']['date'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${mark['mark']}/${mark['out_of']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          double.parse(percentage) >= 60
                              ? Colors.green
                              : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
