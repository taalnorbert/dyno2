import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../providers/speed_provider.dart';
import '../providers/language_provider.dart'; // Adjuk hozzá ezt az importot
import '../speed_meter/widgets/Messages/warning_message.dart';
import '../speed_meter/widgets/location_disabled_screen.dart';
import '../localization/app_localizations.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final SpeedProvider _speedProvider = SpeedProvider();
  final LanguageProvider _languageProvider = LanguageProvider(); // Új sor
  int bottomNavigationIndex = 2;
  bool showLowSpeedWarning = false;
  bool showHighSpeedWarning = false;
  bool showGpsWarning = false;
  bool isMeasurementDialogVisible = false;
  int previousIndex = 2;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _listenToPermissionChanges();

    // Nyelvi változások figyelése
    _languageProvider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    // Ne felejtsük el törölni a listenert
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  // Nyelvi változás esetén frissítjük a UI-t
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        // Elég a setState hívás, nincs szükség további logikára
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    setState(() {
      _hasLocationPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    });
  }

  void _listenToPermissionChanges() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (_hasLocationPermission != hasPermission) {
        setState(() {
          _hasLocationPermission = hasPermission;
        });
      }
    });
  }

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

    setState(() {
      isMeasurementDialogVisible = true;
      previousIndex = bottomNavigationIndex;
      bottomNavigationIndex = 0;
    });

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            AppLocalizations.chooseMeasurementTitle,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.speed_outlined, color: Colors.white),
                title: Text(
                  _speedProvider.isKmh ? '0-100' : '0-60',
                  style: const TextStyle(color: Colors.white),
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
                title: Text(
                  _speedProvider.isKmh ? '100-200' : '60-120',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  if (_speedProvider.currentSpeed >=
                      (_speedProvider.isKmh ? 100.0 : 60.0)) {
                    _showWarningMessage('high');
                  } else {
                    context.push('/hundred-to-twohundred');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.straighten, color: Colors.white),
                title: const Text(
                  '1/4 Mile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  if (_speedProvider.currentSpeed > 5.0) {
                    _showWarningMessage('high');
                  } else {
                    context.push('/quarter-mile');
                  }
                },
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          isMeasurementDialogVisible = false;
          bottomNavigationIndex = previousIndex;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _speedProvider,
      builder: (context, _) {
        if (!_speedProvider.isLocationServiceEnabled) {
          return const LocationDisabledScreen();
        }

        if (!_hasLocationPermission) {
          return const LocationPermissionDeniedScreen();
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
                    label: AppLocalizations.measure,
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.leaderboard,
                      color:
                          bottomNavigationIndex == 1 ? Colors.red : Colors.grey,
                    ),
                    label: AppLocalizations.competition,
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.home,
                      color:
                          bottomNavigationIndex == 2 ? Colors.red : Colors.grey,
                    ),
                    label: AppLocalizations.home,
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.speed,
                      color:
                          bottomNavigationIndex == 3 ? Colors.red : Colors.grey,
                    ),
                    label: AppLocalizations.dyno,
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.timer,
                      color:
                          bottomNavigationIndex == 4 ? Colors.red : Colors.grey,
                    ),
                    label: AppLocalizations.laptime,
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

                  if (index == 0) {
                    _showMeasurementDialog();
                  } else {
                    setState(() {
                      bottomNavigationIndex = index;
                      previousIndex = index;
                    });

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
              WarningMessage(
                key: const Key('gpsWarning'),
                message: AppLocalizations.noGpsWarningMessage,
                icon: Icons.gps_off,
                color: Colors.orange,
                iconColor: Colors.white,
              ),
            if (showLowSpeedWarning)
              WarningMessage(
                key: const Key('lowSpeedWarning'),
                message: AppLocalizations.lowSpeedWarningMessage,
                icon: Icons.warning,
                color: Colors.red,
                iconColor: Colors.white,
              ),
            if (showHighSpeedWarning)
              WarningMessage(
                key: const Key('highSpeedWarning'),
                message: AppLocalizations.movingWarningMessage,
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
