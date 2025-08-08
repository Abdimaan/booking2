import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'user_home.dart';
import 'provider_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tqprwfogyjpnhzpqslug.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxcHJ3Zm9neWpwbmh6cHFzbHVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjY2ODYsImV4cCI6MjA2OTM0MjY4Nn0.jPmmFn5MJghEv_VCxwDOw-VnRqsQoRXrIQ2JKykI66U',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check current session first
        final currentSession = Supabase.instance.client.auth.currentSession;

        if (currentSession != null) {
          // print('User is logged in with ID: ${currentSession.user.id}');
          // User is logged in, check their role and navigate accordingly
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserRole(currentSession.user.id),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data != null) {
                final role = roleSnapshot.data!['role'] as String;
                // print('User role: $role');
                if (role == 'provider') {
                  return const ProviderHome();
                } else {
                  return const UserHome();
                }
              } else {
                // print('No role found for user, showing login page');
                // User exists but no role found, show registration
                return const LoginPage();
              }
            },
          );
        }

        // Also check if snapshot has data and session
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            // print('User is logged in via stream with ID: ${session.user.id}');
            // User is logged in, check their role and navigate accordingly
            return FutureBuilder<Map<String, dynamic>?>(
              future: _getUserRole(session.user.id),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (roleSnapshot.hasData && roleSnapshot.data != null) {
                  final role = roleSnapshot.data!['role'] as String;
                  // print('User role: $role');
                  if (role == 'provider') {
                    return const ProviderHome();
                  } else {
                    return const UserHome();
                  }
                } else {
                  // print('No role found for user, showing login page');
                  // User exists but no role found, show registration
                  return const LoginPage();
                }
              },
            );
          }
        }

        print('User is not logged in, showing login page');
        // User is not logged in
        return const LoginPage();
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserRole(String userId) async {
    try {
      // print('Fetching role for user: $userId');
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      // print('Role response: $response');
      return response;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
}
