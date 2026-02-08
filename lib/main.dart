import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/moments/ui/moments_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://uzlctsulpzlvwvlkekgj.supabase.co',
    anonKey: 'sb_publishable_TNo02OZJnNUGYI0KoG1Aaw_KxEkyoCU',
  );
  
  // Check if user is logged in
  final user = currentUser();
  final initialRoute = user != null ? '/' : '/login';
  
  runApp(
    ProviderScope(
      child: MaterialApp(
        title: 'Momentra',
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Always dark; ignore system setting
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const MomentsHomeScreen(),
          '/login': (context) => const LoginScreen(),
        },
        onGenerateRoute: AppRouter.generateRoute,
      ),
    ),
  );
}
