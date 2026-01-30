import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('user_type')
        .eq('id', user.id)
        .maybeSingle();

    return response?['user_type'] as String?;
  } catch (e) {
    return null;
  }
});
