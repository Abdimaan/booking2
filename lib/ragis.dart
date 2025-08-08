import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ragistarion extends StatefulWidget {
  const ragistarion({super.key});

  @override
  State<ragistarion> createState() => _ragistarionState();
}

class _ragistarionState extends State<ragistarion> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'user';
  bool _isLoading = false;

  Future<void> signUp() async {
    setState(() => _isLoading = true);

    try {
      final auth = Supabase.instance.client.auth;
      final res = await auth.signUp(
        email: emailController.text,
        password: passwordController.text,
      );
      final uid = res.user!.id;

      await Supabase.instance.client.from('users').insert({
        'id': uid,
        'role': role,
        'name': emailController.text,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully! Please check your email to verify.',
          ),
        ),
      );

      // Navigate to login page after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      
      emailController.clear();
      passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating account: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            DropdownButton<String>(
              value: role,
              onChanged: _isLoading
                  ? null
                  : (val) => setState(() => role = val!),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'provider', child: Text('Provider')),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            SizedBox(height: 30),

            ElevatedButton(onPressed: signUp, child: const Text('sign up')),
          ],
        ),
      ),
    );
  }
}
