import 'package:flutter/material.dart';
import 'gpa_cgpa_calculator_screen.dart'; // To navigate to the 2021 calculator

class RegulationSelectionScreen extends StatelessWidget {
  final String userDepartment;
  final int userSemester;

  const RegulationSelectionScreen({
    super.key,
    required this.userDepartment,
    required this.userSemester,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Regulation'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Please select the academic regulation for the GPA/CGPA calculator:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white, // Added for better contrast
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => GpaCgpaCalculatorScreen(
                            initialDepartment: userDepartment,
                            initialSemester:
                                userSemester.toString(), // Pass to calculator
                          ),
                    ),
                  );
                },
                child: const Text('Regulation 2021'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.black87, // Added for better contrast
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Regulation 2017 calculator will be available soon.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                child: const Text('Regulation 2017'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
