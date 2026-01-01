import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Get Supabase credentials from environment variables
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 
      'https://uzlctsulpzlvwvlkekgj.supabase.co'; // Fallback for development
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
      'sb_publishable_TNo02OZJnNUGYI0KoG1Aaw_KxEkyoCU'; // Fallback for development

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing Supabase credentials. Please create a .env file with SUPABASE_URL and SUPABASE_ANON_KEY.\n'
      'See .env.example for template.'
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  }
}
