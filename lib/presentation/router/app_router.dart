import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/clients/clients_screen.dart';
import '../screens/clients/client_detail_screen.dart';
import '../screens/clients/add_client_screen.dart';
import '../screens/clients/edit_client_screen.dart';
import '../screens/debts/debts_screen.dart';
import '../screens/debts/add_debt_screen.dart';
import '../screens/debts/debt_detail_screen.dart';
import '../screens/payments/add_payment_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';
import '../widgets/main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/clients',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ClientsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddClientScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return ClientDetailScreen(clientId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return EditClientScreen(clientId: id);
                  },
                ),
                GoRoute(
                  path: 'debt/add',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return AddDebtScreen(clientId: id);
                  },
                ),
                GoRoute(
                  path: 'debt/:debtId',
                  builder: (context, state) {
                    final clientId = int.parse(state.pathParameters['id']!);
                    final debtId = int.parse(state.pathParameters['debtId']!);
                    return DebtDetailScreen(clientId: clientId, debtId: debtId);
                  },
                  routes: [
                    GoRoute(
                      path: 'payment/add',
                      builder: (context, state) {
                        final clientId = int.parse(state.pathParameters['id']!);
                        final debtId = int.parse(state.pathParameters['debtId']!);
                        return AddPaymentScreen(clientId: clientId, debtId: debtId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/debts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DebtsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddDebtScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return DebtDetailScreen(debtId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'about',
              builder: (context, state) => const AboutScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
