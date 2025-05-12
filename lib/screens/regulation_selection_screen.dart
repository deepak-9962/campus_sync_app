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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Regulation'),
        // backgroundColor will be inherited from global theme
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
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                // This will use the global ElevatedButtonTheme
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ), // Already in global theme but can be kept
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Keep custom shape if desired
                  ),
                ).merge(
                  theme.elevatedButtonTheme.style,
                ), // Ensure global style is base
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
              OutlinedButton(
                // Changed to OutlinedButton for less emphasis
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Clash Grotesk',
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
