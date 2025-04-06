import 'package:flutter/material.dart';



class NoOutlineMeasurementButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isStopped;
  final Color? backgroundColor;

  const NoOutlineMeasurementButton({super.key, 
    required this.onPressed,
    required this.text,
    this.isStopped = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isStopped ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}