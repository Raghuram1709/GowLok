import 'package:flutter/material.dart';
import 'app_theme.dart';

Color getHealthStatusColor(String? status) {
  final s = status?.toLowerCase();
  switch (s) {
    case 'critical':
      return GowlokColors.critical;
    case 'warning':
      return Color(0xFFFFA500);
    default:
      return GowlokColors.success;
  }
}
