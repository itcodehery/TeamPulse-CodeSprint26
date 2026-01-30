import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  Session? get currentSession => Supabase.instance.client.auth.currentSession;
  bool get isAuthenticated => currentSession != null;
}
