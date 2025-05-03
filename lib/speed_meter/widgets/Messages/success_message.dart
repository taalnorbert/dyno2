import 'package:flutter/material.dart';

class SuccessMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const SuccessMessage({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.sizeOf(context);
    final isSmallScreen = screenSize.width < 360;

    // Calculate responsive dimensions
    final containerWidth = screenSize.width * 0.6;
    final fontSize = isSmallScreen ? 12.0 : 14.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;
    final padding = isSmallScreen ? 8.0 : 10.0;

    return Positioned(
      top: screenSize.height * 0.05, // 5% from top
      left: (screenSize.width - containerWidth) / 2, // Center horizontally
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 500),
        child: Container(
          width: containerWidth,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center content
            children: [
              Icon(
                icon,
                color: iconColor,
                size: iconSize,
              ),
              SizedBox(width: padding),
              Flexible(
                // Add Flexible to handle long text
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
