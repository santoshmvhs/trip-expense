import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/data_export_service.dart';
import '../../widgets/momentra_logo_appbar.dart';
import 'edit_profile_dialog.dart';
import 'currency_settings_dialog.dart';
import 'terms_page.dart';
import 'privacy_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _appVersion;
  String? _defaultCurrency;
  String? _userName;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadDefaultCurrency();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = currentUser();
    if (user != null) {
      try {
        final profile = await supabase()
            .from('profiles')
            .select('name, photo_url')
            .eq('id', user.id)
            .maybeSingle();
        
        if (profile != null) {
          setState(() {
            _userName = profile['name'] as String?;
            _userPhotoUrl = profile['photo_url'] as String?;
          });
        } else {
          // Profile doesn't exist, create it
          try {
            await supabase().from('profiles').insert({
              'id': user.id,
              'name': user.email?.split('@').first ?? '',
              'default_currency': 'INR',
            });
            // Reload after creating
            await _loadUserProfile();
          } catch (e) {
            debugPrint('Error creating profile: $e');
          }
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        // Set defaults if profile can't be loaded
        setState(() {
          _userName = user.email?.split('@').first;
          _userPhotoUrl = null;
        });
      }
    }
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadDefaultCurrency() async {
    final user = currentUser();
    if (user != null) {
      try {
        final profile = await supabase()
            .from('profiles')
            .select('default_currency')
            .eq('id', user.id)
            .maybeSingle();
        setState(() {
          _defaultCurrency = profile != null 
              ? (profile['default_currency'] as String? ?? 'INR')
              : 'INR';
        });
      } catch (e) {
        setState(() {
          _defaultCurrency = 'INR';
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase().auth.signOut();
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }

  Future<void> _showEditProfile() async {
    final user = currentUser();
    if (user == null) return;

    try {
      // Use current state values or fetch from database
      String currentName = _userName ?? user.email?.split('@').first ?? '';
      String? currentPhotoUrl = _userPhotoUrl;
      
      // Try to fetch from database if not already loaded
      final profile = await supabase()
          .from('profiles')
          .select('name, photo_url')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profile != null) {
        currentName = profile['name'] as String? ?? currentName;
        currentPhotoUrl = profile['photo_url'] as String? ?? currentPhotoUrl;
      }

      if (context.mounted) {
        final result = await showDialog<Map<String, String?>>(
          context: context,
          builder: (context) => EditProfileDialog(
            currentName: currentName,
            currentPhotoUrl: currentPhotoUrl,
            email: user.email ?? '',
          ),
        );

        if (result != null) {
          // Check if profile exists
          final profileExists = await supabase()
              .from('profiles')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();
          
          if (profileExists == null) {
            // Create profile if it doesn't exist
            await supabase().from('profiles').insert({
              'id': user.id,
              'name': result['name'] ?? '',
              'photo_url': result['photo_url'],
              'default_currency': _defaultCurrency ?? 'INR',
            });
          } else {
            // Update existing profile
            await supabase().from('profiles').update({
              'name': result['name'],
              if (result['photo_url'] != null) 'photo_url': result['photo_url'],
            }).eq('id', user.id);
          }

          // Refresh profile data
          await _loadUserProfile();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadDefaultCurrency(); // Refresh currency if changed
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCurrencySettings() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => CurrencySettingsDialog(
        currentCurrency: _defaultCurrency ?? 'INR',
      ),
    );

    if (result != null) {
      final user = currentUser();
      if (user != null) {
        try {
          await supabase().from('profiles').update({
            'default_currency': result,
          }).eq('id', user.id);

          setState(() {
            _defaultCurrency = result;
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Default currency set to $result')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating currency: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const MomentraLogoAppBar(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                        ? NetworkImage(_userPhotoUrl!)
                        : null,
                    child: _userPhotoUrl == null || _userPhotoUrl!.isEmpty
                        ? (user?.email != null
                            ? Text(
                                user!.email!.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : const Icon(Icons.person))
                        : null,
                  ),
                  title: Text(
                    _userName?.isNotEmpty == true
                        ? _userName!
                        : (user?.email?.split('@').first ?? 'User'),
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(user?.email ?? 'Not signed in'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showEditProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader('Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Default Currency'),
                  subtitle: Text(_defaultCurrency ?? 'INR'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showCurrencySettings,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(isDark ? 'Dark theme enabled' : 'Light theme enabled'),
                  value: isDark,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data & Privacy Section
          _buildSectionHeader('Data & Privacy'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download your data as JSON'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportData(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete Account'),
                  subtitle: const Text('Permanently delete your account and all data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: Text(_appVersion ?? 'Loading...'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out
          Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.onErrorContainer,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _handleSignOut,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This will export all your data (groups, expenses, budgets) as a JSON file. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exporting data...'),
          duration: Duration(seconds: 2),
        ),
      );

      await DataExportService.exportAllData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Second confirmation
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your last chance. Your account and all data will be permanently deleted. Type "DELETE" to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    // Show text input for "DELETE"
    final deleteTextController = TextEditingController();
    final deleteConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type DELETE to confirm'),
        content: TextField(
          controller: deleteTextController,
          decoration: const InputDecoration(
            hintText: 'Type DELETE',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (deleteTextController.text.trim() == 'DELETE') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please type DELETE exactly')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    deleteTextController.dispose();

    if (deleteConfirmed != true) return;

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting account...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final userId = currentUser()?.id;
      if (userId == null) {
        throw Exception('User not found');
      }

      // Delete user profile (this will cascade delete all related data due to foreign keys)
      await supabase().from('profiles').delete().eq('id', userId);

      // Sign out
      await supabase().auth.signOut();

      if (context.mounted) {
        context.go('/auth');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
