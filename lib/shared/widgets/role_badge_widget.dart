import 'package:flutter/material.dart';
import '../../auth/models/app_user.dart';

/// A compact pill-shaped badge that displays a user's role with its brand colour.
class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool large;

  const RoleBadge({super.key, required this.role, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: role.gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: role.color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            role.icon,
            size: large ? 16 : 12,
            color: Colors.white,
          ),
          SizedBox(width: large ? 6 : 4),
          Text(
            role.shortLabel,
            style: TextStyle(
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
