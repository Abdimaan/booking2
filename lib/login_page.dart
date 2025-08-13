import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_home.dart';
import 'provider_home.dart';
import 'location_service.dart';
import 'ragis.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // String role = 'user';
  bool _isLoading = false;

  Future<void> _requestLocationAndSave(String userId) async {
    try {
      // Request location permission and get current location
      Position? position = await LocationService.getCurrentLocation(context);

      if (position != null) {
        // Save location to database
        bool saved = await LocationService.saveUserLocation(
          userId,
          position.latitude,
          position.longitude,
        );

        if (saved) {
          print('Location saved successfully for user: $userId');
        } else {
          print('Failed to save location for user: $userId');
        }
      } else {
        print('Could not get location for user: $userId');
      }
    } catch (e) {
      print('Error handling location for user $userId: $e');
    }
  }

  // Future<void> signUp() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     final auth = Supabase.instance.client.auth;
  //     final res = await auth.signUp(
  //       email: emailController.text,
  //       password: passwordController.text,
  //     );
  //     final uid = res.user!.id;

  //     await Supabase.instance.client.from('users').insert({
  //       'id': uid,
  //       'role': role,
  //       'name': emailController.text
  //     });

  //     // Request location permission and save location
  //     await _requestLocationAndSave(uid);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Account created successfully! Please check your email to verify.')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error creating account: $e')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<bool?> _showLocationPermissionDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
            'We need your location to match you with nearby jobs. Do you allow the app to access and save your location?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Deny'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Allow'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> login() async {
    setState(() => _isLoading = true);

    try {
      final auth = Supabase.instance.client.auth;
      final res = await auth.signInWithPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      final uid = res.user!.id;

      final profile = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', uid)
          .single();

      // Show custom dialog for location permission
      final allowLocation = await _showLocationPermissionDialog(context);
      if (allowLocation == true) {
        await _requestLocationAndSave(uid);
      }

      if (profile['role'] == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProviderHome()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: !_isLoading,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            // DropdownButton<String>(
            //   value: role,
            //   onChanged: _isLoading
            //       ? null
            //       : (val) => setState(() => role = val!),
            //   items: const [
            //     DropdownMenuItem(value: 'user', child: Text('User')),
            //     DropdownMenuItem(value: 'provider', child: Text('Provider')),
            //   ],
            // ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            // ElevatedButton(
            //   onPressed: _isLoading ? null : signUp,
            //   child: const Text('Sign Up'),
            // ),
            ElevatedButton(onPressed: login, child: const Text('Login')),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ragistarion()),
                );
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
