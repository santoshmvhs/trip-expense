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
import '../core/animations/premium_transitions.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  try {
    // Check if Supabase is initialized
    if (!Supabase.instance.isInitialized) {
      debugPrint('⚠️ Supabase not initialized, creating fallback router');
      return GoRouter(
        initialLocation: '/auth',
        routes: [
          GoRoute(
            path: '/auth',
            builder: (_, __) => Scaffold(
              backgroundColor: const Color(0xFF1A1A1A),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      );
    }
    
    final supa = Supabase.instance.client;
    
    // Determine initial location based on auth state
    final hasSession = supa.auth.currentSession != null;
    final initialLocation = hasSession ? '/shell' : '/auth';
    
    debugPrint('🔐 Auth state: ${hasSession ? "Authenticated" : "Not authenticated"}');
    debugPrint('📍 Initial location: $initialLocation');

    return GoRouter(
      initialLocation: initialLocation,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(supa.auth.onAuthStateChange),
      redirect: (context, state) {
        try {
          final session = supa.auth.currentSession;
          final currentPath = state.matchedLocation;
          final isAuthPage = currentPath == '/auth';

          debugPrint('🔄 Redirect check: path=$currentPath, hasSession=${session != null}');
          
          // If no session and not on auth page, redirect to auth
          if (session == null && !isAuthPage) {
            debugPrint('➡️ Redirecting to /auth (no session)');
            return '/auth';
          }
          
          // If has session and on auth page, redirect to shell
          if (session != null && isAuthPage) {
            debugPrint('➡️ Redirecting to /shell (has session)');
            return '/shell';
          }
          
          return null; // No redirect needed
        } catch (e, stackTrace) {
          debugPrint('❌ Router redirect error: $e');
          debugPrint('Stack trace: $stackTrace');
          return '/auth'; // Fallback to auth on error
        }
      },
    routes: [
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => PremiumTransitions.fadeScaleTransition(
          child: const AuthPage(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/shell',
        pageBuilder: (context, state) => PremiumTransitions.fadeScaleTransition(
          child: const AppShell(),
          state: state,
        ),
        routes: [
          GoRoute(
            path: 'group/:id',
            pageBuilder: (context, state) => PremiumTransitions.slideFromRight(
              child: GroupDetailPage(groupId: state.pathParameters['id']!),
              state: state,
            ),
          ),
          GoRoute(
            path: 'group/:id/add-expense',
            pageBuilder: (context, state) => PremiumTransitions.slideFromBottom(
              child: AddExpensePage(groupId: state.pathParameters['id']!),
              state: state,
            ),
          ),
          GoRoute(
            path: 'group/:id/expense/:expenseId',
            pageBuilder: (context, state) => PremiumTransitions.heroTransition(
              child: ExpenseDetailPage(expenseId: state.pathParameters['expenseId']!),
              state: state,
            ),
          ),
          GoRoute(
            path: 'group/:id/expense/:expenseId/edit',
            pageBuilder: (context, state) => PremiumTransitions.slideFromBottom(
              child: AddExpensePage(
                groupId: state.pathParameters['id']!,
                expenseId: state.pathParameters['expenseId']!,
              ),
              state: state,
            ),
          ),
          GoRoute(
            path: 'group/:id/timeline',
            pageBuilder: (context, state) => PremiumTransitions.slideFromRight(
              child: GroupTimelinePage(groupId: state.pathParameters['id']!),
              state: state,
            ),
          ),
          GoRoute(
            path: 'group/:id/qr-invite',
            pageBuilder: (context, state) => PremiumTransitions.slideFromBottom(
              child: QrInviteScreen(groupId: state.pathParameters['id']!),
              state: state,
            ),
          ),
          GoRoute(
            path: 'group/:id/settle',
            pageBuilder: (context, state) => PremiumTransitions.slideFromRight(
              child: SettlePage(groupId: state.pathParameters['id']!),
              state: state,
            ),
          ),
          GoRoute(
            path: 'group/:groupId/moment/:momentId',
            pageBuilder: (context, state) => PremiumTransitions.heroTransition(
              child: MomentDetailPage(
                momentId: state.pathParameters['momentId']!,
                groupId: state.pathParameters['groupId']!,
              ),
              state: state,
            ),
            routes: [
              GoRoute(
                path: 'share',
                pageBuilder: (context, state) => PremiumTransitions.slideFromBottom(
                  child: ShareMomentScreen(
                    momentId: state.pathParameters['momentId']!,
                    groupId: state.pathParameters['groupId']!,
                  ),
                  state: state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'scan-qr',
            pageBuilder: (context, state) => PremiumTransitions.slideFromBottom(
              child: const ScanQrScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => PremiumTransitions.slideFromRight(
              child: const NotificationsScreen(),
              state: state,
            ),
          ),
        ],
      ),
    ],
  );
  } catch (e) {
    debugPrint('ERROR creating router: $e');
    // Return a minimal router that shows error
    return GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(
          path: '/auth',
          builder: (_, __) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Router Error: $e'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
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

