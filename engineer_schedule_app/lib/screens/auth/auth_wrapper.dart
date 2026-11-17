import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:engineer_schedule_app/providers/auth_provider.dart';
import 'package:engineer_schedule_app/screens/auth/login_screen.dart';
import 'package:engineer_schedule_app/screens/dashboard/dashboard_screen.dart';
import 'package:engineer_schedule_app/utils/constants.dart';

/// Listens to Supabase auth state changes and routes the user to the
/// appropriate screen:
///   • Active session → load profile → [DashboardScreen]
///   • No session → [LoginScreen]
///
/// Shows a loading spinner while the initial auth check is in progress.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
    _listenToAuthChanges();
  }

  /// Checks whether there is already a valid Supabase session when the
  /// widget first mounts. If so, loads the user profile via [AuthProvider].
  Future<void> _checkInitialSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // A session exists – try to hydrate the profile.
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadProfile();

      if (!mounted) return;
      setState(() {
        _isAuthenticated = authProvider.isAuthenticated;
        _isCheckingAuth = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _isCheckingAuth = false;
      });
    }
  }

  /// Subscribes to Supabase auth state stream so sign-in / sign-out events
  /// happening elsewhere (e.g. deep link, token refresh) are reflected here.
  void _listenToAuthChanges() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((authState) async {
      final event = authState.event;
      final session = authState.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadProfile();

        if (!mounted) return;
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
      } else if (event == AuthChangeEvent.signedOut) {
        if (!mounted) return;
        setState(() {
          _isAuthenticated = false;
          _isCheckingAuth = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.engineering_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: AppSpacing.lg),
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Loading…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
