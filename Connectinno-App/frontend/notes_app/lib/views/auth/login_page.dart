import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _signIn(bool create) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (create) {
        await auth.createUserWithEmailAndPassword(
          email: emailCtl.text.trim(),
          password: passCtl.text,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: emailCtl.text.trim(),
          password: passCtl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message;
      });
    } finally {
      if (mounted)
        setState(() {
          loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            if (loading)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _signIn(false),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _signIn(true),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
