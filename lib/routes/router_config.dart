import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../speed_meter/Navbar/Pages/home.dart';
import '../speed_meter/Navbar/Pages/competitions.dart';
import '../speed_meter/Navbar/Pages/performance.dart';
import '../speed_meter/Navbar/Pages/laptime.dart';
import '../speed_meter/Navbar/Pages/zero_to_hundred.dart';
import '../speed_meter/Navbar/Pages/hundred_to_twohundred.dart';
import '../login/login.dart';
import '../speed_meter/profile_page.dart';
import '../widgets/main_scaffold.dart';
import '../signup/signup.dart';
import '../speed_meter/Navbar/Pages/quarter_mile.dart';

final GlobalKey<NavigatorState> _rootNavigator = GlobalKey(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigator =
    GlobalKey(debugLabel: 'shell');

final router = GoRouter(
  navigatorKey: _rootNavigator,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (!user.emailVerified) {
            FirebaseAuth.instance.signOut();
            return '/login';
          }
          return '/home';
        }
        return '/login';
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => Login(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => Signup(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        final email = state.extra as String?;
        return ProfilePage(userEmail: email ?? 'No Email');
      },
    ),
    GoRoute(
      path: '/zero-to-hundred',
      builder: (context, state) => const ZeroToHundred(),
    ),
    GoRoute(
      path: '/hundred-to-twohundred',
      builder: (context, state) => const HundredToTwoHundred(),
    ),
    GoRoute(
      path: '/quarter-mile',
      builder: (context, state) => const QuarterMile(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigator,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/measure',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/competitions',
          builder: (context, state) => const CompetitionsPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/dyno',
          builder: (context, state) => const dynoscreen(),
        ),
        GoRoute(
          path: '/laptime',
          builder: (context, state) => const LapTimeScreen(),
        ),
      ],
    ),
  ],
);
