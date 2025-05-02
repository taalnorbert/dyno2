import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/speed_provider.dart';
import '../speed_meter/widgets/Messages/warning_message.dart';
import '../speed_meter/widgets/location_disabled_screen.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final SpeedProvider _speedProvider = SpeedProvider();
  int bottomNavigationIndex = 2;
  bool showLowSpeedWarning = false;
  bool showHighSpeedWarning = false;
  bool showGpsWarning = false;

  void _showNoGpsWarning() {
    setState(() {
      showGpsWarning = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showGpsWarning = false;
          });
        }
      });
    });
  }

  void _showWarningMessage(String type) {
    setState(() {
      if (type == 'low') {
        showLowSpeedWarning = true;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              showLowSpeedWarning = false;
            });
          }
        });
      } else if (type == 'high') {
        showHighSpeedWarning = true;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              showHighSpeedWarning = false;
            });
          }
        });
      }
    });
  }

  void _showMeasurementDialog() {
    if (!mounted || !_speedProvider.hasGpsSignal) {
      _showNoGpsWarning();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Válassz mérést',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.speed_outlined, color: Colors.white),
                title: const Text(
                  '0-100',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  if (_speedProvider.currentSpeed > 5.0) {
                    _showWarningMessage('high');
                  } else {
                    context.push('/zero-to-hundred');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white),
                title: const Text(
                  '100-200',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  if (_speedProvider.currentSpeed < 95) {
                    _showWarningMessage('low');
                  } else if (_speedProvider.currentSpeed > 105) {
                    _showWarningMessage('high');
                  } else {
                    context.push('/hundred-to-twohundred');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _speedProvider,
      builder: (context, _) {
        if (!_speedProvider.isLocationServiceEnabled) {
          return const LocationDisabledScreen();
        }

        return Stack(
          children: [
            Scaffold(
              body: widget.child,
              bottomNavigationBar: NavigationBar(
                backgroundColor: Colors.black,
                indicatorColor: Colors.transparent,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.speed_outlined,
                      color:
                          bottomNavigationIndex == 0 ? Colors.red : Colors.grey,
                    ),
                    label: 'Measure',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.leaderboard,
                      color:
                          bottomNavigationIndex == 1 ? Colors.red : Colors.grey,
                    ),
                    label: 'Verseny',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.home,
                      color:
                          bottomNavigationIndex == 2 ? Colors.red : Colors.grey,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.speed,
                      color:
                          bottomNavigationIndex == 3 ? Colors.red : Colors.grey,
                    ),
                    label: 'Dyno',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.timer,
                      color:
                          bottomNavigationIndex == 4 ? Colors.red : Colors.grey,
                    ),
                    label: 'Laptime',
                  ),
                ],
                selectedIndex: bottomNavigationIndex,
                height: 80,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                onDestinationSelected: (index) {
                  if (!_speedProvider.hasGpsSignal &&
                      (index == 0 || index == 3 || index == 4)) {
                    _showNoGpsWarning();
                    return;
                  }

                  setState(() {
                    bottomNavigationIndex = index;
                  });

                  if (index == 0) {
                    _showMeasurementDialog();
                  } else {
                    switch (index) {
                      case 1:
                        context.go('/competitions');
                        break;
                      case 2:
                        context.go('/home');
                        break;
                      case 3:
                        context.go('/dyno');
                        break;
                      case 4:
                        context.go('/laptime');
                        break;
                    }
                  }
                },
              ),
            ),
            if (showGpsWarning)
              const WarningMessage(
                key: Key('gpsWarning'),
                message: 'Nincs GPS jel!',
                icon: Icons.gps_off,
                color: Colors.orange,
                iconColor: Colors.white,
              ),
            if (showLowSpeedWarning)
              const WarningMessage(
                key: Key('lowSpeedWarning'),
                message: "Legalább 95km/h haladj!",
                icon: Icons.warning,
                color: Colors.red,
                iconColor: Colors.white,
              ),
            if (showHighSpeedWarning)
              const WarningMessage(
                key: Key('highSpeedWarning'),
                message: "Mozgásban vagy!",
                icon: Icons.warning,
                color: Colors.red,
                iconColor: Colors.white,
              ),
          ],
        );
      },
    );
  }
}
