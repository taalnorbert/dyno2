import 'package:flutter/material.dart';

void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey, width: 3),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "App Instructions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                """
                Welcome to the DynoMobile app! Below you will find an overview of the available features:
                
                0-100 Measurement: This function calculates the time it takes for your vehicle to accelerate from 0 to 100 km/h. The timer starts when your speed exceeds 3 km/h.
                
                100-200 Measurement: This function records the time it takes to accelerate from 100 to 200 km/h. The timer starts when your speed surpasses 103 km/h.
                
                Performance Measurement: This feature calculates your vehicle’s power output in horsepower.
                
                Lap Timer: The lap timer starts when you leave your initial position and stops when you return to the same location, recording the total time taken.
                
                Please note that the speedometer and all measurements are subject to inaccuracies. This application is designed purely for entertainment purposes and should not be relied upon for precise performance data.
                
                Drive safely and enjoy using the app!
                """,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
