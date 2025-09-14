import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _sub;

  AuthCubit(this._auth) : super(const AuthUnknown()) {
    _sub = _auth.authStateChanges().listen((user) {
      if (user == null)
        emit(const Unauthenticated());
      else
        emit(Authenticated(user));
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign in failed. Please try again.';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage =
              'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'Sign in failed. Please try again.';
      }

      emit(AuthError(errorMessage));
      emit(const Unauthenticated()); // keep state usable
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign up failed. Please try again.';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          errorMessage =
              'Password is too weak. Please choose a stronger password.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Account creation is not allowed. Please contact support.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'Sign up failed. Please try again.';
      }

      emit(AuthError(errorMessage));
      emit(const Unauthenticated());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
