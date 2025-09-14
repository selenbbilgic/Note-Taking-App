import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/auth/cubit/auth_cubit.dart';
import 'package:notes_app/features/auth/cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final loading = state is AuthUnknown;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Current state: $state',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
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
                if (loading)
                  const CircularProgressIndicator()
                else
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed:
                            () => context.read<AuthCubit>().signIn(
                              emailCtl.text.trim(),
                              passCtl.text,
                            ),
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed:
                            () => context.read<AuthCubit>().signUp(
                              emailCtl.text.trim(),
                              passCtl.text,
                            ),
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
