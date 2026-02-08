import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/moments/ui/moments_home_screen.dart';
import '../features/moments/ui/create_moment_screen.dart';
import '../features/moments/ui/moment_detail_screen.dart';
import '../features/moments/ui/invite_screen.dart';
import '../features/moments/ui/add_contribution_screen.dart';
import '../features/moments/ui/close_moment_screen.dart';

final routerProvider = Provider<RouteInformationParser<Object>>((ref) {
  return _MomentraRouteInformationParser();
});

class _MomentraRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri.path;
  }
  
  @override
  RouteInformation restoreRouteInformation(Object configuration) {
    return RouteInformation(uri: Uri.parse(configuration.toString()));
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MomentsHomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/create-moment':
        return MaterialPageRoute(builder: (_) => const CreateMomentScreen());
      case '/moment-detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MomentDetailScreen(momentId: args['momentId']),
        );
      case '/invite':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InviteScreen(momentId: args['momentId']),
        );
      case '/add-contribution':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddContributionScreen(momentId: args['momentId']),
        );
      case '/close-moment':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CloseMomentScreen(momentId: args['momentId']),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

