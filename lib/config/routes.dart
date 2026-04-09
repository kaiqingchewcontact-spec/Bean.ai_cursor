import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/paywall_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/scanner/scan_result_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/library/bean_detail_screen.dart';
import '../screens/brew/brew_screen.dart';
import '../screens/brew/brew_log_screen.dart';
import '../screens/brew/brew_detail_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/journal/tasting_note_screen.dart';
import '../screens/journal/insights_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/discover/roaster_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/equipment_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LibraryScreen(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => BeanDetailScreen(
                beanId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/brew',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BrewScreen(),
          ),
          routes: [
            GoRoute(
              path: 'log',
              builder: (context, state) => BrewLogScreen(
                beanId: state.uri.queryParameters['beanId'],
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => BrewDetailScreen(
                brewId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/journal',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: JournalScreen(),
          ),
          routes: [
            GoRoute(
              path: 'note',
              builder: (context, state) => TastingNoteScreen(
                brewId: state.uri.queryParameters['brewId'],
              ),
            ),
            GoRoute(
              path: 'insights',
              builder: (context, state) => const InsightsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/discover',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiscoverScreen(),
          ),
          routes: [
            GoRoute(
              path: 'roaster/:id',
              builder: (context, state) => RoasterDetailScreen(
                roasterId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: 'equipment',
              builder: (context, state) => const EquipmentScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/scan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/scan/result',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ScanResultScreen(
        imagePath: state.uri.queryParameters['imagePath'] ?? '',
      ),
    ),
  ],
);
