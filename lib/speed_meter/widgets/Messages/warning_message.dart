import 'package:flutter/material.dart';

class WarningMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const WarningMessage({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Material(
        // Add Material widget to fix text styling
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 500),
            child: Container(
              constraints: BoxConstraints(maxWidth: 300),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: iconColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
