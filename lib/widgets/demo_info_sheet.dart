import 'package:flutter/material.dart';
import '../utils/demo_mode.dart';

/// Demo Info Bottom Sheet
///
/// Shown when the user taps "Explore App" on the login screen.
/// Lets the user pick a role persona before entering demo mode.
class DemoInfoSheet extends StatefulWidget {
  final VoidCallback onEnterDemo;

  const DemoInfoSheet({super.key, required this.onEnterDemo});

  @override
  State<DemoInfoSheet> createState() => _DemoInfoSheetState();
}

class _DemoInfoSheetState extends State<DemoInfoSheet> {
  String _selectedRole = 'student';

  static const _roles = [
    {
      'key': 'student',
      'label': 'Student',
      'subtitle': 'Rahul Kumar — CSE Sem 5',
      'description': 'View timetable, attendance, marks, resources & more',
      'icon': Icons.person_outline_rounded,
      'color': Color(0xFF2E7D32), // green
    },
    {
      'key': 'faculty',
      'label': 'Faculty',
      'subtitle': 'Prof. Meena Sharma',
      'description': 'Take attendance, manage exams, edit timetable & more',
      'icon': Icons.school_outlined,
      'color': Color(0xFF1565C0), // blue
    },
    {
      'key': 'hod',
      'label': 'HOD',
      'subtitle': 'Dr. Arun Patel',
      'description': 'Department analytics, low-attendance alerts, reports',
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFF6A1B9A), // purple
    },
  ];

  static const _features = [
    {'icon': Icons.calendar_today_outlined, 'label': 'Timetable'},
    {'icon': Icons.bar_chart_outlined, 'label': 'Attendance'},
    {'icon': Icons.folder_open_outlined, 'label': 'Resources'},
    {'icon': Icons.campaign_outlined, 'label': 'Announcements'},
    {'icon': Icons.calculate_outlined, 'label': 'GPA Calc'},
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedRoleData = _roles.firstWhere((r) => r['key'] == _selectedRole);
    final selectedColor = selectedRoleData['color'] as Color;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // ── Drag handle ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [selectedColor, selectedColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          selectedRoleData['icon'] as IconData,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Explore Campus Sync',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Experience the full app as different campus roles',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ── Role selector ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHOOSE A ROLE',
                        style: tt.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_roles.map((role) {
                        final isSelected = _selectedRole == role['key'];
                        final roleColor = role['color'] as Color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRole = role['key'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? roleColor.withOpacity(0.08)
                                  : cs.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? roleColor : cs.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? roleColor.withOpacity(0.15)
                                        : cs.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    role['icon'] as IconData,
                                    color: isSelected ? roleColor : cs.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            role['label'] as String,
                                            style: tt.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? roleColor : cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? roleColor.withOpacity(0.1)
                                                  : cs.surfaceVariant,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              role['subtitle'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected
                                                    ? roleColor
                                                    : cs.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        role['description'] as String,
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color: roleColor, size: 22),
                              ],
                            ),
                          ),
                        );
                      })),
                    ],
                  ),
                ),

                // ── Feature pills ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WHAT YOU CAN EXPLORE',
                        style: tt.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _features.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(f['icon'] as IconData,
                                    size: 15, color: selectedColor),
                                const SizedBox(width: 6),
                                Text(
                                  f['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // ── Note ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: cs.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Demo mode shows live read-only data. No account required.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── CTA Buttons ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            'Enter as ${selectedRoleData['label']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            DemoMode().enterDemoMode(withRole: _selectedRole);
                            Navigator.pop(context);
                            widget.onEnterDemo();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
