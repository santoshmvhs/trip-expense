import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/auth_page.dart';
import '../features/shell/app_shell.dart';
import '../features/groups/group_detail_page.dart';
import '../features/expenses/add_expense_page.dart';
import '../features/expenses/expense_detail_page.dart';
import '../features/groups/group_timeline_page.dart';
import '../screens/group/qr_invite_screen.dart';
import '../screens/group/scan_qr_screen.dart';
import '../features/settle/settle_page.dart';
import '../screens/notifications/notifications_screen.dart';
import '../features/moments/moment_detail_page.dart';
import '../features/moments/share_moment_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final supa = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/shell',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(supa.auth.onAuthStateChange),
    redirect: (context, state) {
      try {
        final session = supa.auth.currentSession;
        final loggingIn = state.matchedLocation == '/auth';

        if (session == null && !loggingIn) return '/auth';
        if (session != null && loggingIn) return '/shell';
        return null;
      } catch (e) {
        debugPrint('Router redirect error: $e');
        return '/auth'; // Fallback to auth on error
      }
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
      GoRoute(
        path: '/shell',
        builder: (_, __) => const AppShell(),
        routes: [
          GoRoute(
            path: 'group/:id',
            builder: (ctx, st) {
              final groupId = st.pathParameters['id']!;
              return GroupDetailPage(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'group/:id/add-expense',
            builder: (ctx, st) {
              final groupId = st.pathParameters['id']!;
              return AddExpensePage(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'group/:id/expense/:expenseId',
            builder: (ctx, st) {
              final expenseId = st.pathParameters['expenseId']!;
              return ExpenseDetailPage(expenseId: expenseId);
            },
          ),
          GoRoute(
            path: 'group/:id/expense/:expenseId/edit',
            builder: (ctx, st) {
              final groupId = st.pathParameters['id']!;
              final expenseId = st.pathParameters['expenseId']!;
              return AddExpensePage(groupId: groupId, expenseId: expenseId);
            },
          ),
          GoRoute(
            path: 'group/:id/timeline',
            builder: (ctx, st) {
              final groupId = st.pathParameters['id']!;
              return GroupTimelinePage(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'group/:id/qr-invite',
            builder: (ctx, st) {
              final groupId = st.pathParameters['id']!;
              return QrInviteScreen(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'group/:id/settle',
            builder: (ctx, st) {
              final groupId = st.pathParameters['id']!;
              return SettlePage(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'group/:groupId/moment/:momentId',
            builder: (ctx, st) {
              final groupId = st.pathParameters['groupId']!;
              final momentId = st.pathParameters['momentId']!;
              return MomentDetailPage(momentId: momentId, groupId: groupId);
            },
            routes: [
              GoRoute(
                path: 'share',
                builder: (ctx, st) {
                  final groupId = st.pathParameters['groupId']!;
                  final momentId = st.pathParameters['momentId']!;
                  return ShareMomentScreen(momentId: momentId, groupId: groupId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'scan-qr',
            builder: (_, __) => const ScanQrScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

