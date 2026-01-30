import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client.auth);
});

class AuthRepository {
  final GoTrueClient _authClient;

  AuthRepository(this._authClient);

  Future<void> signInWithEmail(String email, String password) async {
    await _authClient.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _authClient.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authClient.signOut();
  }
  
  Stream<AuthState> get authStateChanges => _authClient.onAuthStateChange;
}
