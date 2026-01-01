import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/momentra_logo_appbar.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        // Sign up
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: _nameController.text.trim().isNotEmpty
              ? {'full_name': _nameController.text.trim()}
              : null,
        );
        
        // If user was created, try to create profile manually if trigger failed
        if (response.user != null) {
          try {
            // Wait a bit for trigger to run
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Check if profile exists
            final profileCheck = await Supabase.instance.client
                .from('profiles')
                .select('id')
                .eq('id', response.user!.id)
                .maybeSingle();
            
            // If profile doesn't exist, create it manually
            if (profileCheck == null) {
              try {
                await Supabase.instance.client.from('profiles').insert({
                  'id': response.user!.id,
                  'email': response.user!.email ?? _emailController.text.trim(),
                  'full_name': _nameController.text.trim(),
                });
                debugPrint('Profile created successfully via client fallback');
              } catch (e) {
                debugPrint('Profile insert failed: $e');
                // Check if it's a PostgrestException (RLS or other DB error)
                final errorString = e.toString();
                final isRlsError = errorString.contains('row-level security') || 
                                   errorString.contains('RLS') || 
                                   errorString.contains('42501') ||
                                   errorString.contains('permission denied');
                
                if (isRlsError) {
                  // Don't try alternative schema if RLS is blocking
                  throw Exception('Permission denied. Please run FIX_SIGNUP_COMPLETE.sql in Supabase SQL Editor.');
                }
                
                // Try with 'name' column if 'full_name' doesn't exist
                try {
                  await Supabase.instance.client.from('profiles').insert({
                    'id': response.user!.id,
                    'name': _nameController.text.trim(),
                    'default_currency': 'INR',
                  });
                  debugPrint('Profile created with alternative schema');
                } catch (e2) {
                  debugPrint('Alternative profile insert failed: $e2');
                  final errorString2 = e2.toString();
                  if (errorString2.contains('row-level security') || 
                      errorString2.contains('RLS') || 
                      errorString2.contains('42501')) {
                    throw Exception('RLS policy blocking profile creation. Please run FIX_SIGNUP_COMPLETE.sql in Supabase SQL Editor.');
                  }
                  // Continue anyway - user can update profile later
                }
              }
            } else {
              debugPrint('Profile already exists (created by trigger)');
            }
          } catch (e) {
            debugPrint('Profile creation check failed: $e');
            // Continue anyway - user is created
          }
        }
        
        if (mounted) {
          _snack('Account created! Please check your email to verify your account.');
        }
      } else {
        // Sign in
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        debugPrint('AuthException: ${e.message}');
        final errorMessage = e.message.toLowerCase();
        // Handle specific error codes
        if (errorMessage.contains('unexpected_failure') || 
            errorMessage.contains('database error') ||
            errorMessage.contains('database error saving new user')) {
          _errorMessage = 'Signup failed due to database error. Please run FIX_SIGNUP_NEVER_FAILS.sql in Supabase SQL Editor to fix the trigger.';
        } else if (errorMessage.contains('email_not_confirmed')) {
          _errorMessage = 'Please check your email to verify your account.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        // Show more detailed error message
        final errorString = e.toString();
        debugPrint('Signup error: $e');
        if (errorString.contains('Database error') || errorString.contains('unexpected_failure')) {
          _errorMessage = 'Database error: Please run FIX_SIGNUP_NEVER_FAILS.sql in Supabase SQL Editor to fix the trigger.';
        } else if (errorString.contains('row-level security') || errorString.contains('RLS')) {
          _errorMessage = 'Permission denied. Please run FIX_SIGNUP_NEVER_FAILS.sql in Supabase SQL Editor.';
        } else {
          _errorMessage = 'Error: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MomentraLogoAppBar(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Momentra Logo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Image.asset(
                    'assets/images/momentra.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Sign up to start splitting expenses'
                      : 'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_isSignUp && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                            _passwordController.clear();
                            _nameController.clear();
                          });
                        },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : "Don't have an account? Sign Up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

