import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    debugPrint('Using fallback credentials');
  }

  // Get Supabase credentials from environment variables
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 
      'https://uzlctsulpzlvwvlkekgj.supabase.co'; // Fallback for development
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
      'sb_publishable_TNo02OZJnNUGYI0KoG1Aaw_KxEkyoCU'; // Fallback for development

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('ERROR: Missing Supabase credentials');
    // Don't throw, use fallbacks instead
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('ERROR: Failed to initialize Supabase: $e');
    // Continue anyway - app will show error in UI
  }

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final router = ref.watch(appRouterProvider);
      final themeMode = ref.watch(themeProvider);
      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MOMENTRA',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR in App build: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return error screen
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MOMENTRA',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $e'),
                const SizedBox(height: 8),
                Text('Check console for details', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }
  }
}
