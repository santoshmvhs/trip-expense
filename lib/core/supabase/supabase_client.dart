import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient supabase() => Supabase.instance.client;

User? currentUser() => Supabase.instance.client.auth.currentUser;

