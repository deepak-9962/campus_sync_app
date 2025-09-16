import 'package:flutter/material.dart';

/// Represents a feature item displayed on the unified dashboard
class DashboardFeature {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? subtitle;
  final bool isEnabled;

  const DashboardFeature({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
    this.subtitle,
    this.isEnabled = true,
  });

  /// Creates a copy of this feature with some properties overridden
  DashboardFeature copyWith({
    String? title,
    IconData? icon,
    VoidCallback? onTap,
    Color? color,
    String? subtitle,
    bool? isEnabled,
  }) {
    return DashboardFeature(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      onTap: onTap ?? this.onTap,
      color: color ?? this.color,
      subtitle: subtitle ?? this.subtitle,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
