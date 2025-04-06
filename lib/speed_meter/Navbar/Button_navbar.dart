import 'package:dyno2/speed_meter/Navbar/Pages/performance.dart';
import 'package:flutter/material.dart';
import 'package:dyno2/login/login.dart';
import '../../services/auth_service.dart';
import 'Pages/laptime.dart';
import 'Pages/competitions.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final double currentSpeed;
  final bool isLocationServiceEnabled;
  final Function() showMovementWarning;
  final Function() showMovementTooHigh;
  final Function(int) onItemTappedInternal;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.currentSpeed,
    required this.isLocationServiceEnabled,
    required this.showMovementWarning,
    required this.showMovementTooHigh,
    required this.onItemTappedInternal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        canvasColor: Colors.black,
      ),
      child: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: PopupMenuButton<String>(
              icon: Icon(Icons.access_time),
              onSelected: (String value) {
                if (value == '0-100') {
                  if (currentSpeed >= 1) {
                    showMovementWarning();
                  } else {
                    onItemTappedInternal(0); // 0-100 mérés indítása
                  }
                } else if (value == '100-200') {
                  if (currentSpeed >= 100) {
                    showMovementTooHigh();
                  } else {
                    onItemTappedInternal(1); // 100-200 mérés indítása
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: '0-100',
                  child: Row(
                    children: [
                      Icon(Icons.speed, color: Colors.blue), // Ikon hozzáadása
                      SizedBox(width: 10), // Térköz az ikon és a szöveg között
                      Text(
                        '0-100 mérés',
                        style: TextStyle(
                          color: Colors.blue, // Szöveg színe
                          fontWeight: FontWeight.bold, // Szöveg vastagsága
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: '100-200',
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.red), // Ikon hozzáadása
                      SizedBox(width: 10), // Térköz az ikon és a szöveg között
                      Text(
                        '100-200 mérés',
                        style: TextStyle(
                          color: Colors.red, // Szöveg színe
                          fontWeight: FontWeight.bold, // Szöveg vastagsága
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            label: 'Mérés',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Competitions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Kezdőlap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: 'Teljesítmény',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Köridő',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: (index) async {
          final user = AuthService().currentUser;
          // Ha a felhasználó anonim, és a 3-as vagy 4-es indexre kattint
          if (user == null && (index == 3 || index == 4
          )) {
            // Üzenet a felhasználónak
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Must be logged in!",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
              ),
            );

            // Navigálj a bejelentkezési oldalra
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Login()),
            );
          } else {
            // Ha a felhasználó be van jelentkezve, akkor végezze el a megfelelő műveletet
            if (index == 1) {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CompetitionsPage()),
              );
            }else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const dynoscreen()),
                );
            } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LapTimeScreen()),
                );
            } else {
              onItemTappedInternal(index);
            }
          }
        },
      ),
    );
  }
}